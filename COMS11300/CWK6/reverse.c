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
    printf("%c", head->value);
    head = head->next;
  }

  printf("\n");
}

int main(void) {
  charList *head;
  char input;

  //input = getchar();
  scanf("%c", &input);

  while (input != '.') {
    head = listInsert(input, head);
    input = getchar();
  }

  head = listInsert(input, head);

  printList(head);

  return 0;
}
