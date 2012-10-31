#include <stdio.h>

#define STACK_MAX_LENGTH 50
#define LOOP_STATE_COMPLETE 0
#define LOOP_STATE_DOWN 1
#define LOOP_STATE_UP 2

/* Raises any real number x to the power y, where y is an integer. */
double power(const double x, int y) {
  /* Handle the special case where x = 0 */
  if (y == 0) {
    return 1;
  }

  double result = x;

  /* No assignment statement in the for loop, we can use the variable y as-is. */
  if (y < 0) {
    for (; y < -1; y++) {
      result = result * x;
    }

    result = 1.0 / result;
  } else {
    for (; y > 1; y--) {
      result = result * x;
    }
  }

  return result;
}

/* Raises any real number x to the power y using the indian algorithm. Y must be
   a positive integer. */
double powerIndian(const double x, const int y) {
  /* Use a bitwise AND to check if odd or even. This works as if the least
       significant bit is a 1, the number is odd. Anything and'ed with 1 will
       only result in a 1 if the LSB is 1 - i.e. an odd number. This should,
       in theory, be faster than using the modulus operator too. */
  if (y == 0) {
    return 1.0;
  } else if ((y & 1) == 1) {
    /* y is odd. */

    return x * (powerIndian(x, y - 1));
  } else {
    /* y is even. */

    /* We cannot use powerIndian to square this result, as it will recurse
       infinitely. Therefore, we square this value 'manually'. In this case,
       we could have called powerIndian twice and multiplied them, but for
       large values of y, this may be slow, so we introduce a new variable. */
    double toSquare = powerIndian(x, y / 2.0);
    return toSquare * toSquare;
  }
}

/* Raises any real number x to the power y using the indian algorithm, where y 
   is a positive integer. Implemented using a while loop. */
double powerLoop(const double x, const int y) {
  double result;
  short int loopState = LOOP_STATE_DOWN;
  int sCurrLen = 0;
  int stackY[STACK_MAX_LENGTH];

  stackY[sCurrLen] = y;

  while (loopState != LOOP_STATE_COMPLETE) {
    if (stackY[sCurrLen] == 0) {
      /* Should only be the case when going down. Turning point. */
      result = 1;
      loopState = LOOP_STATE_UP;
      sCurrLen--;
    } else if ((stackY[sCurrLen] & 1) == 1) {
      /* y is odd. */
      
      if (loopState == LOOP_STATE_DOWN) {
	sCurrLen++;

	/* C has no built in checking for array indexes. */
	if (sCurrLen >= STACK_MAX_LENGTH) {
	  printf("Error: Calculation Overflow\n");
	  return 0;
	}

	stackY[sCurrLen] = stackY[sCurrLen - 1] - 1;
      } else {
	result = x * result;
	sCurrLen--;
      }
    } else {
      /* y is even. */

      if (loopState == LOOP_STATE_DOWN) {
	sCurrLen++;

	if (sCurrLen >= STACK_MAX_LENGTH) {
	  printf("Error: Calculation Overflow\n");
	  return 0;
	}

	stackY[sCurrLen] = stackY[sCurrLen - 1] / 2;
      } else {
	result = result * result;
	sCurrLen--;
      }
    }

    if (sCurrLen < 0 && loopState == LOOP_STATE_UP) {
      loopState = LOOP_STATE_COMPLETE;
    }
  }

  return result;
}

int main() {
  printf("%f\n", 1000 * power(1.0 + (5.0/100.0), 25));
  printf("%f\n", 10000 * power(1 + (4.0/100.0), -12));
  printf("%f\n", powerIndian(1.0000000001, 1000000000));
  printf("%f\n", powerLoop(1.0000000001, 2000000000));
  return 0;
}
