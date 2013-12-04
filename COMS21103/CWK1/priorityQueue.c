#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

// A binary min-heap implementation of a priority queue, backed by an array.
// We will treat the heap as starting from index 1, to simplify the maths!
// heap[0] will thus be spare, we can use it's 'pos' to store heapSize.

//TODO: Use a union for element 0
typedef struct QueueEle {
  void *data; // Pointer to 'user' data. Must be cast before use.
  int pos; // Position in the heap (or size for element 0).
  int key; // The key, aka the priority.
} QueueEle;

inline int parent(int pos) {
  // Right shift will truncate any bits lost off the end, performing the floor op.
  return pos >> 1;
}

inline int left(int pos) {
  return pos << 1;
}

inline int right(int pos) {
  return (pos << 1) + 1;
}

inline int heapSize(QueueEle heap[]) {
  return heap[0].pos;
}

inline void heapSizeSet(QueueEle heap[], int size) {
  heap[0].pos = size;
}

inline bool notEmpty(QueueEle heap[]) {
  return heapSize(heap) > 0;
}

void swapEle(QueueEle heap[], int a, int b) {
  QueueEle tmp = heap[a];
  heap[a] = heap[b];
  heap[b] = tmp;
  // Update the position in each element.
  heap[a].pos = a;
  heap[b].pos = b;
}

void heapify(QueueEle heap[], int i) {
  int smallest;

  if (left(i) <= heapSize(heap) && heap[left(i)].key < heap[i].key) {
    smallest = left(i);
  } else {
    smallest = i;
  }
  if (right(i) <= heapSize(heap) && heap[right(i)].key < heap[i].key) {
    smallest = right(i);
  }
  if (smallest != i) {
    // A child is smaller, swap the elements.
    swapEle(heap, i, smallest);
    heapify(heap, smallest);
  }
}

// Changes elements in arr to make it a binary min-heap. Elements should start at index 1.
void buildHeap(QueueEle arr[], int len) {
  int i = len >> 1;
  // Put the heapsize into the first element.
  arr[0].key = -1;
  arr[0].pos = len;
  arr[0].data = NULL;

  for (; i >= 1; i--) {
    heapify(arr, i);
  }
}

// Debugging print of heap keys
void printHeap(QueueEle arr[], int lim) {
  int i;
  printf("| ");
  for (i=0; i<lim; i++) {
    printf("%d | ", arr[i].key);
  }
  printf("\n");
}

void decreaseKey(QueueEle heap[], int node, int k) {
  if (k > heap[node].key) {
    printf("ERROR: decreaseKey called with larger key value!");
  } else {
    heap[node].key = k;
    while (node > 1 && heap[parent(node)].key > heap[node].key) {
      swapEle(heap, node, parent(node));
      node = parent(node);
    }
  }
}

void insert(QueueEle heap[], QueueEle new) {
  // TODO: RESIZE ARRAY
  heap[0].pos++;
  new.pos = heapSize(heap);
  heap[heapSize(heap)] = new;
  decreaseKey(heap, heapSize(heap), new.key);
}

QueueEle extractMin(QueueEle heap[]) {
  QueueEle min;

  if (heapSize(heap) < 1) {
    printf("ERROR: We outta elements, foo!");
    return min;
  } else {
    min = heap[1];
    heap[1] = heap[heapSize(heap)];
    heapSizeSet(heap, heapSize(heap) - 1);
    heapify(heap, 1);
    return min;
  }
}

// Test main, #define NO_MAIN in other files to avoid conflict!
#ifndef NO_MAIN
int main() {
  QueueEle *arr = malloc(21 * sizeof(QueueEle));
  int i;
  for (i=0;i<20;i++) {
    arr[i].key = (27 - i) % 7;
    arr[i].pos = i;
    arr[i].data = &(arr[i]);
  }
  printHeap(arr, 21);
  buildHeap(arr, 19);
  printHeap(arr, 21);
  QueueEle new = { NULL, -1, 4 };
  insert(arr, new);
  printHeap(arr, 21);
  return 0;
}
#endif
