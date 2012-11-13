#include <stdio.h>
#include <string.h>

/* Removes duplicate characters from a string. */
char *condenseName(char name[], int length) {
  int newLength = length + 1;
  int i;

  for (i = 0; i < (length - 1) ; i++) {
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
  ret[newLength - 1] = '\0';
  return strdup(ret);
}

int main(void) {
  char s[26];
  strncpy(s, "ababbccddeeffgghhiijjkkllmmm", 26);
  printf("%s\n", s);
  printf("%s\n", condenseName(s, 26));
  return 0;
}
