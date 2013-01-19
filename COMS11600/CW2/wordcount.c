#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <time.h>

#define DEFAULT_FILENAME "a_portrait.txt"
#define HASHTABLE_BUCKETS 200

/* General word handling functions. */

// Checks whether a given character should be considered part of the given word,
// assuming the same for the last character of the word.
// Returns 0 (false) if the character should not be considered.
char isWordChar(char new, char *word, int currIndex) {
  if (isalnum(new)) {
    // All alphanumeric characters should be considered word characters.
    return true;
  } else if (currIndex > 0 && !isspace(new)) {
    // If the word is not empty, the new char is not whitespace, and the previous char is alphanumeric, true.
    return isalnum(word[currIndex - 1]);
  } else {
    return false;
  }
}

// Changes all uppercase characters in the given string into their lowercase counterparts.
// The change is performed in-place, thus a copy should be passed if the original must be preserved.
void strToLower(char *str) {
  int i = 0;

  while (str[i] != '\0') {
    str[i] = toLower(str[i]);
  }
}

/* Linked list functions and structs. */

typedef struct _stringOccList {
  struct _stringOccList *next;
  char *value;
  int occurrences;
  // Keep track of the length so that we do not need to iterate over the entire list to calculate the max overflow.
  unsigned int length; // TODO: Optimise, store only for the head.
} stringOccList;

typedef struct _comparisonReturn {
  struct _stringOccList *node;
  unsigned int comparisons;
} comparisonReturn;

// Inserts a new node as the head of a given linked list.
// Returns the new node / the head of the list.
stringOccList *listInsert(char *value, stringOccList *list) {
  stringOccList *next;

  next = malloc(sizeof(stringOccList));
  next->value = value;
  next->occurrences = 1;
  next->next = list;

  // Set the length of the list with the new element added.
  if (list != NULL) {
    next->length = list->length + 1;
  } else {
    next->length = 1;
  }

  return next;
}

// Checks if a linked list beginning with *list contains the given value.
// Returns the node containing the value if present, else NULL.
comparisonReturn *listSearch(char *value, stringOccList *list) {
  comparisonReturn *ret = calloc(1, sizeof(comparisonReturn));

  // Use strcasecmp, as the user probably doesn't care if the word starts a sentence or not.
  while (list != NULL && strcasecmp(value, list->value) != 0) {
    ret->comparisons++;
    list = list->next;
  }

  if (list != NULL) {
    // If the node was found, our comparison count will be one less than it's true value.
    ret->comparisons++;
  }

  ret->node = list;
  return ret;
}



/* Hashtable functions. */

typedef struct _stringOccTable {
  // Stores a pointer to an array of stringOccList pointers initialised to NULL. The array pointer is
  // not constant, and thus may be resized.
  struct _stringOccList **table;
  unsigned int emptyBucketCount;
  unsigned int bucketCount;
  unsigned int maxOverflowSize;
} stringOccTable;

// Calculate the hash of a given string key, assuring that the returned value is within the range of buckets.
// Returns the hash value of the given key.
unsigned int calcHash(char *key, unsigned int buckets) {
  char current = key[0];
  unsigned int hash = 0;
  int i;

  for (i = 1; current != '\0'; i++) {
    hash += current;
    current = key[i];
  }

  return hash % buckets;
}

// Creates a new hashtable struct.
// Returns a pointer to a stringOccTable struct that holds an array of lists to act as overflow, and some 
// variables to store metadata. Returns NULL if allocation failed. See struct declaration for more information.
stringOccTable *createHashtable(unsigned int buckets) {
  // Use calloc so that variables are initialised to NULL, and check the allocation succeeded.
  stringOccTable *table = calloc(1, sizeof(stringOccTable));
  if (table == NULL) {
    return NULL;
  }

  // Declare the internal array of lists, again checking for success.
  table->table = calloc(buckets, sizeof(stringOccList));
  if (table->table == NULL) {
    return NULL;
  }

  table->bucketCount = buckets;
  table->emptyBucketCount = buckets;

  return table;
}

// Inserts a value into the given hash table, incrementing it's counter if it already exists. hTable must be
// initialised with createHashTable before being used as a parameter to this function.
void tableInsert(char *value, stringOccTable *hTable) {
  unsigned int hash = calcHash(value, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];
  stringOccList *node; // TODO refactor insert/search to avoid this being necessary.

  if (bucket == NULL) {
    // The bucket is empty, thus we must decrease the count of empty buckets.
    hTable->emptyBucketCount--;
    bucket = listInsert(value, bucket);
    hTable->table[hash] = bucket;
  } else {
    // The bucket already contains values, so we must check the overflow list for the actual key.
    node = (listSearch(value, bucket))->node;

    if (node == NULL) {
      // Insert the new value into the relevant bucket, and update the point in the table.
      bucket = listInsert(value, bucket);
      hTable->table[hash] = bucket;
    } else {
      // The word is already in the list, so we should just increase it's counter in the list.
      node->occurrences++;
    }

    // The bucket already contains values, so we should increase the maxOverflowSize if necessary.
    if (hTable->maxOverflowSize < bucket->length) {
      hTable->maxOverflowSize = bucket->length;
    }
  }
}

// Searches the given hash table for the list node containing key.
// Returns the stringOccList node containg the given key, else NULL if the key is not present.
comparisonReturn *tableSearch(char *key, stringOccTable *hTable) {
  unsigned int hash = calcHash(key, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];

  if (bucket == NULL) {
    // The bucket is empty, thus the table does not contain an entry corresponding to the given key.
    comparisonReturn *empty = calloc(1, sizeof(comparisonReturn));
    return empty;
  } else {
    return listSearch(key, bucket);
  }
}



/* Main function and user interactions/control. */

// Creates and populates a hashtable using the contents of the file represented by filename.
// Returns a pointer to the newly created hashtable, or NULL if no words could be read, or the creation failed.
stringOccTable *populateTable(char *filename) {
  FILE *inputFile;
  stringOccTable *hTable = createHashtable(HASHTABLE_BUCKETS);

  inputFile = fopen(filename, "r");

  // Could not open the given file, perhaps it does not exist, or insufficient permissions.
  if (inputFile != NULL) {
    char word[100]; // TODO: Variable length
    unsigned char count = 0;
    char *newWord;
    int tmpChar;

    tmpChar = fgetc(inputFile);
    while (tmpChar != EOF) {
      word[count] = toLower((char)tmpChar);

      // Re-use the tmpChar variable to store the result of checking the next character.
      tmpChar = isWordChar(word[count], word, count);

      if (count == 99 || (count > 0 && !tmpChar)) {
        // Reached the end of a word and gathered at least a single character, so add this word after adding a trailing '\0'.

        // TODO: Optimise!
        if (count > 1 && !isalnum(word[count - 1])) {
          // If both the final and penultimate characters are not alphanumeric, strip both.
          word[count - 1] = '\0';
        } else {
          word[count] = '\0';
        }

	// Allocate a new array for the new word and insert it into the hashtable.
	newWord = malloc((count + 2) * sizeof(char)); // TODO remove need to copy string if already contained in table.
	strcpy(newWord, word);
	tableInsert(newWord, hTable);

        count = 0;
      } else if (tmpChar) {
        // Found a word character, increment counter.
        count++;
      }

      tmpChar = fgetc(inputFile);
    }

    // Close the file descriptor
    fclose(inputFile);
  } else {
    // Could not open the given file, perhaps it does not exist, or insufficient permissions.
    return NULL; // TODO: Error messages.
  }

  // Return the pointer to the head of the list, or null if an error occurred.
  return hTable;
}

// Creates and populates a linked list using the contents of the file represented by filename.
// Returns the head of the newly created linked list, or NULL if no words could be read.
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
      word[count] = toLower((char)tmpChar);
      
      // Re-use the tmpChar variable to store the result of checking the next character.
      tmpChar = isWordChar(word[count], word, count);

      if (count == 99 || (count > 0 && !tmpChar)) {
	// Reached the end of a word and gathered at least a single character, so add this word after adding a trailing '\0'.

	// TODO: Optimise!
	if (count > 1 && !isalnum(word[count - 1])) {
	  // If both the final and penultimate characters are not alphanumeric, strip both.
	  word[count - 1] = '\0';
	} else {
	  word[count] = '\0';
	}

	node = (listSearch(word, head))->node;

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
      } else if (tmpChar) {
	// Found a word character, increment counter.
	count++;
      }

      tmpChar = fgetc(inputFile);
    }

    // Close the file descriptor
    fclose(inputFile);
  } else {
    // Could not open the given file, perhaps it does not exist, or insufficient permissions.
    return NULL;
  }

  // Return the pointer to the head of the list, or null if an error occurred.
  return head;
}

void printList(stringOccList *head) {
  while (head != NULL) {
    printf("'%s' %d\n", head->value, head->occurrences);
    head = head->next;
  }
}

void printTable(stringOccTable *hTable) {
  int i;

  printf("Table {empty: %d, maxOver: %d}\n", hTable->emptyBucketCount, hTable->maxOverflowSize);

  for (i = 0; i < HASHTABLE_BUCKETS; i++) {
    printf("=Bucket %d:\n", i);

    printList(hTable->table[i]);
  }
}

// Converts a time created with clock() into a float representing the time in seconds.
// Returns a float value representing the time in seconds.
float clockToSeconds(clock_t clocks) {
  return ((float)clocks) / CLOCKS_PER_SEC;
}

int main(int argc, char *argv[]) {
  stringOccList *head;
  stringOccTable *table;
  clock_t listTimer;
  clock_t tableTimer;

  if (argc > 1) {
    listTimer = clock();
    head = populateList(argv[1]);
    listTimer = clock() - listTimer;
    tableTimer = clock();
    table = populateTable(argv[1]);
    tableTimer = clock() - tableTimer;
  } else {
    listTimer = clock();
    head = populateList("test.txt"); // TODO Use defined constant
    listTimer = clock() - listTimer;
    tableTimer = clock();
    table = populateTable("test.txt");
    tableTimer = clock() - tableTimer;
  }

  printf("Time for population with %d words:\n  List: %f seconds Table: %f seconds\n", head->length, clockToSeconds(listTimer), clockToSeconds(tableTimer));

  printf("Enter word for retrieval: ");
  char choice[100];
  scanf("%99s", choice);
  strToLower(choice);

  printf("List: ");
  comparisonReturn *search = listSearch(choice, head);
  if (search->node != NULL) {
    printf("Found '%s' %d times\n", search->node->value, search->node->occurrences);
  } else {
    printf("Not found\n");
  }
  printf("  with %d comparisons.\n", search->comparisons);

  printf("Table: ");
  search = tableSearch(choice, table);
  if (search->node != NULL) {
    printf("Found '%s' %d times\n", search->node->value, search->node->occurrences);
  } else {
    printf("Not found\n");
  }
  printf("  with %d comparisons.\n", search->comparisons);

  //printTable(table);

  return 0;
}
