#include <stdio.h>

/* Raises any real number x to the power y, where y is a positive integer. */
double power(double x, int y) {
  /* Handle the special case where x = 0 */
  if (y == 0) {
    return 1;
  }

  double result = x;

  /* No assignment statement in the for loop, we can use the variable y as-is. */
  if (y < 0) {
    for (; y < -1; y++) {
      result = result * x;
      /* Debug Code */
	 printf("x: %f, y: %d, r: %f\n", x, y, result);
    }

    result = 1.0 / result;
  } else {
    for (; y > 1; y--) {
      result = result * x;
      /* Debug Code */
	 printf("x: %f, y: %d, r: %f\n", x, y, result);
    }
  }

  return result;
}

int main() {
  printf("%f\n", 1000 * power(1.0 + (5.0/100.0), 25));
  printf("%.10f\n", power(-24.0, -5));
  printf("%f\n", power(7.0, -2));
  printf("%f\n", power(7.0, 2));
  printf("%f\n", power(1, 0));
  return 0;
}
