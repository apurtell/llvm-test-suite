#include <stdio.h>

typedef int __attribute__ ((bitwidth(33))) int33;

struct s {
  int33 field[0];
};

#define OFFS \
        (((char *) &((struct s *) 0)->field[1]) - (char *) 0)

int foo[OFFS];

int main()
{
    printf("%d\n", OFFS);
    return 0;
}
