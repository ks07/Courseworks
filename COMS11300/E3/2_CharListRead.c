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

// Returns 1 if lists are the same, 0 otherwise.
int compare_lists(listelem *head1, listelem *head2) {
  int result = 1;

  while ((head1 != NULL) && (head2 != NULL) && (result == 1)) {
    if (head1->symbol != head2->symbol) {
      result = 0;
    } else if ( ((head1->next == NULL) && (head2->next != NULL)) || ((head1->next != NULL) && (head2->next == NULL)) ) {
      // If only a single next pointer is null, the lists are of different lengths and thus not equal.
      result = 0;
    } else {
      head1 = head1->next;
      head2 = head2->next;
    }
  }

  return result;
}

int main( void ) {
  listelem *lp = read_list();
  listelem *lr = read_list();

  if (compare_lists(lp, lr) == 1) {
    printf("EQUAL\n");
  } else {
    printf("DIFFERENT\n");
  }

  return 0;
}
