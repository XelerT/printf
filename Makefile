all:
	clear
	nasm -f elf64 -l print.lst print.s

	gcc -c main.c
	gcc -o printf.out print.o main.o -no-pie
	./printf.out

test:
	clear
	nasm -f elf64 -l print.lst print.s

	gcc -c test.c
	gcc -o test.out print.o test.o -no-pie
	./test.out
