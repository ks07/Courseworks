#include <stdio.h>

/* Calculates the total price for a single job with custom pricing per sheet and per plate. */
double calcJobPrice(int pages, double perSheetPrice, double perPlatePrice, int copies) {
  return ((perPlatePrice * pages) + ((pages / 2) * perSheetPrice * copies) + (2 * copies)) * 1.175;
}

/* Calculates the total price for a single black and white job. */
double calcJobBW(int pages, int copies) {
  return calcJobPrice(pages, 0.01, 7.0, copies);
}

/* Calculates the total price for a single colour job. */
double calcJobC(int pages, int copies) {
  return calcJobPrice(pages, 0.04, 28.0, copies);
}

int main(void) {
  printf("Job price is £%.2f\n", (calcJobC(32, 1000) + calcJobBW(40, 2000) + calcJobBW(160, 400)));
  return 0;
}
