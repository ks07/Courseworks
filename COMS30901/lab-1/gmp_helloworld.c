#include "gmp_helloworld.h"

int main( int argc, char* argv[] ) {
  mpz_t r0, r1, x, y;
  size_t x_n, y_n;

  mpz_init( r0 );
  mpz_init( r1 );
  mpz_init( x );
  mpz_init( y );

  gmp_scanf( "%Zd",  x );
  gmp_scanf( "%Zd",  y );

  mpz_add( r0, x, y );

  x_n = mpz_size(x);
  y_n = mpz_size(y);

  if ( y_n > x_n ) {
    mpz_swap(x, y);
  }

  mp_limb_t c = mpn_add( x->_mp_d, x->_mp_d, x_n, y->_mp_d, y_n);

  //  (x->_mp_size)++;
  //  printf("%lu %lu\n", x->_mp_size, x_n);
  if (c > 0) {
    // check that we have enough space
    //if (abs(x->_mp_size) == x->_mp_alloc) {
      x->_mp_d = realloc(x->_mp_d, x->_mp_alloc + 1);
      if (x->_mp_d == NULL) { printf("oops"); return 1; }
      //}
    // Put the carry in the top limb.
    x->_mp_d[abs(x->_mp_size)] = c;
    x->_mp_size++;
    x->_mp_alloc++;
  }

  gmp_printf( "%Zd\n%Zd\n", r0, x );

  mpz_clear( r0 );
  mpz_clear( r1 );
  mpz_clear( x );
  mpz_clear( y );

  return 0;
}
