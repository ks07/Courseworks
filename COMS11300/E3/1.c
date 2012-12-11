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

// Returns 1 if number is an integer.
int isInt(double number) {
  int numberAsInt = (int) number;
  double result = number - ((double)numberAsInt);
  if (result != 0) {
    return 0;
  } else {
    return 1;
  }
}

void printDifferencesFromAvg(int numbers[], int length) {
  double avg = average(numbers, length);
  int i;

  /* To make sure we can handle decimal averages, while still matching the
     example output given, we need to change our formatting depending on avg. */
  if (isInt(avg) == 1) {
    for (i = 0; i<length; i++) {
      printf("%.0f\n", avg - (double)numbers[i]);
    }
  } else {
    for (i = 0; i<length; i++) {
      printf("%f\n", avg - (double)numbers[i]);
    }
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
