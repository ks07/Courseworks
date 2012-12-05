#include <stdlib.h>
#include <stdio.h>

typedef struct _charList {
  struct _charList *next;
  char value;
} charList;

charList *listInsert(char value, charList *list) {
  charList *next;

  next = malloc(1 * sizeof(charList));
  next->value = value;
  next->next = list;

  return next;
}

void printList(charList *head) {
  while (head != NULL) {
    printf("%c", head->value);
    head = head->next;
  }

  printf("\n");
}

/* Insert an item into a list after the given pointer. If the pointer is
   null, create a new list. Returns a pointer to the added element. */
charList *listInsertAfter(char value, charList *before) {
  charList *new = malloc(1 * sizeof(charList));
  new->value = value;

  if (before != NULL) {
    new->next = before->next;
    before->next = new;
  }

  return new;
}

int main(void) {
  charList *head = NULL;
  charList *insertAfter;
  char input;
  char insertAtHead = 0;

  input = getchar();
  if (input != '.') {
    head = listInsert(input, head);
    insertAfter = head;
    input = getchar();

    while (input != '.') {
      if (input == '\n' || insertAtHead == 1) {
	head = listInsert(input, head);
	insertAfter = head;
	
	if (input == '\n') {
	  insertAtHead = 1;
	} else {
	  insertAtHead = 0;
	}
      } else {
	insertAfter = listInsertAfter(input, insertAfter);
      }

      input = getchar();
    }
  }

  printList(head);

  return 0;
}
