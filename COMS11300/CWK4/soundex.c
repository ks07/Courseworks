#include <stdio.h>

char[] condenseName(char[] name, int length) {
  int newLength = length;

  for (int i = 0; i < length ; i++) {
    if (name[i] == name[i + 1]) {
      name[i + 1] = '\0';
      i++;
      newLength--;
    }
  }

  char[newLength] ret;
  for (int i = 0; i < length ; i++) {
    
  
}
