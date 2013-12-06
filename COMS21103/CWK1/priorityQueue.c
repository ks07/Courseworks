#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

// A binary min-heap implementation of a priority queue, backed by an array.
// We will treat the heap as starting from index 1, to simplify the maths!
// heap[0] will thus be spare, we can use it's 'pos' to store heapSize.
/*
typedef struct QueueEle {
  Vertex *data; // Pointer to vertex data.
  int pos; // Position in the heap (or size for element 0). //TODO: Am I needed?
  int key; // The key, aka the priority.
} QueueEle;
*/

inline int parent(int pos) {
  // Right shift will truncate any bits lost off the end, performing the floor op.
  return pos >> 1;
}

/*
inline int left(int pos) {
  return pos << 1;
}
*/
#define left(pos) (pos << 1)

inline int right(int pos) {
  return (pos << 1) + 1;
}

inline int heapSize(Vertex *heap[]) {
  return heap[0]->key;
}

inline void heapSizeSet(Vertex *heap[], int size) {
  heap[0]->key = size;
}

inline bool notEmpty(Vertex *heap[]) {
  return heapSize(heap) > 0;
}

// Debugging print of heap keys
void printHeap(Vertex *arr[], int lim) {
  int i;
  printf("| ");
  for (i=0; i<lim; i++) {
    printf("%d | ", arr[i]->key);
  }
  printf("\n");
}

void swapEle(Vertex *heap[], int a, int b) {
  Vertex *tmp = heap[a];
  heap[a] = heap[b];
  heap[b] = tmp;
  // Update the position in each element.
  heap[a]->qPos = a;
  heap[b]->qPos = b;
}

void heapify(Vertex *heap[], int i) {
  int smallest;

  if (left(i) <= heapSize(heap) && heap[left(i)]->key < heap[i]->key) {
    smallest = left(i);
  } else {
    smallest = i;
  }
  if (right(i) <= heapSize(heap) && heap[right(i)]->key < heap[smallest]->key) {
    smallest = right(i);
  }
  if (smallest != i) {
    // A child is smaller, swap the elements.
    swapEle(heap, i, smallest);
    heapify(heap, smallest);
  }
}

// Changes elements in arr to make it a binary min-heap. Elements should start at index 1.
void buildHeap(Vertex *arr[], int len) {
  int i = len >> 1;
  // Put the heapsize into the first element.
  arr[0]->key = len;
  arr[0]->qPos = 0;

  for (; i >= 1; i--) {
    heapify(arr, i);
#ifdef DBGQ
    printHeap(arr, len + 1);
#endif
  }
}

void decreaseKey(Vertex *heap[], int node, int k) {
  if (k > heap[node]->key) {
    printf("ERROR: decreaseKey called with larger key value!\n");
  } else {
    heap[node]->key = k;
    while (node > 1 && heap[parent(node)]->key > heap[node]->key) {
      swapEle(heap, node, parent(node));
      node = parent(node);
    }
  }
}

void insert(Vertex *heap[], Vertex *data, int key) {
  // TODO: RESIZE ARRAY
  heapSizeSet(heap, heapSize(heap)+1);
  int heapsize = heapSize(heap);
  heap[heapsize] = data;
  heap[heapsize]->qPos = heapsize;
  heap[heapsize]->key = key;
  decreaseKey(heap, heapsize, key);
}

Vertex *extractMin(Vertex *heap[]) {
  Vertex *min;

  if (heapSize(heap) < 1) {
    printf("ERROR: Heap underflow.\n");
    return NULL;
  } else {
    min = heap[1];
    min->qPos = -1; //Removing from queue, invalidate this value.
    heap[1] = heap[heapSize(heap)];
    heapSizeSet(heap, heapSize(heap) - 1);
    heapify(heap, 1);
    return min;
  }
}

// Test main
#ifdef DBGQ
int main() {
  int len = 5;
  Vertex **arr = malloc(len * sizeof(Vertex *));

  Vertex *nodes = malloc(len * sizeof(Vertex));
  int i;
  for (i=0;i<len;i++) {
    arr[i] = &(nodes[i]);
    arr[i]->key = (27 - i) % 7;
    arr[i]->qPos = i;
  }
  printHeap(arr, len);
  buildHeap(arr, len - 1);
  printHeap(arr, len);
  return 0;
}
#endif
