#include <stdio.h>

/* gf12815     George Field      VERSION A
 *
 * This program is not necessarily representative of the style we
 * would like you to adopt when writing programs. It has been written
 * solely for the purpose of the practical exam.
 */

char alevel( double percentage, double failBoundary ) {
  if( percentage > 95.0 ) {
    return 'A' ;
  }
  if( percentage > 85.0 ) {
    return 'B' ;
  }
  if( percentage > 65.0 ) {
    return 'C' ;
  }
  if( percentage < failBoundary ) {
    return 'F' ;
  }
  return 'D' ;
}

int main() {
  printf("A level grade for 75%%: %c\n",alevel(75.0,30.0));
  printf("A level grade for 20%%: %c\n",alevel(20.0,30.0));
  return 0 ;
}
