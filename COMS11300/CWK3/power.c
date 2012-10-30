#include <stdio.h>

/* Raises any real integer x to the power y, where y is a positive integer. */
int power(int x, int y) {
  /* Handle the special case where x = 0 */
  if (y == 0) {
    return 1;
  }

  int result = x;

  while(y > 1) {
    result  = result * x;
    y--;
    printf("x: %d, y: %d, r: %d\n", x, y, result);
  }

  return result;
}

int main() {
  printf("Power result: %d\n", power(8, 1));
  printf("Power result: %d\n", power(9, 6));
  printf("Power result: %d\n", power(2, 4));
  printf("Power result: %d\n", power(1000035, 0));
  return 0;
}
