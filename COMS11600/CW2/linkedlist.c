#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_FILENAME "a_portrait.txt"

typedef struct _stringOccList {
  struct _stringOccList *next;
  char *value;
  int occurrences;
} stringOccList;

// Inserts a new node as the head of a given linked list.
// Returns the new node / the head of the list.
stringOccList *listInsert(char *value, stringOccList *list) {
  stringOccList *next;

  next = malloc(sizeof(stringOccList));
  next->value = value;
  next->occurrences = 1;
  next->next = list;

  return next;
}

// Checks if a linked list beginning with *list contains the given value.
// Returns the node containing the value if present, else NULL.
stringOccList *listSearch(char *value, stringOccList *list) {
  // Use strcasecmp, as the user probably doesn't care if the word starts a sentence or not.
  while (list != NULL && strcasecmp(value, list->value) != 0) {
    list = list->next;
  }

  return list;
}

// Checks whether a given character counts as whitespace or not.
// Returns 1 if whitespace, else 0.
char isWhitespace(char ch) {
  switch (ch) {
  case ' ':
  case '\t':
  case '\n':
  case '\r':
    return 1;
  default:
    return 0;
  }
}

// Creates and populates a linked list using the contents of the file represented by filename.
// Returns the head of the newly created linked list, or NULL if no words oculd be read.
stringOccList *populateList(char *filename) {
  FILE *inputFile;
  stringOccList *head = NULL;
  stringOccList *node;

  inputFile = fopen(filename, "r");

  // Could not open the given file, perhaps it does not exist, or insufficient permissions.
  if (inputFile != NULL) {
    char word[100]; // TODO: Variable length
    unsigned char count = 0;
    char *newWord;
    int tmpChar;

    tmpChar = fgetc(inputFile);
    while (tmpChar != EOF) {
      word[count] = (char)tmpChar;

      if ((isWhitespace(word[count]) && count > 0) || count == 99 ) {
	// Reached the end of a word and gathered at least a single character, so add this word after adding a trailing '\0'.
	word[count] = '\0';

	node = listSearch(word, head);

	if (node == NULL) {
	  // Allocate a new array for the new word and insert it into the list.
	  newWord = malloc((count + 2) * sizeof(char));
	  strcpy(newWord, word);
	  head = listInsert(newWord, head);
	} else {
	  // The word is already in the list, so we should just increase it's counter in the list.
	  node->occurrences++;
	}

	count = 0;
      } else {
	// Found a word character, increment counter.
	count++;
      }

      tmpChar = fgetc(inputFile);
    }

    // Close the file descriptor
    fclose(inputFile);
  }

  // Return the pointer to the head of the list, or null if an error occurred.
  return head;
}

void printList(stringOccList *head) {
  while (head != NULL) {
    printf("%s %d\n", head->value, head->occurrences);
    head = head->next;
  }
}

int main(int argc, char *argv[]) {
  printf("c: %d v0: %s v1: %s\n", argc, argv[0], argv[1]);
  if (argc > 1) {
    printList(populateList(argv[1]));
  } else {
    printList(populateList("test.txt"));
  }

  return 0;
}
