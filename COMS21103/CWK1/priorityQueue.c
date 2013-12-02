#include <stdlib.h>
#include <stdio.h>

// A binary min-heap implementation of a priority queue, backed by an array.
// We will treat the heap as starting from index 1, to simplify the maths!
// heap[0] will thus be spare => heap size

int parent(int node) {
  // Right shift will truncate any bits lost off the end, performing the floor op.
  return node >> 1;
}

int left(int node) {
  return node << 1;
}

int right(int node) {
  return (node << 1) + 1;
}

int heapSize(int heap[]) {
  return heap[0];
}

void heapify(int heap[], int i) {
  int smallest;
  int tmp;

  if (left(i) <= heapSize(heap) && heap[left(i)] < heap[i]) {
    smallest = left(i);
  } else {
    smallest = i;
  }
  if (right(i) <= heapSize(heap) && heap[right(i)] < heap[i]) {
    smallest = right(i);
  }
  if (smallest != i) {
    tmp = heap[i];
    heap[i] = heap[smallest];
    heap[smallest] = tmp;
    heapify(heap, smallest);
  }
}

// Changes elements in arr to make it a binary min-heap. Elements should start at index 1.
void BuildHeap(int arr[], int len) {
  int i = len >> 1;
  // Put the heapsize into the first element.
  arr[0] = len;

  for (; i > 1; i--) {
    heapify(arr, i);
  }

}

void printIntArray(int arr[], int lim) {
  int i;
  printf("| ");
  for (i=0; i<lim; i++) {
    printf("%d | ", arr[i]);
  }
  printf("\n");
}

int main() {
int arr[] = {0, 1, 16, 10, 8, 2, 9, 14, 7, 3};
//int arr[] = {0, 16, 14, 10, 8, 7, 9, 3, 2, 1};
//int arr[] = {0, 1, 2, 3, 7, 8, 9, 10, 14, 16};
  printIntArray(arr, 10);
  BuildHeap(arr, 9);
  printIntArray(arr, 10);
  return 0;
}
