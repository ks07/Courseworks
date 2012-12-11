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


int main( void ) {
  listelem *lp = read_list();



  return 0;
}
