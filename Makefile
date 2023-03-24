all:
	nasm -f elf64 -l  main.lst main.asm
	nasm -f elf64 -l  print.lst print.asm

	ld -s -o printf main.o print.o

run:
	./printf
