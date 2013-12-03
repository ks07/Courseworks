#include <stdlib.h>
#include <stdio.h>

// A binary min-heap implementation of a priority queue, backed by an array.
// We will treat the heap as starting from index 1, to simplify the maths!
// heap[0] will thus be spare, we can use it's 'pos' to store heapSize.

typedef struct QueueEle {
  void *data; // Pointer to 'user' data. Must be cast before use.
  int pos; // Position in the heap (or size for element 0).
  int key; // The key, aka the priority.
} QueueEle;

int parent(QueueEle *node) {
  // Right shift will truncate any bits lost off the end, performing the floor op.
  return (node->pos) >> 1;
}

int left(QueueEle *node) {
  return (node->pos) << 1;
}

int right(QueueEle *node) {
  return ((node->pos) << 1) + 1;
}

int heapSize(QueueEle heap[]) {
  return heap[0].pos;
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
  //  QueueEle tmp;
  QueueEle *parent = &(heap[i]);

  if (left(parent) <= heapSize(heap) && heap[left(parent)].key < heap[i].key) {
    smallest = left(parent);
  } else {
    smallest = i;
  }
  if (right(parent) <= heapSize(heap) && heap[right(parent)].key < heap[i].key) {
    smallest = right(parent);
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

void printHeap(QueueEle arr[], int lim) {
  int i;
  printf("| ");
  for (i=0; i<lim; i++) {
    printf("%d | ", arr[i].key);
  }
  printf("\n");
}

// Test main
#ifndef NO_MAIN
int main() {
//int arr[] = {0, 1, 16, 10, 8, 2, 9, 14, 7, 3};
//int arr[] = {0, 16, 14, 10, 8, 7, 9, 3, 2, 1};
//int arr[] = {0, 1, 2, 3, 7, 8, 9, 10, 14, 16};
//printIntArray(arr, 10);
//buildHeap(arr, 9);
//printIntArray(arr, 10);
  QueueEle *arr = malloc(20 * sizeof(QueueEle));
  int i;
  for (i=0;i<20;i++) {
    arr[i].key = (27 - i) % 7;
    arr[i].pos = i;
    arr[i].data = &(arr[i]);
  }
  printHeap(arr, 20);
  buildHeap(arr, 19);
  printHeap(arr, 20);
  return 0;
}
#endif
