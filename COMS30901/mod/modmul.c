#include "modmul.h"

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
    mpz_powm_sec(c, m, e, N);

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

  mpz_t N, d, p, q, d_p, d_q, i_p, i_q, c, m;
  mpz_inits(N,d,p,q,d_p,d_q,i_p,i_q,c,m,NULL);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX ",N,d,p,q,d_p,d_q,i_p,i_q,c) != EOF) {
    //gmp_printf("%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n",N,d,p,q,d_p,d_q,i_p,i_q,c);

    // Decrypt: m = c ^ d mod N
    mpz_powm_sec(m, c, d, N);

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
    mpz_urandomm(y, randstate, q);

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

/*
The main function acts as a driver for the assignment by simply invoking
the correct function for the requested stage.
*/

int main( int argc, char* argv[] ) {
  if( argc != 2 ) {
    abort();
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
