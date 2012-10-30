#include <stdio.h>

/* Raises any real number x to the power y, where y is an integer. */
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
      /* Debug Code
	 printf("x: %f, y: %d, r: %f\n", x, y, result); */
    }

    result = 1.0 / result;
  } else {
    for (; y > 1; y--) {
      result = result * x;
      /* Debug Code
	 printf("x: %f, y: %d, r: %f\n", x, y, result); */
    }
  }

  return result;
}

/* Raises any real number x to the power y using the indian algorithm. Y must be a positive integer. */
double powerIndian(double x, int y) {
  /* Use a bitwise AND to check if odd or even. This works as if the least
       significant bit is a 1, the number is odd. Anything and'ed with 1 will
       only result in a 1 if the LSB is 1 - i.e. an odd number. This should,
       in theory, be faster than using the modulus operator too. */
  if (y == 0) {
    return 1.0;
  } else if ((y & 1) == 1) {
    /* y is odd. */

    return x * (powerIndian(x, y - 1));
  } else {
    /* y is even. */

    /* We cannot use powerIndian to square this result, as it will recurse
       infinitely. Therefore, we square this value 'manually'. In this case,
       we could have called powerIndian twice and multiplied them, but for
       large values of y, this may be slow, so we introduce a new variable. */
    double toSquare = powerIndian(x, y / 2.0);
    return toSquare * toSquare;
  }
}

int main() {
  printf("%f\n", 1000 * power(1.0 + (5.0/100.0), 25));
  printf("%f\n", 10000 * power(1 + (4.0/100.0), -12));
  printf("%f\n", 1000 * powerIndian(1.0 + (5.0/100.0), 25));
  printf("%f\n", powerIndian(1.0000000001, 1000000000));
  printf("%f\n", power(1.0000000001, 1000000000));
  return 0;
}
