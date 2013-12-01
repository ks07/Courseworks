#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_LINE_LEN 100
#define MAX_GRAPH_DIM 20

typedef struct AdjacencyList {
  struct LinkedList *next;
  int toX;
  int toY;
  int weight;
} AdjacencyList;

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
    } else {
      // Unknown line!
      printf("Warning: ignored line %s\n", line);
    }
  }

  fclose(mapFile);

  printMap(graphLim, map);
  printf("Okay!");
  return 0;
}

