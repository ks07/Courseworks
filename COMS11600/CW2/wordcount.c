#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <time.h>

// Define some constants with the preprocessor. These act like simple substitutions, and are seen as literals when compiling.
#define DEFAULT_FILENAME "a_portrait.txt"
#define HASHTABLE_BUCKETS 2099
#define RESIZE_FACTOR 1.5f
#define RESIZE_LIMIT 1.0f

/*
 * General word handling functions.
 */

/*
 * Changes all uppercase characters in the given string into their lowercase counterparts.
 * The change is performed in-place, thus a copy should be passed if the original must be preserved.
 *
 * char *str : A pointer to the string to modify.
 */
void strToLower(char *str) {
  int i;

  for (i = 0; str[i] != '\0'; i++) {
    str[i] = tolower(str[i]);
  }
}

/*
 * Define an enumerated type to represent the outcome of isWordChar.
 */
typedef enum {
  NO = 0, // False, stop reading.
  YES = 1, // True, continue.
  FINAL = 2 // True, but do not consume another character.
} WordCharResult;

/*
 * Checks whether a given character should be considered part of the given word,
 * looking at the previous and next character, if they exist.
 *
 * char new  : The character to decide whether it should be appended or not.
 * char prev : The final character of the word we are appending to. Supply '\0' if empty.
 * int next  : The next character in the input buffer. Supply '\0' if it should not be checked.
 * 
 * Returns a WordCharResult enum value defining the appropriate treatment of the new character.
 */
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

/*
 * Reads in the next alphanumeric character from stdin - i.e. the first letter of the word.
 *
 * FILE *src : A pointer to the input stream we should read from. May be stdin.
 *
 * Returns the next character, or a space (' ') if EOF was reached.
 */
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

/*
 * Reads the next word from the given input stream. A word is any string of characters bounded by whitespace or a non-alphanumeric
 * character. A word may contain single - or ' characters. The array will be automatically resized to fit the input if possible.
 *
 * FILE *src         : A pointer to the input stream we should read from. May be stdin.
 * unsigned int size : The starting size of the char array to hold the string. Should be >= 2.
 * 
 * Returns NULL if no more words could be read, or if there was not enough memory to complete the word. Otherwise, returns a
 * pointer to the string containing the word, or as much of the word as possible if memory limits are reached.
 */
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

    // If wordChar is FINAL, then we should not read any more letters to avoid consuming more than necessary.
    if (wordChar == YES) {
      // Read ahead one letter to help decide whether to keep the current.
      readAhead = fgetc(src);

      // Check the input now that we have our first set of 3 characters.
      wordChar = isWordChar(tmpChar, input[0], readAhead);

      // Loop until we've reached the final character and added it to the string.
      while (wordChar != NO) {
	// Change the case, and cast to char.
	input[i] = tolower((char)tmpChar);

	// Check the array size then increment the counter.
	if (i++ > size) {
	  // The next character, whether it is \0 or otherwise, will be out of bounds, so expand.
	  size = size * 2;

	  // Use realloc to resize the array without losing it's contents. Tries to resize in-place to avoid copying.
	  tmpPtr = realloc(input, size);

	  if (tmpPtr == NULL) {
	    // Could not expand the array, so return the word so far and treat the remainder as a new word.
	    // Attempt to increase by two characters so we don't lose the one we have kept in readAhead.
	    size = (size / 2) + 2;
	    tmpPtr = realloc(input, size);

	    if (tmpPtr == NULL) {
	      // Print an error message to stderr, so the user is aware of potential inaccuracy of results.
	      fprintf(stderr, "Reached max word length, unable to split word.");

	      return NULL;
	    } else {
	      input = tmpPtr;

	      // The minimal resize was a success, so store both the consumed character and terminate the string.
	      input[i] = readAhead;
	      input[i + 1] = '\0';

	      fprintf(stderr, "Reached max word length, splitting word after '%s'.", input);

	      // Return the incomplete word, without losing characters.
	      return input;
	    }
	  } else {
	    // The resize was successful, so we can use the new memory location.
	    input = tmpPtr;
	  }
	}

	if (wordChar == YES) {
	  // The current char, and the following char are accepted, so continue to consume characters.
	  tmpChar = readAhead;
	  readAhead = fgetc(src);

	  // Decide on the new status.
	  wordChar = isWordChar(tmpChar, input[i - 1], readAhead);
	} else if (wordChar == FINAL) {
	  // We should not read any more to avoid losing characters from the next word, so stop the loop.
	  wordChar = NO;
	}
      }
    }

    // Terminate our string.
    input[i] = '\0';
  }

  // Return the pointer to the string.
  return input;
}

/*
 * Linked list functions and structs.
*/

/*
 * A struct that holds a linked list that counts occurrences of strings.
 */
typedef struct _stringOccList {
  struct _stringOccList *next;
  char *value;
  int occurrences;
  // Keep track of the length so that we do not need to iterate over the entire list to calculate the max overflow.
  // This can give us the position in the list, and thus might be useful if we decided to improve upon the list approach.
  unsigned int length;
} stringOccList;

/*
 * A struct that holds the result of searching the list.
 */
typedef struct _comparisonReturn {
  struct _stringOccList *node;
  unsigned int comparisons;
} comparisonReturn;

/*
 * Checks if a linked list beginning with *list contains the given value.
 *
 * char *value         : A pointer to the string to search the list for.
 * stringOccList *list : A pointer to the head of the list to search within.
 *
 * Returns the node containing the value if present, else NULL, paired with a count of the string comparisons
 * needed to find this result.
 */
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

  // Set the list item we found as part of the return value. Will assign the null pointer if we found nothing.
  ret->node = list;
  return ret;
}

/*
 * Inserts a pre-existing node as the head of a given linked list. This performs no check for uniqueness,
 * so should only be used when modifying an already existing list (such as during a hashtable resize).
 *
 * stringOccList *node : A pointer to the node to add to the list.
 * stringOccList *node : A pointer to the head of the list to add to.
 *
 * Returns the supplied node as the head of the list.
 */
stringOccList *listInsertNode(stringOccList *node, stringOccList *list) {
  // Set the node as the head of it's new list.
  node->next = list;

  // If the list is empty, set length to 1, else set the length to reflect the new list.
  node->length = list == NULL ? 1 : list->length + 1;

  // Return the node as head of the list.
  return node;
}

/*
 * Inserts a new node as the head of a given linked list, if the string is new. Otherwise, increases the
 * running total of that string within the list.
 *
 * char *value         : A pointer to the string to insert into the list.
 * stringOccList *list : A pointer to the head of the list to insert into.
 *
 * Returns the new node / the head of the list.
 */
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

/*
 * Determines whether a number is prime or not. Source:
 * http://stackoverflow.com/questions/4475996/given-prime-number-n-compute-the-next-prime/5694432#5694432
 *
 * unsigned int number : The number to test.
 *
 * Returns true if the number is a prime number.
 */
bool isPrime(unsigned int number) {
  unsigned int i, div;

  for (i = 3; true; i += 2) {
    div = number / i;

    if (div < i) {
      return true;
    } else if (number == div * i) {
      // Check if the reverse matches the input to see if the division result was exact, or truncated.
      return false;
    }
  }

  // We should never reach this case, but this should silence compiler warnings.
  return true;
}

/*
 * Gets the next prime after the given starting value, which is closest to the given target. Source:
 * http://stackoverflow.com/questions/4475996/given-prime-number-n-compute-the-next-prime/5694432#5694432
 *
 * unsigned int start  : The number to begin searching after.
 * unsigned int target : The number we must find the nearest prime to.
 *
 * Returns an unsigned int which is the closest prime to target.
 */
unsigned int nextPrime(unsigned int start, unsigned int target) {
  unsigned int prev = 0;
  bool loop = true;

  if (start & 1) {
    // If start is odd, add 2 before we start to loop.
    start += 2;
  } else {
    // Else add 1 to make it odd.
    start++;
  }

  // Continually loop until we've got a prime either side of the target.
  while (loop) {
    if (isPrime(start)) {
      if (start < target) {
	prev = start;
	start += 2;
      } else {
	loop = false;
      }
    } else {
      // Increment the number by 2, we should skip even numbers.
      start += 2;
    }
  }

  if (prev != 0 && (target - prev) < (start - target)) {
    // Prev is the closer prime to target, so return it.
    return prev;
  } else {
    return start;
  }
}


/*
 * Hashtable functions.
 */

/*
 * Define a structure to hold a hashtable. Reliant on the previously defined linked list implementation.
 */
typedef struct _stringOccTable {
  // Stores a pointer to an array of stringOccList pointers initialised to NULL. The array pointer is
  // not constant, and thus may be resized.
  struct _stringOccList **table;
  unsigned int emptyBucketCount;
  unsigned int bucketCount;
  unsigned int itemCount;
} stringOccTable;

/*
 * FNV-1a 32-bit hash function. Should be called via calcHash, to perform the modulus. Source:
 * http://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function#FNV-1a_hash
 *
 * char *key : A pointer to the string key to hash.
 *
 * Returns the raw hash of the given key.
 */
unsigned int calculateHash(char *key) {
  // Define some constants used in the hash generation.
  const unsigned int FNV_OFFSET_BASIS = 2166136261;
  const unsigned int FNV_PRIME = 16777619;
  
  unsigned int i, hash = FNV_OFFSET_BASIS;

  // Perform the operation on all characters.
  for (i = 0; key[i] != '\0'; i++) {
    hash = hash ^ key[i];
    hash = hash * FNV_PRIME;
  }

  // Return the finished hash.
  return hash;
}

/*
 * Calculate the hash of a given string key, assuring that the returned value is within the range of buckets.
 *
 * char *key            : A pointer to the string key to hash.
 * unsigned int buckets : The number of buckets currently in the hashtable we are inserting into.
 *
 * Returns the hash value of the given key.
 */
unsigned int calcHash(char *key, unsigned int buckets) {
  // Use the calculateHash function to produce the raw hash.
  unsigned int hash = calculateHash(key);

  // Mod the result of the hash calculation so we don't go out of bounds.
  return hash % buckets;
}

/*
 * Creates a new hashtable struct.
 *
 * unsigned int buckets : The initial number of buckets to use. A prime number may be beneficial, but is not necessary.
 *
 * Returns a pointer to a stringOccTable struct that holds an array of lists to act as overflow, and some
 * variables to store metadata. Returns NULL if allocation failed. See struct declaration for more information.
 */
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

  // Initialise some of the metadata held about the new hashtable.
  table->bucketCount = buckets;
  table->emptyBucketCount = buckets;

  return table;
}

/*
 * Searches the given hash table for the list node containing key.
 *
 * char *key              : A pointer to the string key to search for.
 * stringOccTable *hTable : A pointer to the hashtable we should search inside of.
 *
 * Returns the stringOccList node containg the given key, else NULL if the key is not present, accompanied
 * by a count of the number of string comparisons required to achieve the result.
 */
comparisonReturn *tableSearch(char *key, stringOccTable *hTable) {
  unsigned int hash = calcHash(key, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];

  if (bucket == NULL) {
    // The bucket is empty, thus the table does not contain an entry corresponding to the given key.
    // Use calloc so the pointer is NULL, and the counter is 0, as expected.
    return calloc(1, sizeof(comparisonReturn));
  } else {
    // Re-use the list search method to traverse the bucket.
    return listSearch(key, bucket);
  }
}

/*
 * Inserts a value into the given hash table, incrementing it's counter if it already exists. hTable must be
 * initialised with createHashTable before being used as a parameter to this function.
 *
 * char *value            : A pointer to the string to insert into the hashtable.
 * stringOccTable *hTable : A pointer to the hashtable we should insert into.
 */
void tableInsert(char *value, stringOccTable *hTable) {
  unsigned int prevCount, hash = calcHash(value, hTable->bucketCount);
  stringOccList *bucket = hTable->table[hash];

  if (bucket == NULL) {
    // The bucket is empty, thus we must decrease the count of empty buckets.
    hTable->emptyBucketCount--;
    prevCount = 0;
  } else {
    // We must store the previous length of the bucket, so we can determine whether a new key was added.
    prevCount = bucket->length;
  }

  // Insert into the relevant bucket, and update the pointer in the table.
  bucket = listInsert(value, bucket);

  if (prevCount < bucket->length) {
    // Insertion added a new node, so we must increment the item counter.
    hTable->itemCount++;
  }

  hTable->table[hash] = bucket;
}

/*
 * Calculates the maximum overflow of the hashtable.
 *
 * stringOccTable *hTable : A pointer to the hashtable to use.
 *
 * Returns the highest number of keys stored in a single bucket.
 */
unsigned int getMaxOverflow(stringOccTable *hTable) {
  unsigned int i, over = 0;

  for (i = 0; i < hTable->bucketCount; i++) {
    if (hTable->table[i] != NULL && hTable->table[i]->length > over) {
      over = hTable->table[i]->length;
    }
  }

  return over;
}

/*
 * Calculates the load factor of the given hashtable.
 *
 * stringOccTable *hTable : A pointer to the hashtable to use.
 *
 * Returns the load factor as a float.
 */
float getLoadFactor(stringOccTable *hTable) {
  // Load factor = Number of keys / Number of buckets
  return (float)hTable->itemCount / (float)hTable->bucketCount;
}

/*
 * Increases the number of buckets in the given table, and rehashes and rearranges the keys inside. 
 *
 * stringOccTable *orig : A pointer to the original hashtable that we should resize. Warning: The location
 *                        pointed to will be freed by this function!
 *
 * Returns a new hashtable containg the contents of the original.
 */
stringOccTable *resizeRehashTable(stringOccTable *orig) {
  // Create a new hashTable with the increased bucket count.
  unsigned int newBuckets = nextPrime(orig->bucketCount, (unsigned int)(orig->bucketCount * RESIZE_FACTOR));
  stringOccTable *new = createHashtable(newBuckets);

  // Declare some variables to use when looping.
  unsigned int i, newHash;
  stringOccList *node, *next;

  new->itemCount = orig->itemCount;

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


/*
 * Main function and user interactions/control.
 */

/*
 * A struct that can hold some kind of data structure that counts occurences of strings.
 */
typedef struct {
  // The tag that identifies which union member to access.
  bool isTable;

  // Wrap a union in struct, so we can store a tag that identifies the internal type.
  union {
    stringOccList *list;
    stringOccTable *table;
  } store;
} stringOcc;

/*
 * Populates a given stringOcc struct with all the words found in the file represented by filename.
 *
 * char *filename  : The filename of the text file to read from.
 * stringOcc *fill : The string occurence counting struct to fill. The structure must be initialised
 *                   if the type requires it. (i.e. if this is a hashtable)
 *
 * Returns the supplied struct with the new contents added, or NULL if no words could be read.
 */
stringOcc *populateStruct(char *filename, stringOcc *fill) {
  FILE *inputFile;

  inputFile = fopen(filename, "r");

  // Could not open the given file, perhaps it does not exist, or insufficient permissions.
  if (inputFile != NULL) {
    char *word;

    // Read the next word from the text file.
    word = readWord(inputFile, 2);

    // Loop until we reach the end of the file, or an error occurs that prevents reading a word.
    while (word != NULL) {
      // Ascertain the type of the data structure, and add to it accordingly.
      if (fill->isTable) {
	tableInsert(word, fill->store.table);

	// Resize the hashtable if it is too full so that lookups take fewer comparisons.
	if (getLoadFactor(fill->store.table) > RESIZE_LIMIT) {
	  fill->store.table = resizeRehashTable(fill->store.table);
	}
      } else {
	fill->store.list = listInsert(word, fill->store.list);
      }

      // Read one more word.
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

/*
 * Prints the entire contents of a supplied string counting list.
 *
 * stringOccList *head : The head of the list to print values from.
 */
void printList(stringOccList *head) {
  while (head != NULL) {
    printf("'%s' %d\n", head->value, head->occurrences);
    head = head->next;
  }
}

/*
 * Prints some metadata about the state of a given string counting hashtable.
 *
 * stringOccTable *hTable : A pointer to the hashtable to print information about.
 */
void printTableMetadata(stringOccTable *hTable) {
  printf("Table {loadFactor: %.2f, buckets: %d, empty: %d, maxOver: %d}\n", getLoadFactor(hTable), hTable->bucketCount, hTable->emptyBucketCount, getMaxOverflow(hTable));
}

/*
 * Prints the entire contents of a string counting hashtable, including metadata.
 *
 * stringOccTable *hTable : A pointer to the hashtable to print.
 */
void printTable(stringOccTable *hTable) {
  int i;

  // Print the metadata first.
  printTableMetadata(hTable);

  // Loop through all buckets, using the list printing function to print the nodes.
  for (i = 0; i < HASHTABLE_BUCKETS; i++) {
    printf("=Bucket %d (%d):\n", i, hTable->table[i] == NULL ? 0 : hTable->table[i]->length);

    printList(hTable->table[i]);
  }
}

/*
 * Converts a time created with clock() into a float representing the time in seconds.
 *
 * clock_t clocks : The time value as reported by time.h functions.
 *
 * Returns a float value representing the time in seconds.
 */
float clockToSeconds(clock_t clocks) {
  return ((float)clocks) / CLOCKS_PER_SEC;
}

/*
 * Prints the result of a lookup operation to stdout from a given comparisonReturn struct.
 *
 * char *search                   : A pointer to the string of the value searched for.
 * comparisonReturn *lookupResult : A pointer to the result of a lookup operation.
 */
void printLookupResult(char *searched, comparisonReturn *lookupResult) {
  if (lookupResult->node != NULL) {
    printf("Found '%s' %d times\n", lookupResult->node->value, lookupResult->node->occurrences);
  } else {
    // We need the searched parameter so that we can print the interpreted string even if it doesn't exist.
    printf("'%s' not found\n", searched);
  }

  // Show the number of comparisons we needed.
  printf("  with %d comparisons.\n", lookupResult->comparisons);
}

/*
 * Ask the user for words they would like to lookup in a loop, displaying results.
 *
 * stringOcc *listContainer  : The list we should search.
 * stringOcc *tableContainer : The table we should search.
 */ 
void doLookups(stringOcc *listContainer, stringOcc *tableContainer) {
  char *choice = NULL;

  // Loop, asking the user to give a word to lookup, then asking whether they would like to search again.
  do {
    // Free the memory location occupied by the last string lookup, if not already free.
    free(choice);

    // Prefix a newline to group lookups.
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

/*
 * The main function of the program. A single optional argument is accepted, which is the filename
 * of the text file that we should read from.
 */
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
