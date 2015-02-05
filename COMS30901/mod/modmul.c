#include "modmul.h"

/*
Perform stage 1:

- read each 3-tuple of N, e and m from stdin,
- compute the RSA encryption c,
- then write the ciphertext c to stdout.
*/

void stage1() {

  mpz_t N, e, m, tmp;
  mpz_inits(N,e,m,tmp,NULL);

  while (gmp_scanf("%ZX %ZX %ZX ",N,e,m) != EOF) {
    //gmp_printf("%ZX\n%ZX\n%ZX\n",N,e,m);

    // Encrypt: y = m ^ e mod N
    mpz_powm_sec(tmp, m, e, N);

    gmp_printf("%ZX\n",tmp);
  }
}

/*
Perform stage 2:

- read each 9-tuple of N, d, p, q, d_p, d_q, i_p, i_q and c from stdin,
- compute the RSA decryption m,
- then write the plaintext m to stdout.
*/

void stage2() {

  mpz_t N, d, p, q, d_p, d_q, i_p, i_q, c, tmp;
  mpz_inits(N,d,p,q,d_p,d_q,i_p,i_q,c,tmp,NULL);

  while (gmp_scanf("%ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX %ZX ",N,d,p,q,d_p,d_q,i_p,i_q,c) != EOF) {
    //gmp_printf("%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n%ZX\n",N,d,p,q,d_p,d_q,i_p,i_q,c);

    // Decrypt: m = c ^ d mod N
    mpz_powm_sec(tmp, c, d, N);

    gmp_printf("%ZX\n",tmp);
  }
}

/*
Perform stage 3:

- read each 5-tuple of p, q, g, h and m from stdin,
- compute the ElGamal encryption c = (c_1,c_2),
- then write the ciphertext c to stdout.
*/

void stage3() {

  // fill in this function with solution

}

/*
Perform stage 4:

- read each 5-tuple of p, q, g, x and c = (c_1,c_2) from stdin,
- compute the ElGamal decryption m,
- then write the plaintext m to stdout.
*/

void stage4() {

  // fill in this function with solution

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
