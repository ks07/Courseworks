/* George Field, gf12815, version G */

#include <stdio.h>

int main(void) {
  char inputA[21], inputB[21], temp;
  int i;

  for (i = 0; i < 20; i++) {
    inputA[i] = getchar();
  }

  // We need to consume all whitespace after the first sentence,
  // up to and including the newline character.
  do {
    temp = getchar();
  } while (temp != '\n');

  for (i = 0; i < 20; i++) {
    inputB[i] = getchar();
  }

  // Not strictly necessary in this case, but lets make these valid strings.
  inputA[20] = '\0';
  inputB[20] = '\0';

  for (i = 0; i < 20; i++) {
    printf("%c", inputA[i]);
    printf("%c", inputB[i]);
  }
  
  printf("\n");

  return 0;
}
