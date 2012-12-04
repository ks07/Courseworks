/* George Field, gf12815, version G */

#include <stdio.h>

int main(void) {
  int input[11];
  int i, result;
  int largest[2]; // largest[0] = first largest, largest[1] = second largest.

  largest[0] = 0;

  for (i = 0; i < 11; i++) {
    scanf("%d", &input[i]);

    // If input is greater than the largest, set 2nd largest to old and replace.
    if (input[i] > largest[0]) {
      largest[1] = largest[0];
      largest[0] = input[i];
    } else if (input[i] > largest[1]) {
      // If input greater than 2nd but smaller than largest.
      largest[1] = input[i];
    }
  }

  for (i = 0; i < 11; i++) {
    result = largest[1] - input[i];

    // The difference should always be >= 0
    if (result < 0) {
      result = result * -1;
    }

    printf("%d\n", result);
  }

  return 0;
}
