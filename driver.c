#include <stdio.h>

extern int MyPrintf( const char*, ... ) __attribute__((format(printf, 1, 2)));
 
int main( int argc, char* argv[] )
{
    printf("%c", '\0');

    int a = 0;

    // a = MyPrintf("%d %c %o %b \n"
    //             "My uncle was a man of virture, \n"
    
    //             "When he became quite old and sick,\n"

    //             "He sought respect and tried to teach me,\n"

    //             "His only heir, verte and weak.\n"

    //             "He had the fun, I had the sore,\n"

    //             "But grecious goodness! what a bore!\n"

    //             "To sit by bedplace day and night,\n"

    //             "Not doing even step aside,\n"

    //             "And what a cheep and cunning thing\n"

    //             "To entertain the sad,\n"

    //             "To serve around, make his bed,\n"

    //             "To fetch the pills, to mourn and grim,\n"

    //             "To sigh outloud, think along:\n"

    //             "God damn old man, why ain't you gone?'\n",
    //             -1313, 90, 235, 1313 );

    a = MyPrintf("Hello %c\n", 65 );
    a = MyPrintf("Hello %c\n", 65 );
    a = MyPrintf("Hello %c\n", 65 );
    a = MyPrintf("Hello %c\n", 65 );

    return 0;
}


