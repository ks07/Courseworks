#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>
#include <string.h>
//TODO: Remove reliance on strlen

#define MAX_LINE_LEN 50
#define MAX_GRAPH_DIM 20

#define NO_PRED -1
#define START_VERT -2

typedef struct Teleport {
  int dX;
  int dY;
  int w; // If weight < 0, no teleport here.
} Teleport;

typedef struct Vertex {
  bool open;
  Teleport t;
  int x;
  int y;
  int pX;
  int pY;
  int qPos;
  int key;
} Vertex;

typedef struct Graph {
  Vertex *nodes;
  int maxDim;
} Graph;

#include "priorityQueue.c"

#define flat(y, x, size) (size * y + x)

#define gget(g, y, x) g->nodes[flat(y, x, g->maxDim)]

Vertex *allocSquare(int size) {
  // Store matrix flattened into a 1d array, less memory operations.
  return (Vertex *)malloc(size * size * sizeof(Vertex));
}

void printMap(Graph *g) {
  int x, y;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      printf(gget(g, y, x).open ? (gget(g, y, x).t.w >= 0 ? "?" : ".") : "#");
    }
    printf("|\n");
  }
}

void relax(Vertex *queue[], Graph *g, int uX, int uY, int vX, int vY, int w) {
  if (gget(g, vY, vX).key > w) {
#ifdef DBGP
    printf("Decreasing (%d,%d) from %d to %d. Pred = (%d,%d)\n", vX, vY, gget(g, vY, vX).key, w, uX, uY);
#endif
    decreaseKey(queue, gget(g, vY, vX).qPos, w);
    gget(g, vY, vX).pX = uX;
    gget(g, vY, vX).pY = uY;
  }
}

char getDirection(int x, int y, int pX, int pY) {
  if (y == pY) {
    if (x > pX) {
      return 'E';
    } else if (x < pX) {
      return 'W';
    } else {
      // No move?
      printf("ERROR: No movement recorded for predecessor.");
      return 'T';
    }
  } else if (x == pX) {
    if (y > pY) {
      return 'S';
    } else if (y < pY) {
      return 'N';
    } else {
      printf ("ERROR: No movement recorded for predecessor.");
      return 'T';
    }
  } else {
    return 'T';
  }
}

char *djikstra(Graph *g, int sX, int sY) {
  gget(g, sY, sX).pX = START_VERT;
  gget(g, sY, sX).pX = START_VERT;

  // Create a queue for all vertices.
  // TODO: Better size creation, count unblocked.
  Vertex **queue = malloc(g->maxDim * g->maxDim * sizeof(Vertex *));
  queue[0] = calloc(1, sizeof(Vertex)); // Add size vertex.

  heapSizeSet(queue, 0);
  int y, x, tmp;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      // Only count node if open.
      if (gget(g, y, x).open) {
	insert(queue, &(gget(g, y, x)), (y == sY && x == sX) ? 0 : INT_MAX);
      }
    }
  }

  char *ret;
  int i;
  Vertex *curr;
  // Iterate through vertices updating the distances.
  while (notEmpty(queue)) {
    curr = extractMin(queue);
    y = curr->y;
    x = curr->x;
#ifdef DBGP
    printf("Point %d,%d - Distance: %d\n", x, y, curr->key);
#endif
    if (curr->key == INT_MAX) {
      // The key of the minimum element is the initial non-relaxed value. This means we have
      // explored all possibilities, remaining nodes are isolated from start.
      return "";
    } else if (x == y && y == g->maxDim-1) {
#ifdef DBGP
      printf("Route Found:\n   Point %d,%d - Distance: %d\n", x, y, curr->key);
#endif
      i = 0;
      // Trace path backwards.
      ret = malloc(sizeof(char) * (curr->key + 1));
      while ((x != sX || y != sY) && x >= 0 && y >= 0) {
#ifdef DBGP
	printf("     (%d,%d)\n", x, y);
#endif
	ret[i] = getDirection(x, y, gget(g, y, x).pX, gget(g, y, x).pY);

	tmp = gget(g, y, x).pX;
	y = gget(g, y, x).pY;
	x = tmp;
	i++;
      }

      ret[i] = '\0';
      return ret;
    }

    // for each vertex v such that u -> v
    //TODO: Bitmask cache of open directions?
    // Check S
    if (y < g->maxDim-1 && gget(g, y+1, x).open) {
      relax(queue, g, x, y, x, y+1, curr->key + 1);
    }
    // Check E
    if (x < g->maxDim-1 && gget(g, y, x+1).open) {
      relax(queue, g, x, y, x+1, y, curr->key + 1);
    }
    // Check N
    if (y > 0 && gget(g, y-1, x).open) {
      // relax(u,v)
      relax(queue, g, x, y, x, y-1, curr->key + 1); 
    }
    // Check W
    if (x > 0 && gget(g, y, x-1).open) {
      relax(queue, g, x, y, x-1, y, curr->key + 1);
    }
    // Teleport
    if (gget(g, y, x).t.w >= 0) {
      relax(queue, g, x, y, gget(g, y, x).t.dX, gget(g, y, x).t.dY, curr->key + gget(g, y, x).t.w);
    }
  }

  return "";
}

void printStringR(char *str) {
  int i = strlen(str) - 1;
  for (; i >= 0; i--) {
    printf("%c", str[i]);
  }
  printf("\n");
}

#ifndef DBGQ
int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("USAGE: robot <filename>\n");
    return 1;
  }

  int graphLim;
  char line[MAX_LINE_LEN];
  char *temp;
  FILE *mapFile;

  mapFile = fopen(argv[1], "r");
  // Read line 1, should be map size.
  temp = fgets(line, MAX_LINE_LEN, mapFile);
  if (temp == NULL) {
    return 2;
  } else {
    sscanf(line, "%5d ", &graphLim);
  }
  
  // Build a graph/vertex representation of the map.
  Graph *g = malloc(sizeof(Graph));
  g -> maxDim = graphLim;
  g -> nodes = allocSquare(graphLim);
  int x, y;
  for (y = 0; y < graphLim; y++) {
    for (x = 0; x < graphLim; x++) {
      gget(g, y, x).open = true;
      gget(g, y, x).t.w = -1;
      gget(g, y, x).pX = NO_PRED;
      gget(g, y, x).pY = NO_PRED;
      gget(g, y, x).x = x;
      gget(g, y, x).y = y;
    }
  }

  while (fgets(line, MAX_LINE_LEN, mapFile) != NULL) {
    int x1, y1, x2, y2, tw;
    if (line[0] == 'b') {
      // This line defines a blocked rectangle.
      // Format: 'b x1 y1 x2 y2' 1 <= 2
      sscanf(line, "b %5d %5d %5d %5d ", &x1, &y1, &x2, &y2);

      for (y = y1 - 1; y < y2; y++) {
	for (x = x1 - 1; x < x2; x++) {
	  gget(g, y, x).open = false;
	}
      }
    } else if (line[0] == 't') {
      // A teleport, 't x1 y1 x2 y2 w' 1 != 2, w >= 0
      sscanf(line, "t %5d %5d %5d %5d %5d ", &x1, &y1, &x2, &y2, &tw);
      x1--;
      x2--;
      y1--;
      y2--;

      gget(g, y1, x1).t.dX = x2;
      gget(g, y1, x1).t.dY = y2;
      gget(g, y1, x1).t.w = tw;
    } else {
      // Unknown line!
      printf("Warning: ignored line %s\n", line);
    }
  }

  // Close the file.
  fclose(mapFile);

#ifdef DBGP_MAP
  printMap(g);
#endif

  printStringR(djikstra(g, 0, 0));

  // freeStructs();
  return 0;
}
#endif
