#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>

#define NO_MAIN

#define MAX_LINE_LEN 100
#define MAX_GRAPH_DIM 20

#define NO_PRED -1
#define START_VERT -2

//TODO: Rename to Edge?
typedef struct Teleport {
  int dX;
  int dY;
  int w; // If weight < 0, no teleport here.
} Teleport;

typedef struct Vertex {
  bool open;
  Teleport t;
  int dist;
  int x;
  int y;
  int pX;
  int pY;
  int qPos;
} Vertex;

typedef struct Graph {
  Vertex **nodes;
  int maxDim;
} Graph;

#include "priorityQueue.c"

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

Vertex * newVertex(bool open) {
  Vertex *new = calloc(1, sizeof(Vertex));
  new -> dist = -1;
  new -> open = open;
  return new;
}

void printMap(Graph *g) {
  int x, y;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      printf(g->nodes[y][x].open ? "." : "#");
    }
    printf("|\n");
  }
}

inline int calculateMaxEdges(int n) {
  // All edges are bi-rectional, no diagonals.
  // 2* 2n(n-1) + teleports
  // Max teleports = floor(n^2 / 2)
  // TODO: Count teleports
  //return 4 * n * (n-1) + ((n*n) / 2)
  return (4.5 * n * n) - (4 * n);
}

void relax(QueueEle queue[], Vertex **nodes, int uX, int uY, int vX, int vY, int w) {
  if (nodes[vY][vX].dist > nodes[uY][uX].dist + w) {
    printf("Decreasing (%d,%d) from %d/%d to %d. Pred = (%d,%d)\n", vX, vY, nodes[vY][vX].dist, queue[nodes[vY][vX].qPos].key, nodes[uY][uX].dist + w, uX, uY);
    decreaseKey(queue, nodes[vY][vX].qPos, nodes[uY][uX].dist + w);
    nodes[vY][vX].pX = uX;
    nodes[vY][vX].pY = uY;
    nodes[vY][vX].dist = nodes[uY][uX].dist + w;
    printf("  Now vY,vX key = %d/%d\n", nodes[vY][vX].dist, queue[nodes[vY][vX].qPos].key);
  }
}

void djikstra(Graph *g, int sX, int sY) {
  Vertex **nodes = g->nodes;
  nodes[sY][sX].pX = START_VERT;
  nodes[sY][sX].pX = START_VERT;

  // Create a queue for all vertices.
  // TODO: Better size creation, count unblocked.
  QueueEle *queue = malloc(g->maxDim * g->maxDim * sizeof(QueueEle));
  int y, x, tmp;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      // Only count node if open.
      if (nodes[y][x].open) {
	//TODO: Stop duplicating info, merge structs?
	//TODO: Change dis.
	printf("Inserting %d,%d\n", x, y);
	nodes[y][x].dist = INT_MAX;
	insert(queue, &(nodes[y][x]), (x == sX && y == sY) ? 0 : INT_MAX);
      }
    }
  }

  // Set start node dist to 0.
  nodes[sY][sX].dist = 0;

  QueueEle curr;
  // Iterate through vertices updating the distances.
  while (notEmpty(queue)) {
    // TODO: Finish when extracting end point
    curr = extractMin(queue);
    y = curr.data->y;
    x = curr.data->x;
    printf("Point %d,%d - Distance: %d %d\n", x, y, curr.data->dist, curr.pos);
    if (x == y && y == g->maxDim-1) {
      printf("WINNER WINNER CHICKEN DINNER\n   Point %d,%d - Distance: %d\n", x, y, curr.data->dist);
      
      // Trace path backwards.
      while (x != START_VERT && y != START_VERT) {
	printf("     (%d,%d)\n", x, y);
	tmp = nodes[y][x].pX;
	y = nodes[y][x].pY;
	x = tmp;
      }
	

      return;
    }

    // for each vertex v such that u -> v
    //TODO: Bitmask cache of open directions?
    // Check N
    if (y > 0 && nodes[y-1][x].open) {
      // relax(u,v)
      relax(queue, nodes, x, y, x, y-1, 1); 
    }
    // Check E
    if (x < g->maxDim-1 && nodes[y][x+1].open) {
      relax(queue, nodes, x, y, x+1, y, 1);
    }
    // S
    if (y < g->maxDim-1 && nodes[y+1][x].open) {
      relax(queue, nodes, x, y, x, y+1, 1);
    }
    // W
    if (x > 0 && nodes[y][x-1].open) {
      relax(queue, nodes, x, y, x-1, y, 1);
    }
    // Teleport
    if (nodes[y][x].t.w >= 0) {
      relax(queue, nodes, x, y, nodes[y][x].t.dX, nodes[y][x].t.dY, nodes[y][x].t.w);
    }
  }
}

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

  printf("Making array of size %d squared\n", graphLim);
  
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

  // Read map definitions into a temporary matrix of blocked locations.
  while (fgets(line, MAX_LINE_LEN, mapFile) != NULL) {
    int x1, y1, x2, y2, tw;
    if (line[0] == 'b') {
      // This line defines a blocked rectangle.
      // Format: 'b x1 y1 x2 y2' 1 <= 2
      sscanf(line, "b %5d %5d %5d %5d ", &x1, &y1, &x2, &y2);
      printf("Blocking %d,%d to %d,%d\n", x1, y1, x2, y2);

      for (y = y1 - 1; y < y2; y++) {
	for (x = x1 - 1; x < x2; x++) {
	  graph -> nodes[y][x].open = false;
	}
      }
    } else if (line[0] == 't') {
      sscanf(line, "t %5d %5d %5d %5d %5d ", &x1, &y1, &x2, &y2, &tw);
      printf("Teleporting %d,%d to %d,%d - cost %d\n", x1, y1, x2, y2, tw);

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

  printMap(graph);
  printf("Feeding into djikstra's!\n");

  djikstra(graph, 0, 0);

  printf("I did it mom!");
  // freeStructs();
  return 0;
}

