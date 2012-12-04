/* George Field, gf12815, version G */

#include <stdio.h>
#include <stdlib.h>

/* Copies the contents of src[] into the beginning of dest[]. Dest must be at least as
   long as src. */
void arrayCopy(char *src, int srcLen, char *dest, int destLen) {
  int i;

  for (i = 0; i < srcLen; i++) {
    dest[i] = src[i];
  }
}

int main(void) {
  char *inputA, *inputTemp, temp;
  int i, aLength, tmpLength;

  i = 0;
  aLength = 1;
  inputA = calloc(aLength, sizeof(char));
  inputTemp = NULL;

  do {
    temp = getchar();

    // Add the char to the array. We need to dynamically allocate the array.
    if (i <= aLength) {
      // We must increase the size of the array. To reduce the number of resizes, we will
      // double the length each time.
      tmpLength = aLength;
      aLength = aLength * 2;

      inputTemp = inputA;
      inputA = calloc(aLength, sizeof(char));
      
      arrayCopy(inputTemp, tmpLength, inputA, aLength);
      // Free the memory used, so we don't cause a memory leak.
      free(inputTemp);
      inputTemp = NULL;
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
  tmpLength = i + 1;
  inputTemp = calloc(tmpLength, sizeof(char));

  for (i = 0; i < tmpLength; i++) {
    inputTemp[i] = getchar();
  }

  // Not strictly necessary in this case, but lets make these valid strings.
  //inputA[20] = '\0';
  //inputB[20] = '\0';

  for (i = 0; i < tmpLength; i++) {
    printf("%c", inputA[i]);
    printf("%c", inputTemp[i]);
  }
  
  printf("\n");

  return 0;
}
