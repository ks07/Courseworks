#include <stdio.h>
#include <string.h>

/* Cleans a string that contains null characters, where characters have been stripped. */
void cleanupString(char string[], int newLength) {
  int firstEmpty, next;

  /* Loop through characters until we find the first null character. */
  for (firstEmpty = 0; string[firstEmpty] != '\0'; firstEmpty++) {}
  
  /* Keep note of the next character index to check. */
  next = firstEmpty + 1;
  /* Decrement newLength for each character in the cleaned string. */
  newLength = newLength - firstEmpty;

  /* Each iteration will move/confirm a character's presence in the cleaned string. */
  for (; newLength > 0; newLength--) {
    /* Continue through the string until the next non-null character is found. Danger of an infinite loop here if newLength is greater than the number of non-null characters in the array. */
    while (string[next] == '\0') {
      next++;
    }
    string[firstEmpty] = string[next];
    firstEmpty++;
    next++;
  }

  /* Make sure the string is null terminated. */
  string[firstEmpty] = '\0';
}

/* Removes duplicate characters from a string. Length not including null. */
void condenseName(char name[], int length) {
  int newLength = length;
  int i;

  for (i = 0; i < (length - 1); i++) {
    if (name[i] == name[i + 1]) {
      name[i + 1] = '\0';
      i++;
      newLength--;
    }
  }

  if (newLength != length) {
    /* Use the cleanupString function to remove the nulls we have left throughout the string where characters were stripped. */
    cleanupString(name, newLength);
  }
}

/* Removes all vowels, spaces and hyphens from a string after the first letter. The implementation of generateSOUNDEX means this function isn't necessary, but we will retain it in order to demonstrate a possible implementation. */
void stripChars(char name[], int length) {
  int newLength = length;
  int i;
  for (i = 1; i < length; i++) {
    switch (name[i]) {
    case 'a':
    case 'e':
    case 'i':
    case 'o':
    case 'u':
    case 'w':
    case 'y':
    case 'h':
    case ' ':
    case '-':
      name[i] = '\0';
      newLength--;
      break;
    }
  }

  /* If modified, we use the cleanup function to remove the nulls throughout. */
  if (newLength != length) {
    cleanupString(name, newLength);
  }
}

/* Returns the uppercase representation of a letter if it exists, else returns the letter. */
char toUpper(char letter) {
  /* In ASCII encoding, a-z occupies the range 97-122. */
  if (letter > 96 && letter < 123) {
    /* In ASCII encoding, lowercase letters are 32 positions ahead of their
       uppercase counterparts. */
    return letter - 32;
  } else {
    return letter;
  }
}

/* Returns a character representing the numerical value of the given character in SOUNDEX encoding. Returns '0' if the provided character has an undefined value. */
char getCodeValue(char letter) {
  switch(toUpper(letter)) {
  case 'B':
  case 'P':
  case 'F':
  case 'V':
    return '1';
  case 'C':
  case 'S':
  case 'K':
  case 'G':
  case 'J':
  case 'Q':
  case 'X':
  case 'Z':
    return '2';
  case 'D':
  case 'T':
    return '3';
  case 'L':
    return '4';
  case 'M':
  case 'N':
    return '5';
  case 'R':
    return '6';
  default:
    /* We have forgotten to strip a character, if this is the case. */
    return '0';
  }
}

/* Calculates the SOUNDEX code of the given string and replaces this string with the code. */
void generateSOUNDEX(char name[], int len) {
  condenseName(name, len); /* No need to re-calculate the length here. */
  stripChars(name, strlen(name));
  len = strlen(name);

  /* This needs to be unsigned to avoid a warning from the compiler - negative array indexes are not valid! */
  unsigned char count = 1;
  int i = 1;

  name[0] = toUpper(name[0]);

  /* Loop through the name until we have a full code or have used all letters. */
  while (count < 4 && i < len) {
    name[count] = getCodeValue(name[i]);

    /* If the character did not have an encoded value, try the next. This should only be the case if the name contained unexpected characters. */
    if (name[count] != '0') {
      count++;
    }
    i++;
  }

  /* If there were not enough letters to generate 3 digits, pad with 0s. */
  for (; count < 4; count++) {
    name[count] = '0';
  }

  /* Remember to null-terminate the string. */
  name[4] = '\0';
}

int main(void) {
  char name[31];
  printf("Please enter a name:\n");
  /* Take a name of max-length 30. */
  scanf(" %30[^\n]s", name);
  generateSOUNDEX(name, strlen(name));
  printf("%s\n", name);

  return 0;
}
