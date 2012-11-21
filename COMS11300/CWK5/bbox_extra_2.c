#include <stdlib.h>
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

/* Struct to hold a straight line segment. */
typedef struct {
  point a;
  point b;
} line;

/* Enum to tag the stored type of shape. */
typedef enum {
  IsCircle,
  IsLine
} shapeTag;

/* Wrap a union inside a struct so we can store a tag indicating the type. */
typedef struct {
  shapeTag shapeType;

  union {
    circle c;
    line l;
  } sh;
} shape;

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

/* Creates a line struct from two pairs of co-ordinates. */
line createLine(int x1, int y1, int x2, int y2) {
  point a, b;
  a.x = x1;
  a.y = y1;
  b.x = x2;
  b.y = y2;

  line ret;
  ret.a = a;
  ret.b = b;

  return ret;
}

/* Calculates the bounding box of a shape. */
rectangle getBoundingBox(shape s) {
  rectangle ret;
  point nE, sW;

  if (s.shapeType == IsCircle) {
    nE.x = s.sh.c.centre.x + s.sh.c.r;
    nE.y = s.sh.c.centre.y + s.sh.c.r;

    sW.x = s.sh.c.centre.x - s.sh.c.r;
    sW.y = s.sh.c.centre.y - s.sh.c.r;
  } else {
    /* Need to find the most SW co-ords from both points. */
    if (s.sh.l.a.x < s.sh.l.b.x) {
      sW.x = s.sh.l.a.x;
      nE.x = s.sh.l.b.x;
    } else {
      sW.x = s.sh.l.b.x;
      nE.x = s.sh.l.a.x;
    }

    if (s.sh.l.a.y < s.sh.l.b.y) {
      sW.y = s.sh.l.a.y;
      nE.y = s.sh.l.b.y;
    } else {
      sW.y = s.sh.l.b.y;
      nE.y = s.sh.l.a.y;
    }
  }

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
  char sType, init, args;
  shape s;
  rectangle bBox;
  int input[4];
  circle c;
  line l;

  /* init marks if we have created our first bounding box */
  init = 0;

  scanf("%c", &sType);
  while (sType != '\n') {
    switch (sType) {
    case 'L':
    case 'l':
      args = scanf("%d %d %d %d", &(input[0]), &(input[1]), &(input[2]), &(input[3]));

      if (args != 4) {
	printf("Error: Invalid arguments for a line.\n");
	/* Return non-zero value if process did not complete normally. */
	return 1;
      }

      l = createLine(input[0], input[1], input[2], input[3]);
      s.shapeType = IsLine;
      s.sh.l = l;
      break;
    case 'C':
    case 'c':
      args = scanf("%d %d %d", &(input[0]), &(input[1]), &(input[2]));

      if (args != 3) {
        printf("Error: Invalid arguments for a circle.\n");
        return 1;
      }

      c = createCircle(input[0], input[1], input[2]);
      s.shapeType = IsCircle;
      s.sh.c = c;
      break;
    default:
      printf("Error: Invalid shape type '%c'.\n", sType);
      return 1;
    }

    /* If this is our first run, we should only create the original
       bounding box. */
    if (init == 0) {
      bBox = getBoundingBox(s);
      init = 1;
    } else {
      bBox = combineBoundingBoxes(bBox, getBoundingBox(s));
    }

    /* Advance through input until we get to the next
       non-whitespace (or \n). */
    do {
      scanf("%c", &sType);
    } while (sType == ' ' || sType == '\t');
  }

  printRectangle(bBox);

  return 0;
}
