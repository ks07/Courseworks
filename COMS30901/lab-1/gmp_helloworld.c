#include "gmp_helloworld.h"

int main( int argc, char* argv[] ) {
  mpz_t r, x, y;

  mpz_init( r );
  mpz_init( x );
  mpz_init( y );

  gmp_scanf( "%Zd",  x );
  gmp_scanf( "%Zd",  y );

  mpz_sub( r, x, y );

  gmp_printf( "%Zd\n", r );

  mpz_clear( r );
  mpz_clear( x );
  mpz_clear( y );

  return 0;
}
