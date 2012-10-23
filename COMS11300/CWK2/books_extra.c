#include <stdio.h>

/* Rounds the number of pages to print to fit n-fold signatures. E.g. 16-fold signatures. */
int roundPagesToSignature(int pages, int signature) {
  if ((pages % signature) == 0 ) {
    return pages;
  } else {
    return pages + (signature - (pages % signature));
  }
}

/* Calculates the total price for a single job with custom pricing per sheet and per plate. */
double calcJobPrice(int pages, double perSheetPrice, double perPlatePrice, int copies) {
  return ((perPlatePrice * pages) + ((roundPagesToSignature(pages, 16) / 2) * perSheetPrice * copies) + (2 * copies)) * 1.175;
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
  printf("£%.2f\n", (calcJobC(32, 1000) + calcJobBW(40, 2000) + calcJobBW(160, 400)));
  printf("£%.2f\n", calcJobC(30, 50));
  printf("£%.2f\n", calcJobBW(34, 35));
  return 0;
}
