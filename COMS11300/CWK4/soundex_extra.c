#include <stdio.h>
#include <string.h>

/* Removes duplicate characters from a string. */
char *condenseName(char name[], int length) {
  int newLength = length + 1;
  int i;

  for (i = 0; i < (length - 1); i++) {
    if (name[i] == name[i + 1]) {
      name[i + 1] = '\0';
      i++;
      newLength--;
    }
  }

  int j = 0;

  char ret[newLength];
  for (i = 0; i < length ; i++) {
    if (name[i] != '\0') {
      ret[j] = name[i];
      j++;
    }  
  }
  ret[j] = '\0';
  return strdup(ret);
}

/* Removes all vowels, spaces and hyphens from a string after the first letter. */
char *stripChars(char name[], int length) {
  int newLength = length + 1;
  int i, j;
  for (i = 0; i < length; i++) {
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

  char ret[newLength];
  j = 0;
  for (i = 0; i < length; i++) {
    if (name[i] != '\0') {
      ret[j] = name[i];
      j++;
    }
  }

  ret[j] = '\0';
  return strdup(ret);
}

/* Returns the uppercase representation of a letter if it exists, else returns the letter. */
char toUpper(char letter) {
  if (letter > 96 && letter < 123) {
    /* In ASCII encoding, lowercase letters are 32 positions ahead of their
       uppercase counterparts. */
    return letter - 32;
  } else {
    return letter;
  }
}

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

char *generateSOUNDEX(char name[], int len) {
  /* This needs to be unsigned to avoid a warning from the compiler - negative array indexes are not valid! */
  unsigned char count = 1;
  char encoded[5];
  int i = 1;

  encoded[0] = toUpper(name[0]);
  encoded[1] = '0';
  encoded[2] = '0';
  encoded[3] = '0';
  encoded[4] = '\0';

  while (count < 4 && i < len) {
    encoded[count] = getCodeValue(name[i]);
    if (encoded[count] != '0') {
      count++;
    }
    i++;
  }

  return strdup(encoded);
} 

int main(void) {
  char s[31];
  printf("Please enter a name:\n");
  scanf(" %30[^\n]s", s);
  char *t = strdup(s);
  t = condenseName(t, strlen(t));
  t = stripChars(t, strlen(t));
  t = generateSOUNDEX(t, strlen(t));
  printf("%s\n", t);

  return 0;
}
