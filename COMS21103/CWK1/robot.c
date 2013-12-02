#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_LINE_LEN 100
#define MAX_GRAPH_DIM 20

#define N 0
#define S 1
#define E 2
#define W 3

typedef struct Vertex {
  bool open;
  struct Vertex *edge[5];
  int dist;
} Vertex;

typedef struct Graph {
  Vertex **nodes;
  int maxDim;
} Graph;

Vertex **callocSquare(int size) {
  // Allocate the rows (y)
  Vertex **square = calloc(size, sizeof(Vertex *));
  int i;
  for (i = 0; i < size; i++) {
    // Add an array for each row, creating the columns (x).
    square[i] = calloc(size, sizeof(Vertex));
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
  graph -> nodes = callocSquare(graphLim);
  for (y = 0; y < graphLim; y++) {
    for (x = 0; x < graphLim; x++) {
      if (map[y][x]) {
	if (y < graphLim - 1 && map[y+1][x]) {
	  // The node below us is not out of bounds and is free. Add it to our edges.
	  graph -> nodes[y][x].edge[S] = &(graph -> nodes[y+1][x]);
	  // We should also update the node below with a link back to us.
	  graph -> nodes[y+1][x].edge[N] = &(graph -> nodes[y][x]);
	}
	if (x < graphLim - 1 && map[y][x+1]) {
	  // The node east of us is not out of bounds and is free. Add it to our edges.
	  graph -> nodes[y][x].edge[E] = &(graph -> nodes[y][x+1]);
	  // We should also update the connected node with a link back to us.
	  graph -> nodes[y][x+1].edge[W] = &(graph -> nodes[y][x]);
	}
      }
    }
  }

  printMap(graphLim, map);
  printf("Okay!");
  return 0;
}

