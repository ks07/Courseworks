#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct _tree {
  char *name;
  char *number;
  struct _tree *left;
  struct _tree *right;
} tree;


void insertLeafRecursive(tree *new, tree *current) {
  int cmp = strcmp(current->name, new->name);

  if (cmp == 0) {
    // Name already exists in tree, so update number.
    current->number = new->number;
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
  new->number = number;

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
    printf("Node: %s, %s", curr->name, curr->number);
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

  if (root != NULL) {
    printTreeOrdered(root->left);
    printf("%s %s\n", root->name, root->number);
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
    scanf("%100s %19s", name, number);
    if (name[0] != '.') {
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
