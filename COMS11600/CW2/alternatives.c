// Old hash functions.

/* // Calculates the hash of a give string key. */
/* // Returns the hash value of the given key. */
/* unsigned int calculateHash(char *key) { */
/*   char current = key[0]; */
/*   unsigned int i, hash = 0; */

/*   for (i = 1; current != '\0'; i++) { */
/*     hash += current; */
/*     current = key[i]; */
/*   } */

/*   return hash; */
/* } */

/* // Int sum hash. */
/* unsigned int calculateHash(char key[]) { */
/*   unsigned int i, j, shift, hash = 0, mod, count; */

/*   // Calculate the size of an int in terms of the size of a char. */
/*   const unsigned int intSize = sizeof(int) / sizeof(char); */

/*   // Calculate the number of chars in the string that do not form a complete int. */
/*   mod = strlen(key) % intSize; */

/*   // Calculate the limit of our loop. */
/*   count = (strlen(key) - mod) / intSize; */

/*   // Loop through until we've constructed all possible ints. */
/*   for (i = 0; i < count; i += 4) { */
/*     hash += key[i] + (key[i + 1] << 8) + (key[i + 2] << 16) + (key[i + 3] << 24); */
/*   } */

/*   // If we have outstanding chars, add them. */
/*   for (j = 0; j < mod; j++) { */
/*     i += j; */
/*     shift = j * 8; */
/*     hash += key[i] << shift; */
/*   } */

/*   return hash; */
/* } */

/* // Modified Bernstein hash. */
/* unsigned int calculateHash(char key[]) { */
/*   unsigned int i, hash = 0; */

/*   for (i = 0; key[i] != '\0'; i++) { */
/*     hash = 33 * hash ^ key[i]; // ^ = XOR */
/*   } */

/*   return hash; */
/* } */

/* // One-at-a-Time hash */
/* unsigned int calculateHash(char key[]) { */
/*   unsigned int i, hash = 0; */

/*   for (i = 0; key[i] != '\0'; i++) { */
/*     hash += key[i]; */
/*     hash += (hash << 10); */
/*     hash ^= (hash >> 6); */
/*   } */

/*   hash += (hash << 3); */
/*   hash ^= (hash >> 11); */
/*   hash += (hash << 15); */

/*   return hash; */
/* } */

/* // sdbm hash */
/* unsigned int calculateHash(char key[]) { */
/*   unsigned int i, hash = 0; */

/*   for (i = 0; key[i] != '\0'; i++) { */
/*     hash = key[i] + (hash << 6) + (hash << 16) - hash; */
/*   } */

/*   return hash; */
/* } */
