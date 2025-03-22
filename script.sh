
nasm -f elf64 $1.asm -l $1.lst

gcc -no-pie -z execstack driver.c printf.o -o ready

rm $1.o

./ready
