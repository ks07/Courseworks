#ifndef __MODMUL_H
#define __MODMUL_H

#define DEBUG
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
} tMontParams;

#endif
