#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>

#define NO_MAIN
#include "priorityQueue.c"

#define MAX_LINE_LEN 100
#define MAX_GRAPH_DIM 20

//TODO: Rename to Edge?
typedef struct Teleport {
  int dX;
  int dY;
  int weight; // If weight < 0, no teleport here.
} Teleport;

typedef struct Vertex {
  bool open;
  Teleport t;
  int dist;
  int x;
  int y;
  int pX;
  int pY;
} Vertex;

typedef struct Graph {
  Vertex **nodes;
  int maxDim;
} Graph;

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

typedef struct PointPairList {
  struct PointPairList *next;
  int x1;
  int y1;
  int x2;
  int y2;
} PointPairList;

Vertex * newVertex(bool open) {
  Vertex *new = calloc(1, sizeof(Vertex));
  new -> dist = -1;
  new -> open = open;
  return new;
}

void printMap(int maxDim, bool map[maxDim][maxDim]) {
  int x, y;
  for (y = 0; y < maxDim; y++) {
    for (x = 0; x < maxDim; x++) {
      printf(map[y][x] ? "." : "#");
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

void relax(QueueEle queue[], Vertex **nodes, int uX, int uY, int vX, int vY, int w, int vPos) {
  if (nodes[vY][vX].dist > nodes[uY][uX].dist + w) {
    decreaseKey(queue, vPos, nodes[uY][uX].dist + w);
  }
}

void djikstra(Graph *g, int sX, int sY) {
  Vertex **nodes = g->nodes;
  nodes[sY][sX].dist = 0;

  // Create a queue for all vertices.
  // TODO: Better size creation, count unblocked.
  QueueEle *queue = malloc(g->maxDim * g->maxDim * sizeof(QueueEle));
  //  int count = 1;
  int y, x;
  for (y = 0; y < g->maxDim; y++) {
    for (x = 0; x < g->maxDim; x++) {
      // Only count node if open.
      if (nodes[y][x].open) {
	//TODO: Stop duplicating info, merge structs?
	//queue[count].pos = count;
	//queue[count].key = nodes[y][x].dist;
	//queue[count].data = &(nodes[y][x]);
	insert(queue, (QueueEle){&(nodes[y][x]), -1, INT_MAX});
      }
    }
  }
  QueueEle curr;
  // Iterate through vertices updating the distances.
  while (notEmpty(queue)) {
    curr = (Vertex *)extractMin(queue);
    y = curr->y;
    x = curr->x;
    // for each vertex v such that u -> v
    //TODO: Bitmask cache of open directions?
    // Check N
    if (y > 0 && nodes[y-1][x].open) {
      // relax(u,v)
      relax(queue, nodes, x, y, x, y-1, 1, curr->pos); 
    }
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("USAGE: robot <filename>\n");
    return 1;
  }

  //bool point[MAX_GRAPH_DIM][MAX_GRAPH_DIM];
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
  
  bool map[graphLim][graphLim];
  
  int x, y;
  for (y = 0; y < graphLim; y++) {
    for (x = 0; x < graphLim; x++) {
      map[y][x] = true;
    }
  }

  // Read map definitions into a temporary matrix of blocked locations.
  while (fgets(line, MAX_LINE_LEN, mapFile) != NULL) {
    printf("%s\n", line);
    int x1, y1, x2, y2;
    if (line[0] == 'b') {
      // This line defines a blocked rectangle.
      // Format: 'b x1 y1 x2 y2' 1 <= 2
      sscanf(line, "b %5d %5d %5d %5d ", &x1, &y1, &x2, &y2);
      printf("Blocking %d,%d to %d,%d\n", x1, y1, x2, y2);

      for (y = y1 - 1; y < y2; y++) {
	for (x = x1 - 1; x < x2; x++) {
	  map[y][x] = false;
	}
      }
    } else if (line[0] == 't') {
      sscanf(line, "t %5d %5d %5d %5d ", &x1, &y1, &x2, &y2);
      printf("Teleporting %d,%d to %d,%d\n", x1, y1, x2, y2);

      // TODO: Support teleports
    } else {
      // Unknown line!
      printf("Warning: ignored line %s\n", line);
    }
  }

  // Close the file.
  fclose(mapFile);

  // Build a graph/vertex representation of the map.
  Graph *graph = malloc(sizeof(Graph));
  graph -> maxDim = graphLim;
  graph -> nodes = allocSquare(graphLim);
  for (y = 0; y < graphLim; y++) {
    for (x = 0; x < graphLim; x++) {
      // TODO: This is fucking stupid. Why am I doing this?
      graph -> nodes[y][x].open = map[y][x];
      if (map[y][x]) {
	graph -> nodes[y][x].dist = INT_MAX;
	graph -> nodes[y][x].t.weight = -1;
	graph -> nodes[y][x].pX = -1;
	graph -> nodes[y][x].pY = -1;
	graph -> nodes[y][x].x = x;
	graph -> nodes[y][x].y = y;
      }
    }
  }

  printMap(graphLim, map);
  printf("Feeding into djikstra's!\n");

  djikstra(graph, 0, 0);

  printf("I did it mom!");
  // freeStructs();
  return 0;
}

