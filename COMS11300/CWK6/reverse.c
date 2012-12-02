#include <stdlib.h>
#include <stdio.h>

typedef struct _charList {
  struct _charList *next;
  char value;
} charList;

charList *listInsert(char value, charList *list) {
  charList *next;

  next = malloc(sizeof(charList));
  next->value = value;

  if (list == NULL) {
    list = next;
  } else {
    next->next = list;
  }

  return next;
}

void printList(charList *head) {
  while (head != NULL) {
    printf("%c\n", head->value);
    head = head->next;
  }
}

int main(void) {
  charList *head;

  head = listInsert('a', head);
  printList(head);

  printf("\n");

  head = listInsert('b', head);
  head = listInsert('c', head);
  printList(head);

  return 0;
}
