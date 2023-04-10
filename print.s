section .text

extern printf
global my_printf
; call standard printf()

;----------------------------------------------------------------------------------------------------------------------------------------
;       Print nullterminated line in terminal using syscall. Uses get_line_len to count length of the line.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry: rsi - pointer on the nullterminated line
;       Destroys: rdi
;                 rax
;                 rbx
;
;-----------------------------------------------------------------------------------------------------------------------------------------

print_null_term_line:
                call get_line_len                       ; calculate length of the line

                mov rdx, rax                            ; write length for syscall
                mov rax, 0x01                           ; use write function
                mov rdi, 1
                syscall

                ret

;----------------------------------------------------------------------------------------------------------------------------------------
;       Calculates length of the nullterminated line.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry: rsi - pointer on the nullterminated line
;       Destroys: rdi
;                 rax
;                 rbx
;
;-----------------------------------------------------------------------------------------------------------------------------------------

get_line_len:
                xor rdi, rdi
                xor rax, rax
                xor rbx, rbx
                dec rdi

.count_char:
                inc rdi
                inc rax
                cmp byte [rsi + rdi], 0                 ; check line terminator
                jne .count_char

                ret

;----------------------------------------------------------------------------------------------------------------------------------------
;       Prints number symbols.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  push n (first argument in stack is number of symbols)
;               push p (second argiment in stack is pointer on the nullterminated line)
;       Destroys: rdi
;                 rax
;                 rbx
;
;-----------------------------------------------------------------------------------------------------------------------------------------

print_n_symbs:

                mov rsi, [rsp + 1 * 8]          ; pointer on line
                mov rdx, [rsp + 2 * 8]          ; length of the line

                mov rax, 0x01                   ; use write funtion
                mov rdi, 1
                syscall

                ret

;----------------------------------------------------------------------------------------------------------------------------------------
;       Prints format line. On % call print functions
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  rdi - pointer on format line
;               rsi - first argument
;               rdx - second argument
;               rcx - third argument
;               r8  - forth argument
;               r9 -  fifth argument
;               Another arguments through stack
;       Destroys: r14
;                 r15
;                 r12
;       Can destroy: r10
;
;-----------------------------------------------------------------------------------------------------------------------------------------

my_printf:
                call printf

                xor r14, r14
                mov r15, rdx                    ; save rdx
                mov r12, rcx                    ; save rcx
.print_symb:
                cmp byte [rdi], '%'             ; check %
                jne .next_symb

                cmp byte [rdi + 1], '%'
                je .percent

                call push_next_printf_arg       ; put next argument to printf in stack
                inc r14                         ; increases argument counter

                call printf_arg                 ; choose format of argument and print it
                add rsp, 8                      ; delete argument from push_next_printf_arg

                jmp .print_symb
.percent:
                inc rdi
.next_symb:
                push rsi                        ;/
                push rdx                        ;       save registers
                push rdi                        ;/
                call print_char
                pop rdi                         ;/
                pop rdx                         ;       restore registers
                pop rsi                         ;/

                inc rdi                         ; next symbol in format line

                cmp byte [rdi], 0
                jne .print_symb

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print argument. Uses jump table to choose format function.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:          rdi - pointer on the line
;       Destroys:       rdi
;                       rax
;                       rcx
;
;------------------------------------------------------------------------------------------------------------------------------------------

%define dup_err(from, to) times (to - from + 1) dq .error

printf_arg:
                inc rdi

                cmp byte [rdi], 'b'
                jb .error

                cmp byte [rdi], 'x'
                ja .error

                xor rax, rax
                mov al, byte [rdi]
                sub al, 'b'

                push rsi
                push rdi
                push rdx

                mov rax, qword .JMP_TABLE[rax * 8]
                jmp rax
.JMP_TABLE:
        dq   .binary   ; = b
        dq   .char     ; = c
        dq   .decimal  ; = d
        dup_err('e', 'n')
        dq   .octal    ; = o
        dup_err('p', 'r')
        dq   .string   ; = s
        dup_err('t', 'w')
        dq   .hex      ; = x

.string:
                mov rsi, qword [rsp + 4 * 8]                    ; get argument

                call print_null_term_line

                jmp .break
.decimal:
                mov rax, qword [rsp + 4 * 8]                     ; get argument

                call print_sign_decimal                          ; get argument

                jmp .break
.hex:
                mov rbx, qword [rsp + 4 * 8]                     ; get argument

                call print_hex

                jmp .break
.char:
                push qword [rsp + 4 * 8]                        ; get argument
                call print_char
                add rsp, 8
                jmp .break
.octal:
                mov rbx, qword [rsp + 4 * 8]                    ; get argument

                call print_octo

                jmp .break
.binary:
                mov r10, qword [rsp + 4 * 8]                    ; get argument

                call print_binary

                jmp .break

.error:
                mov rsi, ERROR_LINE
                push rdi
                call print_null_term_line                       ; print error line
                pop rdi
                jmp .exit
.break:
                pop rdx
                pop rdi
                pop rsi

.exit:
                inc rdi
                ret

%undef dup_err

;------------------------------------------------------------------------------------------------------------------------------------------
;       Pushes printf argument in stack if it's in registers.
;               If argument is in stack, it will change it's position
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:          r14 - argument counter
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

push_next_printf_arg:

                pop rax                         ; return adress from push_next_printf_arg

                cmp r14, 5                      ; if more than 5 arguments, get it in stack
                jae .ARG_IN_STK

                mov rbx, qword [.ARG_OFFSET + r14 * 8]          ; jump table calculation
                jmp rbx

.ARG_OFFSET:
        dq .ARG_IN_RSI
        dq .ARG_IN_RDX
        dq .ARG_IN_RCX
        dq .ARG_IN_R8
        dq .ARG_IN_R9

.ARG_IN_RSI:
                push rsi
                jmp .RETURN
.ARG_IN_RDX:
                push r15                ; contains rdx
                jmp .RETURN
.ARG_IN_RCX:
                push r12                ; contains rcx
                jmp .RETURN
.ARG_IN_R8:
                push r8
                jmp .RETURN
.ARG_IN_R9:
                push r9
                jmp .RETURN
.ARG_IN_STK:
                pop rbx                  ; return adress from print_format_line
                pop r13
                push rbx
                push r13
.RETURN:
                push rax
                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print char in terminal.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  in stack pointer on line
;       Destroys: rsi
;                 rdx
;                 rdi
;                 rax
;------------------------------------------------------------------------------------------------------------------------------------------

print_char:
                mov rsi, [rsp + 1 * 8]          ; pointer on line
                mov rdx, 1                      ; length of the line

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:          r10 - number to print
;       Destroys:       rsi
;                       rcx
;                        bx
;------------------------------------------------------------------------------------------------------------------------------------------

print_binary:
                mov rsi, rsp
                sub rsi, 20

                mov rdx, 1
                mov rax, 0x01           ; syscall arguments to print 1 char
                mov rdi, 1

                mov rcx, 64

.next_symb:
                xor bx, bx
                shl r10, 1
                adc bx, 0
                add bx, '0'
                mov [rsp - 20], bx      ; save char before stack

                push rcx
                syscall                 ; print char
                pop rcx

                loop .next_symb

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print hex number.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  rbx - number to print
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_hex:
                mov rcx, 16
                xor rax, rax
.print_number:
                mov al, bl
                shr rbx, 4

                call print_hex_number
                cmp rbx, 0
                jne .print_number

                call print_hex_number_buf

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print hexadecimal number
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  al - number to print
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_hex_number:
                and al, 0xF
                add al, '0'             ; UTF-8 offset
                cmp al, '9'             ; nedd to write A-F?
                jle .skip_letter
                add al, 7               ; write letter
.skip_letter:
                mov byte [HEX_NUMBER_BUF + rcx], al
                dec rcx

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print hexadecimal number in buffer
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  rcx
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_hex_number_buf:

                mov rsi, HEX_NUMBER_BUF                 ; buffer offset
                add rsi, rcx
                inc rsi

                mov rdx, 16                             ; calculate length of the line
                sub rdx, rcx

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry: rax - number to print
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_sign_decimal:
                test rax, rax                   ; need - before?
                jns .has_no_sign

                mov bl, '-'

                push rsi
                push rdx
                push rdi
                push rax

                push rcx
                mov rcx, rsp
                sub rcx, 20

                mov byte [rsp - 20], bl         ; put char to print before stack
                push rcx

                call print_char                 ; print - before number

                add rsp, 8
                pop rcx
                pop rax
                pop rdi
                pop rdx
                pop rsi

.has_no_sign:
                call print_unsign_decimal

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Prints unsigned decimal number.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry: rax
;       Destroys: rcx
;                 rdx
;                 rdi
;------------------------------------------------------------------------------------------------------------------------------------------

print_unsign_decimal:

                mov rdi, 10             ; base of notation
                ; xor rcx, rcx
                mov rcx, 20

.next_number:
                xor rdx, rdx

                div rdi

                add dl, '0'

                mov byte [DECIMAL_NUMBER_BUF + rcx], dl         ; write number in buffer
                dec rcx

                cmp rax, 0
                jne .next_number

                call print_decimal_from_buf                     ; print decimal from buffer

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Prints decimal from buffer
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:          rcx - length of number
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_decimal_from_buf:

                mov rsi, DECIMAL_NUMBER_BUF             ; buffer offset
                add rsi, rcx
                inc rsi

                mov rdx, 20                             ; calculate length of the line
                sub rdx, rcx

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print octal number.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry: rbx - number to print
;       Destroys:       rax
;                       rsi
;                       rdx
;------------------------------------------------------------------------------------------------------------------------------------------

print_octo:
                mov rcx, 24
.print_number:
                mov al, bl
                shr rbx, 3

                and al, 7
                add al, '0'
                mov byte [OCTO_NUMBER_BUF + rcx], al
                dec rcx

                cmp rbx, 0
                jne .print_number

                call print_octo_number_buf

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print octodecimal number in buffer
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  rcx
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_octo_number_buf:

                mov rsi, OCTO_NUMBER_BUF                ; buffer offset
                add rsi, rcx
                inc rsi

                mov rdx, 24                             ; calculate length of the line
                sub rdx, rcx

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

section .data

ERROR_LINE: db "!Unknown specificator!", 0xA, 0
HEX_NUMBER_BUF:     db "________________"
DECIMAL_NUMBER_BUF: db "____________________"
OCTO_NUMBER_BUF:    db "________________________"
BINARY_NUMBER_BUF:  db  "________________________________________________________________"
