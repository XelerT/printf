;  %include "print.asm"

section .text

global _start

extern printf

 _start:
                mov rdi, line
                mov rsi, 256
                mov rdx, line_to_printf2
                mov rcx, line_to_printf3
                mov r8, 0xABCDEF
                mov r9, 0xFEDCBA
                push 0xFEDE
                push 0xBADDED

                call printf

                mov rax, 0x3C
                xor rdi, rdi
                syscall

section .data
; %d %s %x %%%c %b, -1, "love", 0xEDA, '!', 127

line: db "My line", 0xA, "%d %s %s %o %x %x %x", 0xA, 0
line_to_printf: db "Printfed line", 0xA, 0
line_to_printf2: db "Second line", 0
line_to_printf3: db "Third line", 0xA, 0
