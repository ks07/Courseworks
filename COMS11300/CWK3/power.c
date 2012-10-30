#include <stdio.h>

/* Raises any real number x to the power y, where y is a positive integer. */
double power(double x, int y) {
  /* Handle the special case where x = 0 */
  if (y == 0) {
    return 1;
  }

  double result = x;

  while(y > 1) {
    result = result * x;
    y--;
    /* Debug Code
       printf("x: %f, y: %d, r: %f\n", x, y, result); */
  }

  return result;
}

int main() {
  printf("Sum: %f\n", 1000 * power(1.0 + (5.0/100.0), 25));
  return 0;
}
