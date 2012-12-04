/* George Field, gf12815, version G */

#include <stdio.h>

int main(void) {
  int input[11];
  int i, result;
  int largest = 0;

  for (i = 0; i < 11; i++) {
    scanf("%d", &input[i]);

    if (input[i] > largest) {
      largest = input[i];
    }
  }

  for (i = 0; i < 11; i++) {
    result = largest - input[i];
    printf("%d\n", result);
  }

  return 0;
}
