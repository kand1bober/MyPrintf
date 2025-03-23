#include <stdio.h>

extern int MyPrintf( const char*, ... ) __attribute__((format(printf, 1, 2)));
 
int main( int argc, char* argv[] )
{
    int a = 0;

    printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
    -1,
    -1,
    "love",
    3802,
    100,
    33,
    127,
    -1,
    "love", 3802, 100, 33, 127);

    MyPrintf("\n");

    MyPrintf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
    -1,
    -1,
    "love",
    3802,
    100,
    33,
    127,
    -1,
    "love", 3802, 100, 33, 127);

    // MyPrintf("Hello %!\n");

    return 0;
}


