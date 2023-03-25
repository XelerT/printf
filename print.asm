section .text

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
                mov rax, 0x01                           ; use write funtion
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
                cmp byte [rsi + rdi], 0                 ; check line_terminator
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

print_format_line:
                xor r14, r14
                mov r15, rdx            ; save rdx
                mov r12, rcx            ; save rcx
.print_symb:
                cmp byte [rdi], '%'             ; check %
                jne .next_symb

                call push_next_printf_arg       ; put next argument to printf in stack
                inc r14                         ; increases argument counter

                call printf_arg                 ; choose format of argument and print it
                add rsp, 8                      ; delete argument from push_next_printf_arg

                jmp .print_symb
.next_symb:
                push rsi                        ;\
                push rdx                        ;       save registers
                push rdi                        ;/
                call print_char
                pop rdi                         ;\
                pop rdx                         ;       restore registers
                pop rsi                         ;/

                inc rdi                         ; next symbol in format line

                cmp byte [rdi], 0
                jne .print_symb

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print argument. Uses switch to choose format function.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:          rdi - pointer on the line
;       Destroys:       rdi
;                       rax
;                       rcx
;
;------------------------------------------------------------------------------------------------------------------------------------------

printf_arg:
                inc rdi
                cmp byte [rdi], 'x'
                ja .error

                xor rax, rax                                    ;\
                mov al, byte [rdi]                              ;       2 identical lines because 1 is not compiling
                mov al, byte [rdi]                              ;       calculate place in jump table
                sub al, 'b'                                     ;/

                mov rax, qword .JMP_TABLE[rax * 8]
                jmp rax
.JMP_TABLE:
        dq   .binary   ; = b
        dq   .char     ; = c
        dq   .decimal  ; = d
        dq   .error    ; e
        dq   .error    ; f
        dq   .error    ; g
        dq   .error    ; h
        dq   .error    ; i
        dq   .error    ; j
        dq   .error    ; k
        dq   .error    ; l
        dq   .error    ; m
        dq   .error    ; n
        dq   .octal    ; = o
        dq   .error    ; p
        dq   .error    ; q
        dq   .error    ; r
        dq   .string   ; = s
        dq   .error    ; t
        dq   .error    ; u
        dq   .error    ; v
        dq   .error    ; w
        dq   .hex      ; = x
        dq   .error    ; y
        dq   .error    ; z

.string:
                mov rsi, qword [rsp + 1 * 8]                    ; get argument

                push rdi

                call print_null_term_line

                pop rdi
                jmp .break
.decimal:
                mov rax, qword [rsp + 1 * 8]                     ; get argument

                push rsi
                push rdi
                push rdx

                call print_sign_decimal                          ; get argument

                pop rdx
                pop rdi
                pop rsi

                jmp .break
.hex:
                mov rbx, qword [rsp + 1 * 8]                     ; get argument
                push rsi
                push rdi
                push rdx

                call print_hex

                pop rdx
                pop rdi
                pop rsi

                jmp .break
.char:
                push qword [rsp + 1 * 8]                        ; get argument
                call print_char
                add rsp, 8
                jmp .break
.octal:
                mov rbx, qword [rsp + 1 * 8]                    ; get argument
                push rsi
                push rdi
                push rdx

                call print_octo

                pop rdx
                pop rdi
                pop rsi
                jmp .break
.binary:
                mov r10, qword [rsp + 1 * 8]                    ; get argument
                push rsi
                push rdi

                call print_binary

                pop rdi
                pop rsi
                jmp .break
.error:
                push ERROR_LINE
                call print_null_term_line                       ; print error line
                add rsp, 8
.break:
                inc rdi
                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;               Pushes printf argument in stack if it's in registers. If argument is in stack, it will change it's position
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
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  Print char in terminal.
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
                mov rax, rbx
                shl rbx, 4
                shr rax, 60                     ; get 4 hight bits

                call print_hex_number
                cmp rbx, 0
                jne print_hex

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print hexadecimal number
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  al - number to print
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_hex_number:
                add al, '0'             ; UTF-8 offset
                cmp al, '9'             ; nedd to write A-F?
                jle .skip_letter
                add al, 7               ; write letter
.skip_letter:
                push rcx
                mov rcx, rsp
                sub rcx, 20

                mov byte [rsp - 20], al         ; add char to print before stack
                push rcx                        ; rcx - pointer on the char to print

                call print_char

                add rsp, 8
                pop rcx

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
                xor rcx, rcx
.next_number:
                xor rdx, rdx

                div rdi

                add dl, '0'

                mov byte [DECIMAL_NUMBER_BUF + rcx], dl         ; write number in buffer
                inc rcx

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

                dec rcx
                mov rsi, DECIMAL_NUMBER_BUF             ; buffer offset
.print_number:
                push rsi
                push rax
                push rdi
                push rcx

                add rsi, rcx
                push rsi

                call print_char
                add rsp, 8

                pop rcx
                pop rdi
                pop rax
                pop rsi

                dec rcx

                cmp rcx, 0
                jnl .print_number

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
                mov rax, rbx
                shl rbx, 3
                shr rax, 61                         ; get 3 hight bits

                call print_octo_digit

                cmp rbx, 0
                jne print_octo

                ret

;------------------------------------------------------------------------------------------------------------------------------------------
;       Print octal digit.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;       Entry:  al - number to print
;       Destroys:
;------------------------------------------------------------------------------------------------------------------------------------------

print_octo_digit:
                add al, '0'

                push rcx
                mov rcx, rsp
                sub rcx, 20

                mov byte [rsp - 20], al         ; write char before stack
                push rcx

                call print_char

                add rsp, 8
                pop rcx

                ret

section .data

ERROR_LINE: db "!Unknown specificator!", 0xA, 0
DECIMAL_NUMBER_BUF: db "____________________"
