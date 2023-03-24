section .text

;-------------------------------------------------------------------------------------------------------------
;
;       Entry:
;       Destroys: rsi rdi rax rbx
;
;-------------------------------------------------------------------------------------------------------------

print_null_term_line:
                ; mov rsi, [rsp + 1 * 8]
                ; push rsi
                call get_line_len
                ; pop rsi

                mov rdx, rax
                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;-------------------------------------------------------------------------------------------------------------

get_line_len:
                ; mov rsi, [rsp + 1 * 8]
                xor rdi, rdi
                dec rdi
                xor rax, rax

                xor rbx, rbx
.count_char:
                inc rdi
                inc rax
                mov bh, byte [rsi + rdi]
                cmp byte [rsi + rdi], 0                 ; line_terminator
                jne .count_char

                ret

;-------------------------------------------------------------------------------------------------------------

print_n_symbs:

                mov rsi, [rsp + 1 * 8]          ; pointer on line
                mov rdx, [rsp + 2 * 8]          ; length of the line

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;-------------------------------------------------------------------------------------------------------------
; need n of arguments
; rdi - format line
; rsi - 1arg, rdx - 2arg, rcx - 3arg, r8 - 4arg, r9 - 5arg
; r14 as arg counter
print_format_line:
                xor r14, r14
                mov r15, rdx            ; save rdx
                mov r12, rcx
.print_symb:
                cmp byte [rdi], '%'
                jne .next_symb

                call push_next_printf_arg
                inc r14

                call printf_arg
                add rsp, 8                      ; delete argument from push_next_printf_arg

                jmp .print_symb
.next_symb:
                push rsi
                push rdx
                push rdi
                call print_char
                pop rdi
                pop rdx
                pop rsi

                inc rdi

                cmp byte [rdi], 0
                jne .print_symb

                ret

; %s %d %x %c %o %b
printf_arg:
                inc rdi
                cmp byte [rdi], 'x'
                ja .L1

                xor rax, rax
                mov al, byte [rdi]
                sub al, 'b'

                mov rax, qword .L4[rax * 8]
                jmp rax

.L4:
        dq   .L2 ; = b
        dq   .L5 ; = c
        dq   .L7 ; = d
        dq   .L1 ; e
        dq   .L1 ; f
        dq   .L1 ; g
        dq   .L1 ; h
        dq   .L1 ; i
        dq   .L1 ; j
        dq   .L1 ; k
        dq   .L1 ; l
        dq   .L1 ; m
        dq   .L1 ; n
        dq   .L3 ; = o
        dq   .L1 ; p
        dq   .L1 ; q
        dq   .L1 ; r
        dq   .L8 ; = s
        dq   .L1 ; t
        dq   .L1 ; u
        dq   .L1 ; v
        dq   .L1 ; w
        dq   .L6 ; = x
        dq   .L1 ; y
        dq   .L1 ; z

.L8:
                mov rsi, qword [rsp + 1 * 8]
                push rdi
                call print_null_term_line
                pop rdi
                jmp .L9
.L7:
                ; call print_dec
                jmp .L9
.L6:
                ; call print_hex
                jmp .L9
.L5:
                push qword [rsp + 1 * 8]
                call print_char
                add rsp, 8
                jmp .L9
.L3:
                ; call print_octa
                jmp .L9
.L2:
                mov r10, qword [rsp + 1 * 8]
                push rsi
                push rdi
                call print_binary
                pop rdi
                pop rsi
                jmp .L9
.L1:
                push ERROR_LINE
                call print_null_term_line
                add rsp, 8
.L9:
                inc rdi
                ret

;----------------------------------------------------------------------------------------------------------------------
; Entry: r14 - number of argument
; add in stack argument for printf_arg funtion.
push_next_printf_arg:

                pop rax                         ; return adress from push_next_printf_arg

                cmp r14, 6
                jae .ARG_IN_STK

                mov rbx, qword [.ARG_OFFSET + r14 * 8]
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
                pop rbx                         ; return adress from print_format_line
                pop r13
                push rbx
                push r13
.RETURN:
                push rax
                ret


;----------------------------------------------------------------------------------------------------------------------
; destroys: rsi, rdx, rdi
print_char:
                mov rsi, [rsp + 1 * 8]          ; pointer on line
                mov rdx, 1                      ; length of the line

                mov rax, 0x01
                mov rdi, 1
                syscall

                ret

;----------------------------------------------------------------------------------------------------------------------
; entry: r10
print_binary:
                mov rsi, rsp       ; 4(just for safe) + 8
                add rsi, 20

                mov rdx, 1
                mov rax, 0x01
                mov rdi, 1

                mov rcx, 64

.next_symb:
                xor bx, bx
                shl r10, 1
                adc bx, 0
                add bx, '0'
                mov [rsp + 20], bx

                push rcx
                syscall
                pop rcx

                loop .next_symb

                ret
;-------------------------------------------------------------------------------------------------------------------------------------

section .data

ERROR_LINE: db "!Unknown specificator!", 0xA, 0
CHAR_BUF: db "1"

; line_terminator = '\0'

