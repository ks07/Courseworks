/* George Field, gf12815, version C */

#include <stdio.h>
#include <stdlib.h>

typedef struct L {
  char     symbol;
  struct L *next;
} listelem;


listelem *insert_list(char c, listelem *p) {
  listelem *temp = calloc(1,sizeof(listelem));

  temp->symbol = c;
  temp->next = p;
  return temp;
}


listelem *read_list( void ) {
  char c;
  listelem *lp = NULL;

  c = getchar();   
  while (c != '.') {
    lp = insert_list(c,lp);
    c = getchar(); 
  }
  return lp;
}

listelem *duplicate_char(char c, listelem *head) {
  listelem *current, *previous;
  int loop;

  // Base case if given an empty list.
  if (head != NULL) {
    if (head->symbol == c) {
      // Base case if the first element contains 'c'.
      head = insert_list(c, head);
    } else {
      previous = head;
      current = head->next;
      loop = 1;
      
      while ((loop == 1) && (current != NULL)) {
	if (current->symbol == c) {
	  current = insert_list(c, current);
	  previous->next = current;
	  loop = 0;
	} else {
	  previous = current;
	  current = previous->next;
	}
      }
    }
  }

  return head;
}

void print_list(listelem *head) {
  while (head != NULL) {
    printf("%c", head->symbol);
    head = head->next;
  }

  printf("\n");
}

int main( void ) {
  listelem *lp = read_list();
  lp = duplicate_char('R', lp);
  print_list(lp);


  return 0;
}
