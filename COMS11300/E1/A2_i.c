#include <stdio.h>

/* gf12815     George Field    VERSION A
 *
 * This program is not necessarily representative of the style we
 * would like you to adopt when writing programs. It has been written
 * solely for the purpose of the practical exam.
 *
 * This function calculates the probability that  if you
 * flipping a coin 10 times in a row, you will get 10 tails.
 */
double teninrow() {
  int i=1;
  double p = 1.0 ;
  while(i<11) {
    p = p * 0.5 ;
    i++;
  }
  return p ;
}

int main() {
  printf( "10-in-row: %f\n", teninrow() ) ;
  return 0 ;
}
