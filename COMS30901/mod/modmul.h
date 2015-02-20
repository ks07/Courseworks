#ifndef __MODMUL_H
#define __MODMUL_H

#define NDEBUG
//#define DEBUG
//#define FIXEDY

// In case both NDEBUG and DEBUG are set, revert to NDEBUG only
#ifdef NDEBUG

#ifdef DEBUG
#undef DEBUG
#endif

#endif

#include  <stdio.h>
#include <stdlib.h>

#include <string.h>
#include    <gmp.h>

#include <assert.h>

typedef struct MontParams {
  mpz_t N;
  mp_limb_t omega;
  mpz_t rho_sq;
  // Will always need to undo the mont transform eventually (at least in our implementation)
  // so store a copy of the one constant to avoid recreating it
  mpz_t one;
} tMontParams;

#endif
