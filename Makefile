all:
	nasm -f elf64 -l  print.lst print.asm

	gcc -c main.c
	gcc -o printf.out print.o main.o -no-pie
	./printf.out
