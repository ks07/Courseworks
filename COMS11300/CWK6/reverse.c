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

int main(void) {
  charList *head = NULL;
  char input;

  do {
    input = getchar();
    head = listInsert(input, head);
  } while (input != '.');

  printList(head);

  return 0;
}
