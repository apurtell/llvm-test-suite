//===--- part_select.c --- Test The bit_select builtin --------------------===//
//
// This file was developed by Reid Spencer and is distributed under the 
// University of Illinois Open Source License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This test case tests the __builtin_part_select builtin function llvm-gcc.
// bit_select selects one bit out of a larger 
//
//===----------------------------------------------------------------------===//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "bits.h"

#ifdef ENABLE_LARGE_INTEGERS
typedef uint256 BitType;
const BitType X = 0xFEDCBA9876543210ULL;
#else
typedef uint47 BitType;
const BitType X = 0xFEDCBA9876543210ULL;
#endif

int main(int argc, char** argv)
{

#ifdef ENABLE_LARGE_INTEGERS
  BitType Y = X * X;
#else
  BitType Y = X;
#endif

  srand(0);

  unsigned i, j;

  for (i = 0; i < bitwidthof(BitType); ++i) {
    BitType left = rand() % bitwidthof(BitType);
    BitType right = i;
    printf("part_select(Y, %3u, %3u) = ", (unsigned)left, (unsigned)right);
    BitType Z = part_select(Y, right, left );
    printBits(Z);
    uint64_t val = Z;
    printf(" (%lx)", val);
    printf("\n");
  }

  return 0;
}
