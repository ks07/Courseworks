#include "modmul.h"

#include "time.h"

// Toggle between pseudorandom Y and fixed Y for example comparison.
#define FIXEDY

void zp(mpz_t x) {
  gmp_printf("%Zd\n", x);
}

void findRhoSq(mpz_t rho_sq, mpz_t N) {
  mpz_set_ui(rho_sq, 1);
  //  mpz_mod(rho_sq, rho_sq, N); // This is probably pointless... it's 1...

  const size_t lim = 2 * mpz_size(N) * GMP_LIMB_BITS; // GMP_NUMB_BITS == GMP_LIMB_BITS... or at least in our version of GMP

  for (size_t i = 1; i <= lim; i++) {
    mpz_add(rho_sq, rho_sq, rho_sq); // Hmm...
    if (mpz_cmp(rho_sq, N) >= 0) {
      mpz_sub(rho_sq, rho_sq, N);
    }
  }
}

void findOmega(mpz_t omega, mpz_t N) {
  const size_t w = GMP_LIMB_BITS; // b = 2^w
  mpz_t b;
  mpz_init_set_ui(b, GMP_NUMB_MAX);
  mpz_add_ui(b, b, 1);

  assert(GMP_NUMB_MAX == pow(2.0, GMP_LIMB_BITS) - 1);

  mpz_set_ui(omega, 1);
  for (size_t i = 1; i < w; i++) {
    mpz_mul(omega, omega, omega);
    mpz_mul(omega, omega, N);
    mpz_mod(omega, omega, b);
  }
  mpz_neg(omega, omega);
  mpz_mod(omega, omega, b);
}

// Calculates x * y mod N (?)
void MontMul(mpz_t r, mpz_t x, mpz_t y, mpz_t N, mpz_t omega, mpz_t rho_sq) {
  mpz_t u, b, tmp;
  mpz_inits(u, tmp, NULL);
  mpz_init_set_ui(b, GMP_NUMB_MAX);
  mpz_add_ui(b, b, 1);

  // lN = limb count?
  const size_t lN = mpz_size(N);

  mpz_set_ui(r, 0);

  for (size_t i = 0; i < lN; i++) {
    // TODO: Why is this in an mpz?
    // u = (r0 + yi * x0) * omega (mod b)
    mpz_set_ui(u, mpz_getlimbn(x, 0)); // u = x0
    mpz_mul_ui(u, u, mpz_getlimbn(y, i)); // u = x0 * yi
    mpz_add_ui(u, u, mpz_getlimbn(r, 0)); // u = r0 + yi * x0
    mpz_mul(u, u, omega); // u = (r0 + yi * x0) * omega
    mpz_mod(u, u, b); // mod b TODO: LOL

    // r = (r + yi * x + u * N) / b
    // r = (_r + (yi*x) + (u*N)) / b
    mpz_mul_ui(tmp, x, mpz_getlimbn(y, i)); // tmp = (yi*x);
    mpz_add(r, r, tmp); // r = _r + (yi*x)
    mpz_mul(tmp, u, N); // tmp = (u*N)
    mpz_add(r, r, tmp); // r = _r + (yi*x) + (u*N)
    mpz_tdiv_q_2exp(r, r, GMP_LIMB_BITS); // TODO: niceify?
  }

  if (mpz_cmp(r, N) >= 0) {
    mpz_sub(r, r, N);
  }
}

static inline void GetMontRep(mpz_t x_m, mpz_t x, mpz_t N, mpz_t omega, mpz_t rho_sq) {
  MontMul(x_m, x, rho_sq, N, omega, rho_sq);
}

static inline void UndoMontRep(mpz_t r, mpz_t r_m, mpz_t N, mpz_t omega, mpz_t rho_sq) {
  mpz_t one;
  mpz_init_set_ui(one, 1);
  MontMul(r, r_m, one, N, omega, rho_sq);
  mpz_clear(one);
}

void MontRep_test() {
  gmp_randstate_t randstate;
  mpz_t omega, rho_sq, N, r, r_m, r_;

  mpz_inits(omega, rho_sq, N, r, r_m, r_, NULL);

  gmp_randinit_mt(randstate);
  gmp_randseed_ui(randstate, time(NULL));

  for (int i = 0; i < 10; i++) {
    // Pick a modulus N of up to 1024 bits
    mpz_urandomb(N, randstate, 1024); // 1024 bit
    // Ensure N is at least 5
    mpz_add_ui(N, N, 5);
    // Find a prime larger than this number.
    mpz_nextprime(N, N);

    // Find the corresponding omega and rho_sq
    findOmega(omega, N);
    findRhoSq(rho_sq, N);

    for (int j = 0; j < 10; j++) {
      // Select some random r
      mpz_urandomm(r, randstate, N);

      // Calculate the Montgomery representation.
      GetMontRep(r_m, r, N, omega, rho_sq);

      // Return r_m back to normal representation.
      UndoMontRep(r_, r_m, N, omega, rho_sq);

      // Check results
      if (mpz_cmp(r, r_) != 0) {
	gmp_printf("[ERROR] Failed MontRep test on\n%Zx\n\t=>\n%Zx\n\t=>\n%Zx\n", r, r_m, r_);
	abort();
      }
    }
  }
  gmp_printf("[OK] Passed MontRep tests.\n");
}

// x in G of order n, y less than n, window size k, t=x^y mod n
void TWOk_ary_slide_ONEexp(mpz_t t, mpz_t x, mpz_t y, mpz_t n, unsigned char k) {
  size_t len = (size_t) pow(2.0, (double)(k - 1));
  mpz_t T[len], x_sq, tmp;
  long long i, l, y_size, lowest_hot;
  unsigned int u; // Must hold 2^k (width of >= k)

  // Ensure we've picked sensible types for k and u.
  assert(pow(2.0, 8.0*sizeof(k)) <= pow(2.0, 8.0*sizeof(u)));

  lowest_hot = 0 - 1;

  mpz_init_set(T[0], x);
  mpz_init(x_sq);
  mpz_init(tmp);
  mpz_mul(x_sq, x, x);
  for (unsigned int ii = 1; ii < len; ii++) {
    mpz_init(T[ii]);
    mpz_mul(T[ii], T[ii-1], x_sq);
  }

  mpz_set_ui(t, 1); // t = 0G ?
  y_size = mpz_sizeinbase(y, 2); // i = |y| - 1 
  i = y_size - 1;

  while (i >= 0) {
    // if y[i] == 0; l = i, u = 0
    if (mpz_tstbit(y, i) == 0) {
      l = i;
      u = 0;
    } else {
      l = fmax(i - k + 1, 0);
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

      l = lowest_hot;

      // Need to unshift to work with the lowest hot... better if reversed?
      // UNLESS... l == 0!
      const unsigned int to_shift = k - i + l - 1;
      if (l != 0) {
	u = u >> to_shift;
      }

      if ( l == 0 - 1 || mpz_tstbit(y,l) != 1) {
	abort();
      }
    }

    // replaceme
    double tp = pow(2.0, (double)i-l+1);
    mpz_powm_ui(tmp, t, tp, n);

    if (u != 0) {
      // Only bad people write multiplication with a +
      mpz_mul(t, tmp, T[(u-1) >> 1]);
    } else {
      // TODO: nooo
      mpz_swap(t, tmp);
    }

    i = l - 1;
  }

  mpz_mod(tmp, t, n);
  mpz_swap(t, tmp);

#ifndef NDEBUG
  mpz_powm(tmp, x, y, n);
  assert(mpz_cmp(t, tmp) == 0);
#endif
}

/*
Perform stage 1:

- read each 3-tuple of N, e and m from stdin,
- compute the RSA encryption c,
- then write the ciphertext c to stdout.
*/

void stage1() {

  mpz_t N, e, m, c;
  mpz_inits(N,e,m,c,NULL);

  while (gmp_scanf("%ZX %ZX %ZX ",N,e,m) != EOF) {
    //gmp_printf("%ZX\n%ZX\n%ZX\n",N,e,m);

    // Encrypt: y = m ^ e mod N
    //mpz_powm_sec(c, m, e, N);
    TWOk_ary_slide_ONEexp(c, m, e, N, 4);

    gmp_printf("%ZX\n",c);
  }
}

/*
Perform stage 2:

- read each 9-tuple of N, d, p, q, d_p, d_q, i_p, i_q and c from stdin,
- compute the RSA decryption m,
- then write the plaintext m to stdout.
*/

void stage2() {

  mpz_t N, d, p, q, d_p, d_q, i_p, i_q, c, m, m_1, m_2, h, msub, tmp;
  mpz_inits(N,d,p,q,d_p,d_q,i_p,i_q,c,m,m_1,m_2,h,msub,tmp,NULL);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX ",N,d,p,q,d_p,d_q,i_p,i_q,c) != EOF) {
    //gmp_printf("%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n",N,d,p,q,d_p,d_q,i_p,i_q,c);

    // Decrypt: m = c ^ d mod N
    // Using the CRT:
    // m1 = c ^ d_p mod p
    // m2 = c ^ d_q mod q
    // h = i_q * (m1 - m2) mod p
    // m = m2 + h * q
    TWOk_ary_slide_ONEexp(m_1, c, d_p, p, 4);
    //mpz_powm_sec(m_1, c, d_p, p);
    mpz_powm_sec(m_2, c, d_q, q);
    mpz_sub(msub, m_1, m_2);
    mpz_mul(tmp, i_q, msub);
    mpz_powm_ui(h, tmp, 1, p);
    mpz_mul(tmp, h, q);
    mpz_add(m, m_2, tmp);

    gmp_printf("%ZX\n",m);
  }
}

/*
Perform stage 3:

- read each 5-tuple of p, q, g, h and m from stdin,
- compute the ElGamal encryption c = (c_1,c_2),
- then write the ciphertext c to stdout.
*/

void stage3() {

  FILE *dev_random;
  unsigned char in_char;
  unsigned long int seed = 0;

  gmp_randstate_t randstate;
  mpz_t p, q, g, h, m, y, c_1, c_2, tmp, tmp2;
  mpz_inits(p,q,g,h,m,y,c_1,c_2,tmp,tmp2,NULL);
  gmp_randinit_mt(randstate); // Use the Mersenne Twister for random number generation.

  dev_random = fopen("/dev/random", "r");

  if (dev_random == NULL) {
    fprintf(stderr, "ERROR: Failed to open random source /dev/random\n");
  } else {
    const size_t char_count = ((sizeof seed) / (sizeof in_char));
    for (size_t i = 0; i < char_count; i++) {
      in_char = fgetc(dev_random);
      //printf("Read char: %X\n", in_char);
      if (feof(dev_random)) {
	printf("Error: Out of random bits! (read: %zu)\n", i);
	break;
      }

      seed = seed << (8 * sizeof in_char);
      //printf("Shifted Seed: %lX\n", seed);
      seed = seed | in_char;
      //printf("And Seed: %lX\n", seed);
    }

    fclose(dev_random);
  }

  //printf("RNG Seed: %lX\n", seed);

  gmp_randseed_ui(randstate, seed);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX ",p,q,g,h,m) != EOF) {
    //    gmp_printf("%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n",p,q,g,h,m);

    // Encrypt: c_1 = g^(y mod q) mod p, random 0<y<q
    // c_2 = m * h^(y mod q) mod p
    
    // Set a fixed y = 1 for testing.
    //    mpz_set_ui(y, 1);

    // Set a random y for real implementation.
#ifdef FIXEDY
    mpz_set_ui(y, 1);
#else
    mpz_urandomm(y, randstate, q);
#endif

    mpz_powm_sec(c_1, g, y, p);
    mpz_powm_sec(tmp, h, y, p);
    mpz_mul(tmp2, tmp, m);
    mpz_powm_ui(c_2, tmp2, 1, p);

    gmp_printf("%ZX\n%ZX\n",c_1,c_2);
  }
}

/*
Perform stage 4:

- read each 5-tuple of p, q, g, x and c = (c_1,c_2) from stdin,
- compute the ElGamal decryption m,
- then write the plaintext m to stdout.
*/

void stage4() {

  mpz_t p, q, g, x, c_1, c_2, i_c_1, tmp, m;
  mpz_inits(p,q,g,x,c_1,c_2,i_c_1,tmp,m,NULL);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX %ZX ",p,q,g,x,c_1,c_2) != EOF) {

    // Decrypt: m = c_2 * c_1^(-x mod q) mod p
    // ==> c_2 * c_1^(-1)^(x mod q) mod p

    // TODO: Should we mod x?
    mpz_invert(tmp, c_1, p);
    mpz_powm_sec(i_c_1, tmp, x, p);

    mpz_mul(tmp, i_c_1, c_2);
    mpz_powm_ui(m, tmp, 1, p);

    gmp_printf("%ZX\n",m);
  }
}

void MontMul_test() {
  gmp_randstate_t randstate;
  mpz_t omega, rho_sq, N, one, x, y, r, x_m, y_m, r_m, r2;

  mpz_inits(omega, rho_sq, N, one, x, y, r, x_m, y_m, r_m, r2, NULL);
  mpz_set_ui(one, 1);

  gmp_randinit_mt(randstate);
  gmp_randseed_ui(randstate, time(NULL));

  for (int i = 0; i < 10; i++) {
    // Pick a modulus N of up to 1024 bits
    mpz_urandomb(N, randstate, 1024); // 1024 bit
    // Ensure N is at least 5
    mpz_add_ui(N, N, 5);
    // Find a prime larger than this number.
    mpz_nextprime(N, N);

    // Find the corresponding omega and rho_sq
    findOmega(omega, N);
    findRhoSq(rho_sq, N);

    for (int j = 0; j < 10; j++) {
      // Select some random x and y
      mpz_urandomm(x, randstate, N);
      mpz_urandomm(y, randstate, N);

      // Calculate the Montgomery representation.
      MontMul(x_m, x, rho_sq, N, omega, rho_sq);
      MontMul(y_m, y, rho_sq, N, omega, rho_sq);

      // Do the multiplication x * y mod N
      mpz_mul(r, x, y);
      mpz_mod(r, r, N);
      MontMul(r_m, x_m, y_m, N, omega, rho_sq);

      // Return r_m back to normal representation.
      MontMul(r2, r_m, one, N, omega, rho_sq);

      // Check results
      if (mpz_cmp(r, r2) != 0) {
	gmp_printf("[ERROR] Failed MontMul test on\n%Zx\n\t*\n%Zx\n\tGot\n%Zx\n", x, y, r2);
	abort();
      }
    }
  }
  gmp_printf("[OK] Passed MontMul tests.\n");
}

/*
The main function acts as a driver for the assignment by simply invoking
the correct function for the requested stage.
*/

int main( int argc, char* argv[] ) {
  if( argc != 2 ) {
    MontRep_test();
    MontMul_test(); // TODO: Comment and abort()
    return 0;
  }

  /* mpz_t x, y, n, r; */
  /* mpz_inits(x,y,n,r,NULL); */
  /* mpz_set_ui(n, 99999999999); */
  /* gmp_scanf("%Zd %Zd",x,y); */
  /* gmp_printf("Calc: %Zd ^ %Zd\n", x, y); */
  /* TWOk_ary_slide_ONEexp(r, x, y, n, 4); */
  /* gmp_printf("R: %Zd\n", r); */
  /* return 0; */

  /* mpz_t rho_sq, omega, N; */
  /* mpz_inits(rho_sq, omega, N, NULL); */
  /* mpz_set_ui(N, 667); */
  /* findRhoSq(rho_sq, N); */
  /* findOmega(omega, N); */
  /* gmp_printf("%Zd\n%Zd\n%Zd\n", N, rho_sq, omega); */
  /* return 0; */

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
