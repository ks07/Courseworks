#include "modmul.h"

#define MAX(A, B) ((A) > (B) ? (A) : (B))

#ifdef DEBUG

// Use time.h for a simple seed for unit tests
#include "time.h"

// Convenience function for GDB use
void zp(mpz_t x) {
  gmp_printf("%Zd\n", x);
}

// Enable fixed Y to compare against test vectors
#define FIXEDY

#endif

// Finds the rho_sq value corresponding to N
void findRhoSq(mpz_t rho_sq, mpz_t N) {
  mpz_set_ui(rho_sq, 1);

  const size_t lim = 2 * mpz_size(N) * GMP_LIMB_BITS;

  for (size_t i = 1; i <= lim; i++) {
    mpz_add(rho_sq, rho_sq, rho_sq);
    if (mpz_cmp(rho_sq, N) >= 0) {
      mpz_sub(rho_sq, rho_sq, N); // mod N as we go
    }
  }
}

// Finds the omega value corresponding to N
void findOmega(mpz_t omega, mpz_t N) {
  const size_t w = GMP_LIMB_BITS; // b = 2^w
  mpz_t b;
  mpz_init_set_ui(b, GMP_NUMB_MAX);
  mpz_add_ui(b, b, 1);

  // Slightly dodgy check to make sure that NUMB_MAX actually does
  // match our expectation of LIMB_BITS
  assert(GMP_NUMB_MAX == ((mp_limb_t) 0) - 1); // We would shift here, if we could be sure of

  mpz_set_ui(omega, 1);
  for (size_t i = 1; i < w; i++) {
    mpz_mul(omega, omega, omega);
    mpz_mul(omega, omega, N);
    mpz_mod(omega, omega, b);
  }
  mpz_neg(omega, omega);
  mpz_mod(omega, omega, b);

  mpz_clear(b);
}

// Initialises the tMontParams from an N.
void tMontParams_init(tMontParams *mp, mpz_t N) {
  mpz_inits(mp->rho_sq, mp->omega, NULL);
  mpz_init_set(mp->N, N);
  findRhoSq(mp->rho_sq, mp->N);
  findOmega(mp->omega, mp->N);
}

// Initialises the tMontParams with a preset N.
void tMontParams_init2(tMontParams *mp) {
  mpz_inits(mp->rho_sq, mp->omega, NULL);
  findRhoSq(mp->rho_sq, mp->N);
  findOmega(mp->omega, mp->N);
}

// Clears all initialised values in the tMontParams
void tMontParams_clear(tMontParams *mp) {
  mpz_clears(mp->N, mp->rho_sq, mp->omega, NULL);
}

// Calculates x * y mod N. x and y must be in montgomery representation.
void MontMul(mpz_t r, mpz_t x, mpz_t y, tMontParams *mp) {
  mp_limb_t u; // We can just use a limb type instead of another mpz var... (unless Nails are enabled!)

  // lN = limb count
  const size_t lN = mpz_size(mp->N);

  // Ensure r doesn't alias x or y!
  assert(r->_mp_d != x->_mp_d && r->_mp_d != y->_mp_d);

  // From the definition of omega it should only be a single lim... Ensure this is the case, else u is wrong.
  assert(mpz_size(mp->omega) == 1);

  mpz_set_ui(r, 0);

  for (size_t i = 0; i < lN; i++) {
    // u = (r0 + yi * x0) * omega (mod b)
    u = mpz_getlimbn(x, 0) * mpz_getlimbn(y, i); // u = x0 * yi
    u += mpz_getlimbn(r, 0); // u = r0 + yi * x0
    u *= mpz_getlimbn(mp->omega, 0); // u = (r0 + yi * x0) * omega

    // r = (r + x * yi + u * N) / b
    mpz_addmul_ui(r, x, mpz_getlimbn(y, i)); // r = r_ + (x * yi)
    mpz_addmul_ui(r, mp->N, u); // r = (r_ + (x * yi)) + (N * u)
    mpz_tdiv_q_2exp(r, r, GMP_LIMB_BITS); // r = (r + x * yi + u * N) / b
  }

  if (mpz_cmp(r, mp->N) >= 0) {
    mpz_sub(r, r, mp->N);
  }
}

// TODO: make me externally available
static inline void GetMontRep(mpz_t x_m, mpz_t x, tMontParams *mp) {
  MontMul(x_m, x, mp->rho_sq, mp);
}

static inline void UndoMontRep(mpz_t r, mpz_t r_m, tMontParams *mp) {
  mpz_t one;
  mpz_init_set_ui(one, 1);
  MontMul(r, r_m, one, mp);
  mpz_clear(one);
}

// x in G of order n, y less than n, window size k, t=x^y mod n
void SlidingMontExp(mpz_t t_, mpz_t x_, mpz_t y, tMontParams *mp, const unsigned char k) { //TODO: Rename _
  const size_t len = 1 << (k - 1);
  mpz_t T_m[len], tmp, x_m, x_m_sq, t_m; // TODO: Nice init
  long long i, l;
  mp_bitcnt_t lowest_hot = 0; // We don't really need to init this, but we want to lose compiler warnings.
  unsigned int u;

  // Ensure u is wide enough for k bits
  assert( 8 * sizeof(u) >= k );

  // Ensure our input x is < N
  assert(mpz_cmp(x_, mp->N) < 0);

  // Init mpz_t vars, except for T_m
  mpz_inits(tmp, x_m, x_m_sq, t_m, NULL);

  // Convert relevant values to Montgomery representation
  GetMontRep(x_m, x_, mp);

  // Use montgomery rep to seed T_m
  mpz_init_set(T_m[0], x_m);

  // Make sure the square is also in Mont rep
  MontMul(x_m_sq, x_m, x_m, mp);

  // Fill T using Mont rep values
  for (unsigned int ii = 1; ii < len; ii++) {
    mpz_init(T_m[ii]);
    MontMul(T_m[ii], T_m[ii-1], x_m_sq, mp);
  }

  // Free x_m_sq
  mpz_clear(x_m_sq);

  // t = 0G
  mpz_set_ui(t_, 1); // TODO: We should (ab)use one here?

  // Convert t to Mont rep
  GetMontRep(t_m, t_, mp);

  i = mpz_sizeinbase(y, 2) - 1; // i = |y| - 1

  while (i >= 0) {
    // if y[i] == 0; l = i, u = 0
    if (mpz_tstbit(y, i) == 0) {
      l = i;
      u = 0;
    } else {
      l = MAX(i - k + 1, 0);
      u = 0;
      // TODO: mpz_scan1
      for (long ii = i; ii >= (long)l; ii--) {
	// Build u and check l;
	u = u << 1;
	if (mpz_tstbit(y, ii)) {
	  lowest_hot = ii;
	  u = u | 1;
	}
      }

      // Need to unshift to work with the lowest hot... better if reversed?
      // shift right so we get u = y[i..l]
      // we have shifted left (i - l + 1) times, shift right (sl - i + lh - 1)
      const unsigned int to_shift = (i - l + 1) - i + lowest_hot - 1;
      u = u >> to_shift;
      l = lowest_hot;

      assert(l <= i && mpz_tstbit(y,l) == 1);
    }

    // Calculate t ^ 2 ^ (i-l+1)
    for (unsigned int ii = 0; ii < i-l+1; ii++) {
      MontMul(tmp, t_m, t_m, mp);
      mpz_swap(t_m, tmp); // Cannot alias tmp and t for MontMul, so swap after.
    }

    if (u != 0) {
      // Only bad people write multiplication with a +
      MontMul(tmp, t_m, T_m[(u-1) >> 1], mp);
      mpz_swap(t_m, tmp); // Shove result back in t_m
    }

    i = l - 1;
  }

  UndoMontRep(t_, t_m, mp);

#ifdef DEBUG
  mpz_powm(tmp, x_, y, mp->N);
  assert(mpz_cmp(t_, tmp) == 0);
#endif

  // Free temporary GMP vars
  for (size_t ii = 0; ii < len; ii++) {
    mpz_clear(T_m[ii]);
  }
  mpz_clears(tmp, x_m, t_m, NULL);
}

/*
Perform stage 1:

- read each 3-tuple of N, e and m from stdin,
- compute the RSA encryption c,
- then write the ciphertext c to stdout.
*/

void stage1() {
  tMontParams mp;
  mpz_t     e, m, c;
  mpz_inits(e, m, c, mp.N, NULL);

  while (gmp_scanf("%ZX %ZX %ZX ",mp.N,e,m) != EOF) {
    tMontParams_init2(&mp);
    // Encrypt: y = m ^ e mod N
    SlidingMontExp(c, m, e, &mp, 4);

    gmp_printf("%ZX\n",c);
  }

  mpz_clears(e, m, c, NULL);
  tMontParams_clear(&mp);
}

/*
Perform stage 2:

- read each 9-tuple of N, d, p, q, d_p, d_q, i_p, i_q and c from stdin,
- compute the RSA decryption m,
- then write the plaintext m to stdout.
*/

void stage2() {
  tMontParams mp_p, mp_q;
  mpz_t     d_p, d_q, i_p, i_q, c, m, m_1, m_2, h, msub, tmp, c_mp, c_mq;
  mpz_inits(d_p, d_q, i_p, i_q, c, m, m_1, m_2, h, msub, tmp, c_mp, c_mq, mp_p.N, mp_q.N, NULL);

  while (gmp_scanf("%*ZX %*ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX ",mp_p.N,mp_q.N,d_p,d_q,i_p,i_q,c) != EOF) {
    tMontParams_init2(&mp_p);
    tMontParams_init2(&mp_q);

    // CRT decryption:
    mpz_mod(c_mp, c, mp_q.N);
    mpz_mod(c_mp, c, mp_p.N);
    mpz_mod(c_mq, c, mp_p.N);
    mpz_mod(c_mq, c, mp_q.N);
    SlidingMontExp(m_1, c_mp, d_p, &mp_p, 4); // m1 = c ^ d_p mod p
    SlidingMontExp(m_2, c_mq, d_q, &mp_q, 4); // m2 = c ^ d_q mod q

    // TODO: Do we need to undo here? And can we use MontMul?
    mpz_sub(msub, m_1, m_2); // msub = (m1 - m2)
    mpz_mul(tmp, i_q, msub); // tmp = i_q * (m1 - m2)
    mpz_mod(h, tmp, mp_p.N); // h = i_q * (m1 - m2) mod p
    mpz_mul(tmp, h, mp_q.N); // tmp = h * q
    mpz_add(m, m_2, tmp); // m = m2 + h * q

    gmp_printf("%ZX\n",m);
  }

  mpz_clears(d_p, d_q, i_p, i_q, c, m, m_1, m_2, h, msub, tmp, c_mp, c_mq, NULL);
  tMontParams_clear(&mp_p);
  tMontParams_clear(&mp_q);
}

/*
Perform stage 3:

- read each 5-tuple of p, q, g, h and m from stdin,
- compute the ElGamal encryption c = (c_1,c_2),
- then write the ciphertext c to stdout.
*/

void stage3() {
  tMontParams mp;
  mpz_t     q, g, h, m, y, c_1, c_2, tmp;
  mpz_inits(q, g, h, m, y, c_1, c_2, tmp, mp.N, NULL);

#ifndef FIXEDY
  FILE *dev_random;
  unsigned char in_char;
  unsigned long int seed = 0;

  gmp_randstate_t randstate;
  gmp_randinit_mt(randstate); // Use the Mersenne Twister for random number generation.

  dev_random = fopen("/dev/random", "r");

  if (dev_random == NULL) {
    fprintf(stderr, "ERROR: Failed to open random source /dev/random\n");
  } else {
    const size_t char_count = ((sizeof seed) / (sizeof in_char));
    for (size_t i = 0; i < char_count; i++) {
      in_char = fgetc(dev_random);
      if (feof(dev_random)) {
	fprintf(stderr, "Error: Out of random bits! (read: %zu)\n", i);
	break;
      }

      seed = seed << (8 * sizeof in_char);
      seed = seed | in_char;
    }

    fclose(dev_random);
  }

  gmp_randseed_ui(randstate, seed);
#endif

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX ",mp.N,q,g,h,m) != EOF) {
    tMontParams_init2(&mp);

    // Encrypt: c_1 = g^(y mod q) mod p, random 0<y<q
    // c_2 = m * h^(y mod q) mod p

    // Set a random y for real implementation.
#ifdef FIXEDY
    mpz_set_ui(y, 1);
#else
    mpz_urandomm(y, randstate, q);
#endif

    // TODO: Pass mont rep vals into Slide
    mpz_t omega, rho_sq, m_m, tmp_m;
    mpz_inits(omega, rho_sq, m_m, tmp_m, NULL);
    findOmega(omega, mp.N);
    findRhoSq(rho_sq, mp.N);
    SlidingMontExp(c_1, g, y, &mp, 4); // c_1 = g ^ y mod p
    SlidingMontExp(tmp, h, y, &mp, 4); // tmp = h ^ y mod p
    GetMontRep(m_m, m, &mp);
    GetMontRep(tmp_m, tmp, &mp);
    MontMul(c_2, m_m, tmp_m, &mp); // c_2 = m * (h ^ y) mod p;
    UndoMontRep(tmp, c_2, &mp);
    mpz_swap(tmp, c_2);
    gmp_printf("%ZX\n%ZX\n",c_1,c_2);
  }

#ifndef FIXEDY
  gmp_randclear(randstate);
#endif

  mpz_clears(q, g, h, m, y, c_1, c_2, tmp, NULL);
}

/*
Perform stage 4:

- read each 5-tuple of p, q, g, x and c = (c_1,c_2) from stdin,
- compute the ElGamal decryption m,
- then write the plaintext m to stdout.
*/

void stage4() {
  tMontParams mp;
  mpz_t     q, g, x, c_1, c_2, i_c_1, tmp, m;
  mpz_inits(q, g, x, c_1, c_2, i_c_1, tmp, m, mp.N, NULL);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX %ZX ",mp.N,q,g,x,c_1,c_2) != EOF) {
    tMontParams_init2(&mp);
    // Decrypt: m = c_2 * c_1^(-x mod q) mod p
    // ==> c_2 * c_1^(-1)^(x mod q) mod p

    // TODO: Should we mod x?
    mpz_invert(tmp, c_1, mp.N);
    SlidingMontExp(i_c_1, tmp, x, &mp, 4);

    // TODO: MontMul and Slide change and no tmp
    mpz_mul(tmp, i_c_1, c_2);
    mpz_mod(m, tmp, mp.N);

    gmp_printf("%ZX\n",m);
  }

  mpz_clears(q, g, x, c_1, c_2, i_c_1, tmp, m, NULL);
}

////////////////////////////////////////////////////////////
//////////////////////// UNIT TESTS ////////////////////////
////////////////////////////////////////////////////////////

#ifdef DEBUG
void MontRep_test(gmp_randstate_t randstate) {
  tMontParams mp;
  mpz_t     r, r_m, r_;
  mpz_inits(r, r_m, r_, NULL);

  for (int i = 0; i < 10; i++) {
    mpz_init(mp.N);
    // Pick a modulus N of up to 1024 bits
    mpz_urandomb(mp.N, randstate, 1024); // 1024 bit
    // Ensure N is at least 5
    mpz_add_ui(mp.N, mp.N, 5);
    // Find a prime larger than this number.
    mpz_nextprime(mp.N, mp.N);

    tMontParams_init2(&mp);

    for (int j = 0; j < 10; j++) {
      // Select some random r
      mpz_urandomm(r, randstate, mp.N);

      // Calculate the Montgomery representation.
      GetMontRep(r_m, r, &mp);

      // Return r_m back to normal representation.
      UndoMontRep(r_, r_m, &mp);

      // Check results
      if (mpz_cmp(r, r_) != 0) {
	gmp_printf("[ERROR] Failed MontRep test on\n%Zx\n\t=>\n%Zx\n\t=>\n%Zx\n", r, r_m, r_);
	abort();
      }
    }

    tMontParams_clear(&mp);
  }

  mpz_clears(r, r_m, r_, NULL);

  gmp_printf("[OK] Passed MontRep tests.\n");
}

void MontMul_test(gmp_randstate_t randstate) {
  tMontParams mp;
  mpz_t     x, y, r, x_m, y_m, r_m, r2;
  mpz_inits(x, y, r, x_m, y_m, r_m, r2, NULL);

  for (int i = 0; i < 10; i++) {
    mpz_init(mp.N);
    // Pick a modulus N of up to 1024 bits
    mpz_urandomb(mp.N, randstate, 1024); // 1024 bit
    // Ensure N is at least 5
    mpz_add_ui(mp.N, mp.N, 5);
    // Find a prime larger than this number.
    mpz_nextprime(mp.N, mp.N);

    tMontParams_init2(&mp);

    for (int j = 0; j < 10; j++) {
      // Select some random x and y
      mpz_urandomm(x, randstate, mp.N);
      mpz_urandomm(y, randstate, mp.N);

      // Calculate the Montgomery representation.
      GetMontRep(x_m, x, &mp);
      GetMontRep(y_m, y, &mp);

      // Do the multiplication x * y mod N
      mpz_mul(r, x, y);
      mpz_mod(r, r, mp.N);
      MontMul(r_m, x_m, y_m, &mp);

      // Return r_m back to normal representation.
      UndoMontRep(r2, r_m, &mp);

      // Check results
      if (mpz_cmp(r, r2) != 0) {
	gmp_printf("[ERROR] Failed MontMul test on\n%Zx\n\t*\n%Zx\n\tmod\n%Zx\n\tGot\n%Zx\n", x, y, mp.N, r2);
	abort();
      }
    }

    tMontParams_clear(&mp);
  }

  mpz_clears(x, y, r, x_m, y_m, r_m, r2, NULL);

  gmp_printf("[OK] Passed MontMul tests.\n");
}

void SlidingMontExp_test(gmp_randstate_t randstate) {
  const unsigned int win_size = 4;
  tMontParams mp;
  mpz_t     x, y, r, r2;
  mpz_inits(x, y, r, r2, NULL);

  for (int i = 0; i < 10; i++) {
    mpz_init(mp.N);
    // Pick a modulus N of up to 1024 bits
    mpz_urandomb(mp.N, randstate, 1024); // 1024 bit
    // Ensure N is at least 5
    mpz_add_ui(mp.N, mp.N, 5);
    // Find a prime larger than this number.
    mpz_nextprime(mp.N, mp.N);

    tMontParams_init2(&mp);

    for (int j = 0; j < 10; j++) {
      // Select some random x and y
      mpz_urandomm(x, randstate, mp.N);
      mpz_urandomm(y, randstate, mp.N);

      // Do the exponentiation x ^ y mod N.
      SlidingMontExp(r, x, y, &mp, win_size);
      mpz_powm(r2, x, y, mp.N);

      // Check results
      if (mpz_cmp(r, r2) != 0) {
	gmp_printf("[ERROR] Failed SlidingMontExp test on\n%Zx\n\t^\n%Zx\n\tmod\n%Zx\n\tGot\n%Zx\n", x, y, mp.N, r);
	abort();
      }
    }

    tMontParams_clear(&mp);
  }

  mpz_clears(x, y, r, r2, NULL);

  gmp_printf("[OK] Passed SlidingMontExp tests.\n");
}

void runtests() {
  // Define and init random state
  gmp_randstate_t randstate;
  gmp_randinit_mt(randstate);
  gmp_randseed_ui(randstate, time(NULL));

  // In some kind of strange catch-22, MontRep and MontMul rely on each other...
  // ...so lets test them both!
  MontRep_test(randstate);
  MontMul_test(randstate);
  SlidingMontExp_test(randstate);

  gmp_randclear(randstate);
}
#endif

////////////////////////////////////////////////////////////
///////////////////// END OF UNIT TESTS ////////////////////
////////////////////////////////////////////////////////////

/*
The main function acts as a driver for the assignment by simply invoking
the correct function for the requested stage.
*/
int main( int argc, char* argv[] ) {
  if( argc != 2 ) {
#ifdef DEBUG
    runtests();
    return 0;
#else
    abort();
#endif
  }

  if     ( !strcmp( argv[ 1 ], "stage1" ) ) {
    stage1();
  }
  else if( !strcmp( argv[ 1 ], "stage2" ) ) {
    stage2();
  }
  else if( !strcmp( argv[ 1 ], "stage3" ) ) {
    stage3();
  }
  else if( !strcmp( argv[ 1 ], "stage4" ) ) {
    stage4();
  }
  else {
    abort();
  }

  return 0;
}
