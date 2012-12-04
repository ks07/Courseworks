#include <stdlib.h>
#include <stdio.h>

typedef struct _charList {
  struct _charList *next;
  char value;
} charList;

charList *listInsert(char value, charList *list) {
  charList *next;

  next = calloc(1, sizeof(charList));
  next->value = value;

  if (list != NULL) {
    next->next = list;
  }

  return next;
}

void printList(charList *head) {
  while (head != NULL) {
    printf("%c", head->value);
    head = head->next;
  }

  printf("\n");
}

/* Inserts an element at the end of a given linked list. If the list
   provided is NULL, a new list is created. This function returns a
   pointer to the tail of the list, i.e. the inserted element. */
charList *listInsertTail(char value, charList *list) {
  charList *new = calloc(1, sizeof(charList));
  new->value = value;

  if (list == NULL) {
    list = new;
  } else {
    while (list->next != NULL) {
      list = list->next;
    }

    list->next = new;
    list = list->next;
  }

  return list;
}

int main(void) {
  charList *head = NULL;
  charList *tail;
  char input;

  input = getchar();
  if (input != '.') {
    head = listInsert(input, head);
    tail = head;
    input = getchar();

    while (input != '.') {
      tail = listInsertTail(input, tail);
      input = getchar();
    }
  }

  printList(head);

  return 0;
}
