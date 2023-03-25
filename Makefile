all: minuses
	# nasm -f elf64 -l  main.lst main.asm
	nasm -f elf64 -l  print.lst print.asm

	gcc -c main.c
	# ld -s -o printf main.o print.o
	gcc -o lox.out print.o main.o -no-pie
	./lox.out

minuses:
	@echo ------------------------------------------------------
run:
	# ./printf
	./lox.out
