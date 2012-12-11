/* George Field. gf12815, version C */

#include <stdio.h>
#include <stdlib.h>

// Will use doubles for averages, as the average is not guaranteed to be an integer.
double average(int numbers[], int length) {
  int i;
  double result = 0;

  for (i=0; i<length; i++) {
    result = result + (double)numbers[i];
  }

  result = result / length;
  return result;
}

void printDifferencesFromAvg(int numbers[], int length) {
  double avg = average(numbers, length);
  int i;

  for (i = 0; i<length; i++) {
    printf("%f\n", avg - (double)numbers[i]);
  }
}

int main(void) {
  int numbers[40];
  int i = 0;

  do {
    scanf("%d", &numbers[i]);
    i++;
  } while (i < 40 && numbers[i-1] != -1);

  printDifferencesFromAvg(numbers, i);

  return 0;
}
