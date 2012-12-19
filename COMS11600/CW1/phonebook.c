#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct _stringList {
  char *string;
  struct _stringList *next;
} stringList;

typedef struct _tree {
  char *name;
  stringList *numbers;
  struct _tree *left;
  struct _tree *right;
} tree;

void fixCapitalisation(char *string) {
  int i;

  if (string[0] >= 'a' && string[0] <= 'z') {
    string[0] += ('A' - 'a');
  }

  for (i = 1; string[i] != '\0'; i++) {
    if (string[i] >= 'A' && string[i] <= 'Z') {
      string[i] += ('a' - 'A');
    }
  }
}

void insertLeafRecursive(tree *new, tree *current) {
  int cmp = strcasecmp(current->name, new->name);

  if (cmp == 0) {
    // Name already exists in tree, so update number.
    if (strcmp(current->name, new->name) != 0) {
      fixCapitalisation(current->name);
    }

    new->numbers->next = current->numbers;
    current->numbers = new->numbers;
  } else if (cmp < 0) {
    if (current->right != NULL) {
      insertLeafRecursive(new, current->right);
    } else {
      current->right = new;
    }
  } else {
    if (current->left != NULL) {
      insertLeafRecursive(new, current->left);
    } else {
      current->left = new;
    }
  }
}

tree *insertLeaf(char *name, char *number, tree *root) {
  tree *new = calloc(1, sizeof(tree));
  new->name = name;

  stringList *strings = calloc(1, sizeof(stringList));
  strings->string = number;
  new->numbers = strings;

  //Base case if tree is empty
  if (root == NULL) {
    return new;
  } else {
    insertLeafRecursive(new, root);
  }

  return root;
}

// Debug function
void printTreeInteractive(tree *root) {
  char dir;
  tree *curr = root;
  
  while (curr != NULL) {
    printf("Node: %s", curr->name);
    if (curr->left != NULL) {
      printf(" L");
    }
    if (curr->right != NULL) {
      printf(" R");
    }
    printf("\n");
    if (curr->right != NULL || curr->left != NULL) {
      dir = getchar();
      while (dir != 'l' && dir != 'r') {
	dir = getchar();
      }
      if (dir == 'l') {
	curr = curr->left;
      } else {
	curr = curr->right;
      }
    } else {
      curr = NULL;
    }
  }
}

void printTreeOrdered(tree *root) {
  /* We must explore left as far as possible. Print at end. Reverse back
     along stack until we can take a right. Print current, then go right.
     Repeat. */
  stringList *number;

  if (root != NULL) {
    printTreeOrdered(root->left);
    printf("%s", root->name);

    number = root->numbers;
    while (number != NULL) {
      printf(" %s", number->string);
      number = number->next;
    }
    printf("\n");

    printTreeOrdered(root->right);
  }
}

int main(void) {
  // Assume a maximum name of 100 characters, maximum number of 20.
  char *name, *number;
  tree *root = NULL;

  name = malloc(101 * sizeof(char));
  number = malloc(21 * sizeof(char));

  do {
    scanf("%100s", name);
    if (name[0] != '.') {
      scanf("%20s", number);
      root = insertLeaf(name, number, root);

      name = malloc(101 * sizeof(char));
      number = malloc(21 * sizeof(char));
    }
  } while (name[0] != '.');

  printTreeOrdered(root);

  /*
  while (1) {
    printf("Printing From Root:\n");
    printTree(root);
  }
  */

  return 0;
}
