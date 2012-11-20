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

/* Calculates the bounding box of two component bounding boxes. */
rectangle combineBoundingBoxes(rectangle r1, rectangle r2) {
  point sW, nE;

  /* Find the rectangle with the least x value of it's W edge. */
  if (r1.sW.x < r2.sW.x) {
    sW.x = r1.sW.x;
  } else {
    sW.x = r2.sW.x;
  }

  if (r1.sW.y < r2.sW.y) {
    sW.y = r1.sW.y;
  } else {
    sW.y = r2.sW.y;
  }

  /* Now looking for the higher values. */
  if (r1.nE.x > r2.nE.x) {
    nE.x = r1.nE.x;
  } else {
    nE.x = r2.nE.x;
  }

  if (r1.nE.y > r2.nE.y) {
    nE.y = r1.nE.y;
  } else {
    nE.y = r2.nE.y;
  }

  rectangle bB;
  bB.sW = sW;
  bB.nE = nE;

  return bB;
}

/* Prints a rectangle as two pairs of numbers, representing the SW and NE
   corners of the rectangle respectively. */
void printRectangle(rectangle r) {
  printf("(%d,%d) (%d,%d)\n", r.sW.x, r.sW.y, r.nE.x, r.nE.y);
}

int main(void) {
  int x[2], y[2], r[2];
  circle c[2];
  rectangle bB[3];

  /* Input format:
     x1 y1 r1 x2 y2 r2 */
  scanf("%d %d %d %d %d %d", &x[0], &y[0], &r[0], &x[1], &y[1], &r[1]);

  c[0] = createCircle(x[0], y[0], r[0]);
  c[1] = createCircle(x[1], y[1], r[1]);
  bB[0] = getBoundingBox(c[0]);
  bB[1] = getBoundingBox(c[1]);
  bB[2] = combineBoundingBoxes(bB[0], bB[1]);
  printRectangle(bB[2]);
  return 0;
}
