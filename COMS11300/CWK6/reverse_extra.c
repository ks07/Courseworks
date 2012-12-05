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

/* Insert an item into a list after the given pointer. If the pointer is null,
   create a new list. */
charList *listInsertAfter(char value, charList *before) {
  charList *new = calloc(1, sizeof(charList));
  new->value = value;

  if (before == NULL) {
    before = new;
  } else {
    if (before->next != NULL) {
      new->next = before->next;
    }

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
