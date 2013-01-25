#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <time.h>

// Define some constants with the preprocessor. These act like simple substitutions, and are seen as literals when compiling.
#define DEFAULT_FILENAME "a_portrait.txt"
#define HASHTABLE_BUCKETS 1000
#define RESIZE_FACTOR 1.33f

/* General word handling functions. */

// Changes all uppercase characters in the given string into their lowercase counterparts.
// The change is performed in-place, thus a copy should be passed if the original must be preserved.
void strToLower(char *str) {
  int i;

  for (i = 0; str[i] != '\0'; i++) {
    str[i] = tolower(str[i]);
  }
}

// Define an enumerated type to signify the outcome of isWordChar. Match positive and negative outcomes to true and false values.
typedef enum {
  NO = 0, // False, stop reading.
  YES = 1, // True, continue.
  FINAL = 2 // True, but do not consume another character.
} WordCharResult;

// Checks whether a given character should be considered part of the given word,
// looking at the previous and next character, if they exist.
// Returns 0 (false) if the character should not be considered.
WordCharResult isWordChar(char new, char prev, int next) {
  if (isalnum(new)) {
    // All alphanumeric characters should be considered word characters.
    if (isspace(next)) {
      return FINAL;
    } else {
      return YES;
    }
  } else if (isalnum(prev) && (new == '-' || new == '\'')) {
    // If the word is not empty, the new char is either - or ', and the next and previous chars are alphanumeric.

    // If next is the null char, presume this char is valid, else return true if the next char is alphanumeric.
    if (next == '\0' || (next != EOF && isalnum(next))) {
      return YES;
    } else {
      return NO;
    }
  } else {
    return NO;
  }
}

// Reads in the next alphanumeric character from stdin - i.e. the first letter of the word.
// Returns the next character, or a space (' ') if EOF was reached.
char loopGetChar(FILE *src) {
  int c;

  do {
    c = fgetc(src);

    if (c == EOF) {
      return ' ';
    }
  } while (!isalnum(c));

  return (char)c;
}

// Reads the next word from the given input stream. A word is any string of characters bounded by whitespace or a non-alphanumeric
// character. A word may contain single - or ' characters.

char *readWord(FILE *src, unsigned int size) {
  if (size < 2) {
    // The minimum size of the string must be 2.
    size = 2;
  }

  unsigned int i = 1;
  int tmpChar, readAhead;
  char *input = calloc(size, sizeof(char));
  char *tmpPtr;
  WordCharResult wordChar;

  // Use loopGetchar to consume all whitespace, and give us the first character.
  input[0] = tolower(loopGetChar(src));

  if (input[0] == ' ') {
    // We reached EOF, so return NULL.
    return NULL;
  } else {
    // Store the output of fgetc into an int, so we can represent EOF.
    tmpChar = fgetc(src);
    wordChar = isWordChar(input[0], '\0', tmpChar);

    if (wordChar == YES) {
      readAhead = fgetc(src);

      wordChar = isWordChar(tmpChar, input[0], readAhead);

      while (wordChar != NO) {
	input[i] = tolower((char)tmpChar);

	// Check the array size then increment the counter.
	if (i++ > size) {
	  // The next character, whether it is \0 or otherwise, will be out of bounds, so expand.
	  size = size * 2;

	  tmpPtr = realloc(input, size);

	  if (tmpPtr == NULL) {
	    // Could not expand the array, so return the word so far and treat the remainder as a new word.
	    fprintf(stderr, "Reached max word length, splitting word after '%s'.", input);

	    // Attempt to increase by two characters so we don't lose the one we have kept in readAhead.
	    size = (size / 2) + 2;
	    tmpPtr = realloc(input, size);

	    if (tmpPtr == NULL) {
	      fprintf(stderr, "Reached max word length, splitting word after '%s'.", input);
	      return NULL;
	    } else {
	      input = tmpPtr;

	      input[i] = readAhead;
	      input[i + 1] = '\0';

	      fprintf(stderr, "Reached max word length, splitting word after '%s'.", input);

	      return input;
	    }
	  } else {
	    input = tmpPtr;
	  }
	}

	if (wordChar == YES) {
	  tmpChar = readAhead;
	  readAhead = fgetc(src);

	  wordChar = isWordChar(tmpChar, input[i - 1], readAhead);
	} else if (wordChar == FINAL) {
	  wordChar = NO;
	}
      }
    }

    input[i] = '\0';
  }

  return input;
}



/* Linked list functions and structs. */

typedef struct _stringOccList {
  struct _stringOccList *next;
  char *value;
  int occurrences;
  // Keep track of the length so that we do not need to iterate over the entire list to calculate the max overflow.
  unsigned int length;
} stringOccList;

typedef struct _comparisonReturn {
  struct _stringOccList *node;
  unsigned int comparisons;
} comparisonReturn;

// Checks if a linked list beginning with *list contains the given value.
// Returns the node containing the value if present, else NULL.
comparisonReturn *listSearch(char *value, stringOccList *list) {
  comparisonReturn *ret = calloc(1, sizeof(comparisonReturn));

  // Loop through the list, stopping if we encounter the desired value or reach the end of the list.
  while (list != NULL && strcmp(value, list->value) != 0) {
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

// Inserts a pre-existing node as the head of a given linked list.
// Returns the supplied node as the head of the list.
stringOccList *listInsertNode(stringOccList *node, stringOccList *list) {
  // Set the node as the head of it's new list.
  node->next = list;

  // If the list is empty, set length to 1, else set the length to reflect the new list.
  node->length = list == NULL ? 1 : list->length + 1;

  // Return the node as head of the list.
  return node;
}

// Inserts a new node as the head of a given linked list.
// Returns the new node / the head of the list.
stringOccList *listInsert(char *value, stringOccList *list) {
  stringOccList *next;

  // We must first search the list to check whether we should increment an existing node or add a new one.
  next = (listSearch(value, list))->node;

  if (next == NULL) {
    // Allocate a new array for the new word and insert it into the list.
    char *newWord = malloc((strlen(value) + 1) * sizeof(char));
    strcpy(newWord, value);

    // Allocate a new node to insert at the head of the list.
    next = malloc(sizeof(stringOccList));
    next->value = newWord;
    next->occurrences = 1;

    // Insert the node into the list and return it as the head of the list..
    return listInsertNode(next, list);
  } else {
    // The word is already in the list, so we should just increase it's counter in the list.
    next->occurrences++;

    // Return the head of the list.
    return list;
  }
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

/*
// Calculates the hash of a give string key.
// Returns the hash value of the given key.
unsigned int calculateHash(char *key) {
  char current = key[0];
  unsigned int i, hash = 0;

  for (i = 1; current != '\0'; i++) {
    hash += current;
    current = key[i];
  }

  return hash;
}
*/
/*
unsigned int calculateHash(char key[]) {
  unsigned int i, j, shift, hash = 0, mod, count;

  // Calculate the size of an int in terms of the size of a char.
  const unsigned int intSize = sizeof(int) / sizeof(char);

  // Calculate the number of chars in the string that do not form a complete int.
  mod = strlen(key) % intSize;

  // Calculate the limit of our loop.
  count = (strlen(key) - mod) / intSize;

  // Loop through until we've constructed all possible ints.
  for (i = 0; i < count; i += 4) {
    hash += key[i] + (key[i + 1] << 8) + (key[i + 2] << 16) + (key[i + 3] << 24);
  }

  // If we have outstanding chars, add them.
  for (j = 0; j < mod; j++) {
    i += j;
    shift = j * 8;
    hash += key[i] << shift;
  }

  return hash;
}*/
/*
// Modified Bernstein hash.
unsigned int calculateHash(char key[]) {
  unsigned int i, hash = 0;

  for (i = 0; key[i] != '\0'; i++) {
    hash = 33 * hash ^ key[i]; // ^ = XOR
  }

  return hash;
  }*/

// One-at-a-Time hash
unsigned int calculateHash(char key[]) {
  unsigned int i, hash = 0;

  for (i = 0; key[i] != '\0'; i++) {
    hash += key[i];
    hash += (hash << 10);
    hash ^= (hash >> 6);
  }

  hash += (hash << 3);
  hash ^= (hash >> 11);
  hash += (hash << 15);

  return hash;
}

// Calculate the hash of a given string key, assuring that the returned value is within the range of buckets.
// Returns the hash value of the given key.
unsigned int calcHash(char *key, unsigned int buckets) {
  // Use the calculateHash function to produce the raw hash.
  unsigned int hash = calculateHash(key);

  // Mod the result of the hash calculation so we don't go out of bounds.
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

// Searches the given hash table for the list node containing key.
// Returns the stringOccList node containg the given key and a count of comparisons required, else NULL if the key is not present.
comparisonReturn *tableSearch(char *key, stringOccTable *hTable) {
  unsigned int hash = calcHash(key, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];

  if (bucket == NULL) {
    // The bucket is empty, thus the table does not contain an entry corresponding to the given key.
    return calloc(1, sizeof(comparisonReturn));
  } else {
    return listSearch(key, bucket);
  }
}

// Inserts a value into the given hash table, incrementing it's counter if it already exists. hTable must be
// initialised with createHashTable before being used as a parameter to this function.
void tableInsert(char *value, stringOccTable *hTable) {
  unsigned int hash = calcHash(value, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];

  if (bucket == NULL) {
    // The bucket is empty, thus we must decrease the count of empty buckets.
    hTable->emptyBucketCount--;
  } else {
    // The bucket already contains values, so we should increase the maxOverflowSize if necessary.
    if (hTable->maxOverflowSize < bucket->length) {
      hTable->maxOverflowSize = bucket->length;
    }
  }

  // Insert into the relevant bucket, and update the pointer in the table.
  bucket = listInsert(value, bucket);
  hTable->table[hash] = bucket;
}

// Calculates the load factor of the given hashtable.
// Returns the load factor as a float.
float getLoadFactor(stringOccTable *hTable) {
  unsigned int i, total = 0;

  // Calculate the total number of elements in the table.
  for (i = 0; i < hTable->bucketCount; i++) {
    if (hTable->table[i] != NULL) {
      total += hTable->table[i]->length;
    }
  }

  // Load factor = Number of keys / Number of buckets
  return (float)total / (float)hTable->bucketCount;
}

// Increases the number of buckets in the given table, and rehashes and rearranges the keys inside.
// Returns a new hashtable containg the contents of the original.
stringOccTable *resizeRehashTable(stringOccTable *orig) {
  // Create a new hashTable with the increased bucket count.
  unsigned int newBuckets = (unsigned int)(orig->bucketCount * RESIZE_FACTOR);
  stringOccTable *new = createHashtable(newBuckets);

  // Declare some variables to use when looping.
  unsigned int i, newHash;
  stringOccList *node, *next;

  // Loop through the buckets in the original table.
  for (i = 0; i < orig->bucketCount; ++i) {
    node = orig->table[i];

    // Loop through the nodes within the current bucket.
    while (node != NULL) {
      // Calculate the new hash of the key.
      newHash = calcHash(node->value, newBuckets);

      // Store the pointer to the next node so we don't lose it.
      next = node->next;

      // Add the node to it's new bucket.
      listInsertNode(node, new->table[newHash]);

      // If the bucket was empty, the length will be 1, thus we should adjust the counter.
      if (node->length == 1) {
	new->emptyBucketCount--;
      }

      // Set the new maxOverflowSize if necessary.
      if (new->maxOverflowSize < node->length) {
	new->maxOverflowSize = node->length;
      }

      // Add the node as the head of it's new bucket.
      new->table[newHash] = node;

      // Advance through the list.
      node = next;
    }
  }

  // Free the memory used by the original table struct and it's internal array to prevent leaking memory.
  free(orig->table);
  free(orig);

  // Return the newly resized table struct.
  return new;
}



/* Main function and user interactions/control. */

// A struct that can hold some kind of data structure than counts occurences of strings.
typedef struct {
  bool isTable;

  // Wrap a union in struct, so we can store a tag that identifies the internal type.
  union {
    stringOccList *list;
    stringOccTable *table;
  } store;
} stringOcc;

// Populates a given stringOcc struct with all the words found in the file represented by filename.
// Returns the supplied struct with the new contents added, or NULL if no words could be read.
stringOcc *populateStruct(char *filename, stringOcc *fill) {
  FILE *inputFile;

  inputFile = fopen(filename, "r");

  // Could not open the given file, perhaps it does not exist, or insufficient permissions.
  if (inputFile != NULL) {
    char *word;

    word = readWord(inputFile, 2);

    while (word != NULL) {
      // Ascertain the type of the data structure, and add to it accordingly.
      if (fill->isTable) {
	tableInsert(word, fill->store.table);
      } else {
	fill->store.list = listInsert(word, fill->store.list);
      }

      word = readWord(inputFile, 2);
    }

    // Close the file descriptor
    fclose(inputFile);
  } else {
    // Could not open the given file, perhaps it does not exist, or insufficient permissions.
    fprintf(stderr, "Could not open the file '%s'.\n", filename);

    return NULL;
  }

  // Return the pointer to the head of the list, or null if an error occurred.
  return fill;
}

// Prints the entire contents of a supplied string counting list.
void printList(stringOccList *head) {
  while (head != NULL) {
    printf("'%s' %d\n", head->value, head->occurrences);
    head = head->next;
  }
}

// Prints some metadata about the state of a given string counting hashtable.
void printTableMetadata(stringOccTable *hTable) {
  printf("Table {loadFactor: %.2f, buckets: %d, empty: %d, maxOver: %d}\n", getLoadFactor(hTable), hTable->bucketCount, hTable->emptyBucketCount, hTable->maxOverflowSize);
}

// Prints the entire contents of a give string counting hashtable, including metadata.
void printTable(stringOccTable *hTable) {
  int i;

  printTableMetadata(hTable);

  for (i = 0; i < HASHTABLE_BUCKETS; i++) {
    printf("=Bucket %d (%d):\n", i, hTable->table[i] == NULL ? 0 : hTable->table[i]->length);

    printList(hTable->table[i]);
  }
}

// Converts a time created with clock() into a float representing the time in seconds.
// Returns a float value representing the time in seconds.
float clockToSeconds(clock_t clocks) {
  return ((float)clocks) / CLOCKS_PER_SEC;
}

// Prints the result of a lookup operation to stdout from a given comparisonReturn struct.
void printLookupResult(char *searched, comparisonReturn *lookupResult) {
  if (lookupResult->node != NULL) {
    printf("Found '%s' %d times\n", lookupResult->node->value, lookupResult->node->occurrences);
  } else {
    printf("'%s' not found\n", searched);
  }

  printf("  with %d comparisons.\n", lookupResult->comparisons);
}

// Ask the user for words they would like to lookup in a loop, displaying results.
void doLookups(stringOcc *listContainer, stringOcc *tableContainer) {
  char *choice = NULL;

  // Loop, asking the user to give a word to lookup, then asking whether they would like to search again.
  do {
    // Free the memory location occupied by the last string lookup, if not already free.
    free(choice);

    printf("\nEnter word for retrieval: ");
    choice = readWord(stdin, 2);
    strToLower(choice);

    printf("List: ");
    printLookupResult(choice, listSearch(choice, listContainer->store.list));

    printf("Table: ");
    printLookupResult(choice, tableSearch(choice, tableContainer->store.table));

    printf("Would you like to search again? [Y/n] ");
    choice[0] = loopGetChar(stdin);

    // Quit if choice[0] == ' ', as this means we received EOF.
  } while (choice[0] != 'n' && choice[0] != 'N' && choice[0] != ' ');
}

int main(int argc, char *argv[]) {
  stringOcc *listContainer = malloc(sizeof(stringOcc));
  stringOcc *tableContainer = malloc(sizeof(stringOcc));

  // Initialise the list container. The list pointer is null, as an empty list is merely a null pointer.
  listContainer->isTable = false;
  listContainer->store.list = NULL;

  // Initialise the table container. The table must be created before first use.
  tableContainer->isTable = true;
  tableContainer->store.table = createHashtable(HASHTABLE_BUCKETS);

  // Declare two timers for comparisons.
  clock_t listTimer;
  clock_t tableTimer;

  // Declare a pointer to hold the filename to use.
  char *filename;

  // Take the filename from the command line argument if present, else try the default.
  if (argc > 1) {
    filename = argv[1];
  } else {
    filename = strdup(DEFAULT_FILENAME);
  }

  // Populate the linked list from the file, and time how long it takes.
  listTimer = clock();
  listContainer = populateStruct(filename, listContainer);
  listTimer = clock() - listTimer;

  // Populate the hashtable from the file, and time how long this takes.
  tableTimer = clock();
  tableContainer = populateStruct(filename, tableContainer);
  tableTimer = clock() - tableTimer;

  if (listContainer == NULL || tableContainer == NULL || listContainer->store.list == NULL || tableContainer->store.table == NULL) {
    // If either populate returns null, print the error and end the program.
    fprintf(stderr, "Failed to load words from the file '%s'.\n", filename);

    // Return value > 0 indicates an error has occured.
    return 1;
  } else {

    // Resize the hashtable if it is too full so that lookups take fewer comparisons.
    if (getLoadFactor(tableContainer->store.table) > 3.0f) {
      tableContainer->store.table = resizeRehashTable(tableContainer->store.table);
    }

    // Print statistics on the population process.
    printf("Time for population with %d words:\n  List: %.2f seconds Table: %.2f seconds\n", listContainer->store.list->length, clockToSeconds(listTimer), clockToSeconds(tableTimer));
    printTableMetadata(tableContainer->store.table);

    if (listContainer->store.list->length > 0) {
      // Ask the user which words they would like to lookup.
      doLookups(listContainer, tableContainer);
    } else {
      // We haven't got any words, so don't bother asking for lookup values.
      printf("Found 0 words, quitting.\n");
    }
  }

  // Return 0 to signify successful operation.
  return 0;
}
