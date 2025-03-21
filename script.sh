#!/bin/bash

rm $1

nasm -f elf64 $1.asm -l $1.lst
gcc -no-pie -z execstack $1.o -o $1
rm $1.o

./$1
