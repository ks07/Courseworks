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

void printLeaf(tree *leaf) {
  stringList *number;
  printf("%s", leaf->name);
  for (number = leaf->numbers; number != NULL; number = number->next) {
    printf(" %s", number->string);
  }
  printf("\n");
}

void printTreeOrdered(tree *leaf) {
  /* We must explore left as far as possible. Print at end. Reverse back
     along stack until we can take a right. Print current, then go right.
     Repeat. */
  if (leaf != NULL) {
    printTreeOrdered(leaf->left);
    printLeaf(leaf);
    printTreeOrdered(leaf->right);
  }
}

/* Two options here: Traverse entire tree as before, printing when we are within the bounds,
   or traverse tree only until we meet the boundary. Try with the latter. */
void printTreeRange(char *lower, char *upper, tree *current) {
  int cmpLower, cmpUpper;

  if (current != NULL) {
    // cmpLower < 0 if current is left of (< than) lower.
    cmpLower = strcasecmp(current->name, lower);
    
    if ((strcasecmp(lower, upper) == 0) && (cmpLower == 0)) {
      // This node is both the upper and lower limit, so print and stop.
      printLeaf(current);
    } else {
      // cmpUpper > 0 if current is right of (> than) upper.
      cmpUpper = strcasecmp(current->name, upper);

      // First check if we need to move to get into bounds.
      if (cmpLower < 0) {
	// Need to go right.
	printTreeRange(lower, upper, current->right);
      } else if (cmpUpper > 0) {
	// Need to go left.
	printTreeRange(lower, upper, current->left);
      } else {
	// We must traverse left before printing this node.
	printTreeRange(lower, upper, current->left);
	printLeaf(current);
	// Traverse right.
	printTreeRange(lower, upper, current->right);
      }
    }
  }
}

// Reads in the next non-whitespace character.
char getNextChar() {
  char temp = getchar();

  while (temp == '\n' || temp == ' ' || temp == '\t') {
    temp = getchar();
  }

  return temp;
}

int main(void) {
  // Assume a maximum name of 100 characters, maximum number of 20.
  char *input1, *input2, choice;
  tree *root = NULL;

  input1 = malloc(101 * sizeof(char));
  input2 = malloc(21 * sizeof(char));

  do {
    scanf("%100s", input1);
    if (input1[0] != '.') {
      scanf("%20s", input2);
      root = insertLeaf(input1, input2, root);

      input1 = malloc(101 * sizeof(char));
      input2 = malloc(21 * sizeof(char));
    }
  } while (input1[0] != '.');

  printf("Do you want to print all entries [Y/n]? ");
  choice = getNextChar();

  while (choice != 'n' && choice != 'y' && choice != 'Y' && choice != 'N') {
    printf("Please enter either 'y' or 'n': '%c'", choice);
    choice = getNextChar();
  }

  if (choice == 'n' || choice == 'N') {
    input2 = malloc(101 * sizeof(char));
    printf("First entry? ");
    scanf("%100s", input1);
    printf("Last entry? ");
    scanf("%100s", input2);
    printTreeRange(input1, input2, root);
  } else {
    printTreeOrdered(root);
  }

  return 0;
}
