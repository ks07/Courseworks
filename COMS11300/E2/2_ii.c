/* George Field, gf12815, version G */

#include <stdio.h>
#include <stdlib.h>

int main(void) {
  char *inputA, *inputB, temp;
  int i, aLength, bLength;

  i = 0;
  aLength = 2; // Smallest sentence possible is "."
  inputA = calloc(aLength, sizeof(char));

  do {
    temp = getchar();

    // Add the char to the array. We need to dynamically allocate the array. Check against i+1 as we need space
    // to store the \0.
    if ((i + 1) <= aLength) {
      // We must increase the size of the array. To reduce the number of resizes, we will
      // double the length each time.
      aLength = aLength * 2;

      // Use realloc to resize an area of memory allocated previously, keeping contents intact.
      inputA = realloc(inputA, aLength * sizeof(char));
    }

    inputA[i] = temp;
    i++;
  } while (temp != '.');

  // We need to consume all whitespace after the first sentence,
  // up to and including the newline character.
  do {
    temp = getchar();
  } while (temp != '\n');

  // We know the length of the second sentence.
  bLength = i;
  inputB = calloc(bLength + 1, sizeof(char));

  for (i = 0; i <= bLength; i++) {
    inputB[i] = getchar();
  }

  // Not strictly necessary in this case, but lets make these valid strings.
  inputA[bLength] = '\0';
  inputB[bLength] = '\0';

  for (i = 0; i <= bLength; i++) {
    printf("%c", inputA[i]);
    printf("%c", inputB[i]);
  }
  
  printf("\n");

  return 0;
}
