 %include "print.asm"

 section .text

 global _start

 _start:
                mov rdi, line
                mov rsi, 256
                mov rdx, line_to_printf2
                mov rcx, line_to_printf3
                mov r8, 0xABCDEF
                mov r9, 0xFEDCBA
                push 0xFEDE
                push 0xBADDED

                call print_format_line

                mov rax, 0x3C
                xor rdi, rdi
                syscall

section .data

line: db "My line", 0xA, "%d %s %s %x %x %x %x", 0xA, 0
line_to_printf: db "Printfed line", 0xA, 0
line_to_printf2: db "Second line", 0
line_to_printf3: db "Third line", 0xA, 0
