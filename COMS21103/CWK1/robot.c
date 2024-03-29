#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>

#define MAX_LINE_LEN 50
#define MAX_GRAPH_DIM 20

#define NO_PRED -1
#define START_VERT -2

// Struct to group information about a teleport.
typedef struct Teleport {
  int dX;
  int dY;
  int w; // If weight < 0, no teleport here.
} Teleport;

// Struct to hold information about a vertex.
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

// Struct to hold graph global information.
typedef struct Graph {
  Vertex **nodes;
  int maxDim;
} Graph;

// Include the priorityQueue code. This must be here, as it relies on the Vertex type.
#include "priorityQueue.c"

// Allocates a square matrix to hold the graph. Need to allocate rows/cols separately,
// as an array of arrays does not degrade into a pointer to a pointer! (How would it know indexes?)
Vertex **allocSquare(int size) {
  // Allocate the rows (y)
  Vertex **square = malloc(size * sizeof(Vertex *));
  int i;
  for (i = 0; i < size; i++) {
    // Add an array for each row, creating the columns (x).
    square[i] = malloc(size * sizeof(Vertex));
  }

  return square;
}

// Frees rows/cols of the matrix.
void freeSquare(Vertex **square, int size) {
  int i;
  for (i = 0; i < size; i++) {
    free(square[i]);
  }
  free(square);
}

// Basic printing of graph, for debugging IO. Not suitable for large inputs.
void printMap(Graph *g) {
  int x, y;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      printf(g->nodes[y][x].open ? (g->nodes[y][x].t.w >= 0 ? "?" : ".") : "#");
    }
    printf("|\n");
  }
}

// Used in djikstra's algorithm to update node distances if necessary.
void relax(Vertex *queue[], Vertex **nodes, int uX, int uY, int vX, int vY, int w) {
  if (nodes[vY][vX].key > w) {
#ifdef DBGP
    printf("Decreasing (%d,%d) from %d to %d. Pred = (%d,%d)\n", vX, vY, nodes[vY][vX].key, w, uX, uY);
#endif
    decreaseKey(queue, nodes[vY][vX].qPos, w);
    nodes[vY][vX].pX = uX;
    nodes[vY][vX].pY = uY;
  }
}

// Converts a point and predecessor point pair into a direction.
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

// Simple struct to allow djikstra to return both the string and it's length.
typedef struct DjikstraResult {
  char *rPath;
  int len;
} DjikstraResult;

// Performs djikstra's algorithm on the graph from sX,sY. The returned path is reversed.
DjikstraResult djikstra(Graph *g, int sX, int sY) {
  DjikstraResult res = {"", 0};
  Vertex **nodes = g->nodes;
  nodes[sY][sX].pX = START_VERT;
  nodes[sY][sX].pX = START_VERT;

  // Create a queue for all vertices.
  // TODO: Better size creation, count unblocked.
  Vertex **queue = malloc(g->maxDim * g->maxDim * sizeof(Vertex *));
  queue[0] = calloc(1, sizeof(Vertex)); // Add size vertex.

  heapSizeSet(queue, 0);
  int y, x, tmp;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      // Only count node if open.
      if (nodes[y][x].open) {
	insert(queue, &(nodes[y][x]), (y == sY && x == sX) ? 0 : INT_MAX);
      }
    }
  }

  int i;
  Vertex *curr;
  // Iterate through vertices updating the distances.
  while (notEmpty(queue)) {
    curr = extractMin(queue);
    y = curr->y;
    x = curr->x;
#ifdef DBGP
    printf("Point %d,%d - Distance: %d\n", x, y, curr->key); // Use preprocessor to remove debug prints.
#endif
    // TODO: Variable end point
    if (curr->key == INT_MAX) {
      // The key of the minimum element is the initial non-relaxed value. This means we have
      // explored all possibilities, remaining nodes are isolated from start.
      free(queue);
      return res;
    } else if (x == y && y == g->maxDim-1) {
#ifdef DBGP
      printf("Route Found:\n   Point %d,%d - Distance: %d\n", x, y, curr->key);
#endif
      i = 0;
      // Trace path backwards.
      res.rPath = malloc(sizeof(char) * (curr->key + 1));
      res.len = 0;
      while ((x != sX || y != sY) && x >= 0 && y >= 0) {
#ifdef DBGP
	printf("     (%d,%d)\n", x, y);
#endif
	res.rPath[i] = getDirection(x, y, nodes[y][x].pX, nodes[y][x].pY);

	tmp = nodes[y][x].pX;
	y = nodes[y][x].pY;
	x = tmp;
	i++;
      }

      res.rPath[i] = '\0';
      res.len = i;
      free(queue);
      return res;
    }

    // for each vertex v such that u -> v
    //TODO: Bitmask cache of open directions?
    // Check S
    if (y < g->maxDim-1 && nodes[y+1][x].open) {
      relax(queue, nodes, x, y, x, y+1, curr->key + 1);
    }
    // Check E
    if (x < g->maxDim-1 && nodes[y][x+1].open) {
      relax(queue, nodes, x, y, x+1, y, curr->key + 1);
    }
    // Check N
    if (y > 0 && nodes[y-1][x].open) {
      // relax(u,v)
      relax(queue, nodes, x, y, x, y-1, curr->key + 1); 
    }
    // Check W
    if (x > 0 && nodes[y][x-1].open) {
      relax(queue, nodes, x, y, x-1, y, curr->key + 1);
    }
    // Teleport
    if (nodes[y][x].t.w >= 0) {
      relax(queue, nodes, x, y, nodes[y][x].t.dX, nodes[y][x].t.dY, curr->key + nodes[y][x].t.w);
    }
  }

  free(queue);
  return res;
}

// Prints a string character by character in reverse.
void printStringR(char *str, int len) {
  for (len--; len >= 0; len--) {
    printf("%c", str[len]);
  }
  printf("\n");
}

// Main function. Use preprocessor to remove this definition if we want to test the PriorityQueue
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
  Graph *graph = malloc(sizeof(Graph));
  graph -> maxDim = graphLim;
  graph -> nodes = allocSquare(graphLim);
  int x, y;
  for (y = 0; y < graphLim; y++) {
    for (x = 0; x < graphLim; x++) {
      graph -> nodes[y][x].open = true;
      graph -> nodes[y][x].t.w = -1;
      graph -> nodes[y][x].pX = NO_PRED;
      graph -> nodes[y][x].pY = NO_PRED;
      graph -> nodes[y][x].x = x;
      graph -> nodes[y][x].y = y;
    }
  }

  // Start reading bulk of file
  while (fgets(line, MAX_LINE_LEN, mapFile) != NULL) {
    int x1, y1, x2, y2, tw;
    if (line[0] == 'b') {
      // This line defines a blocked rectangle.
      // Format: 'b x1 y1 x2 y2' 1 <= 2
      sscanf(line, "b %5d %5d %5d %5d ", &x1, &y1, &x2, &y2);

      for (y = y1 - 1; y < y2; y++) {
	for (x = x1 - 1; x < x2; x++) {
	  graph -> nodes[y][x].open = false;
	}
      }
    } else if (line[0] == 't') {
      // A teleport, 't x1 y1 x2 y2 w' 1 != 2, w >= 0
      sscanf(line, "t %5d %5d %5d %5d %5d ", &x1, &y1, &x2, &y2, &tw);
      x1--;
      x2--;
      y1--;
      y2--;

      graph -> nodes[y1][x1].t.dX = x2;
      graph -> nodes[y1][x1].t.dY = y2;
      graph -> nodes[y1][x1].t.w = tw;
    } else {
      // Unknown line!
      printf("Warning: ignored line %s\n", line);
    }
  }

  // Close the file.
  fclose(mapFile);

#ifdef DBGP_MAP
  printMap(graph);
#endif

  DjikstraResult dr = djikstra(graph, 0, 0);
  printStringR(dr.rPath, dr.len);

  // Free resources before we quit.
  freeSquare(graph->nodes, graph->maxDim);
  free(graph);
  if (dr.len > 0) {
    free(dr.rPath);
  }
  return 0;
}
#endif
