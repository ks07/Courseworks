#include <stdio.h>

/* Rounds the number of pages to print to fit n-fold signatures. E.g. 16-fold signatures.
   If an impossible signature is provided, e.g. 0 or -1, then 1 is used instead. */
int roundPagesToSignature(int pages, int signature) {
  if (signature < 2 || (pages % signature) == 0) {
    return pages;
  } else {
    return pages + (signature - (pages % signature));
  }
}

/* Calculates the total price for a single job with custom pricing per sheet and per plate. */
double calcJobPrice(int pages, double perSheetPrice, double perPlatePrice, int copies, int signature) {
  return ((perPlatePrice * pages) + ((roundPagesToSignature(pages, signature) / 2) * perSheetPrice * copies) + (2 * copies)) * 1.175;
}

/* Calculates the total price for a single black and white job. */
double calcJobBW(int pages, int copies, int signature) {
  return calcJobPrice(pages, 0.01, 7.0, copies, signature);
}

/* Calculates the total price for a single colour job. */
double calcJobC(int pages, int copies, int signature) {
  return calcJobPrice(pages, 0.04, 28.0, copies, signature);
}

int main(void) {
  printf("£%.3f\n", (calcJobC(32, 1000, 16) + calcJobBW(40, 2000, 16) + calcJobBW(160, 400, 16)));
  printf("£%.3f\n", calcJobC(30, 50, 16));
  printf("£%.3f\n", calcJobBW(34, 35, 16));
  printf("£%.3f\n", calcJobBW(34, 35, 8));
  printf("£%.3f\n", calcJobBW(34, 100, 6));
  return 0;
}
