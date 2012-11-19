#include <stdio.h>

/* References to compass directions throughout treat the positive y direction
   as north, the positive x direction as east, etc. */

/* Struct to hold a point in 2D space. */
typedef struct {
  int x;
  int y;
} point;

/* Struct to hold a circle. */
typedef struct {
  point centre;
  int r;
} circle;

/* Struct to hold bounding boxes. */
typedef struct {
  point nE;
  point sW;
} rectangle;

/* Creates a circle struct from the centre's co-ordinates and the radius. */ 
circle createCircle(int x, int y, int radius) {
  point centre;
  centre.x = x;
  centre.y = y;
  
  circle ret;
  ret.centre = centre;
  ret.r = radius;
  
  return ret;
}

/* Calculates the bounding box of a circle. */
rectangle getBoundingBox(circle c) {
  rectangle ret;
  point nE, sW;

  nE.x = c.centre.x + c.r;
  nE.y = c.centre.y + c.r;

  sW.x = c.centre.x - c.r;
  sW.y = c.centre.y - c.r;

  ret.nE = nE;
  ret.sW = sW;

  return ret;
}

/* Prints a rectangle as two pairs of numbers, representing the SW and NE
   corners of the rectangle respectively. */
void printRectangle(rectangle r) {
  printf("(%d,%d) (%d,%d)\n", r.sW.x, r.sW.y, r.nE.x, r.nE.y);
}

int main(void) {
  circle c = createCircle(1, 2, 3);
  rectangle boundingBox = getBoundingBox(c);
  printRectangle(boundingBox);
  return 0;
}
