; ==========================
; GROUP MEMBER 01: MICHAEL TODD U23540223
; GROUP MEMBER 02: CORNE DE LANGE U23788862
; GROUP MEMBER 03: COBUS BOTHA U23556502
; ==========================

section .data
    p6_header db "P6", 10          ; P6 HEADER FOR PPM FILE
    maxval db "255", 10            ; MAX COLOR VALUE
    space db " "                   ; SPACE CHARACTER
    newline db 10                  ; NEWLINE CHARACTER
    err_msg db "ERROR OPENING FILE", 10 ; ERROR MESSAGE
    err_len equ $ - err_msg        ; LENGTH OF ERROR MESSAGE

section .bss
    number_buffer resb 20          ; BUFFER FOR NUMBER CONVERSION

section .text
global writePPM
extern printf    ; FOR DEBUGGING

; SYSTEM CALLS
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_WRITE equ 1
SYS_EXIT equ 60

; FILE OPEN FLAGS
O_WRONLY equ 1
O_CREAT equ 64
O_TRUNC equ 512

; FILE PERMISSIONS
MODE equ 0644o                     ; -RW-R--R--

writePPM:
    push rbp
    mov rbp, rsp
 
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48

    mov [rbp-8], rdi              ; FILENAME
    mov [rbp-16], rsi             ; HEAD POINTER

    ; CALCULATE WIDTH BY COUNTING NODES IN THE FIRST ROW
    xor r14, r14                  ; WIDTH = 0
    mov r12, [rbp-16]             ; CURRENT = HEAD
.count_width:
    test r12, r12
    jz .width_done
    inc r14                       ; INCREMENT WIDTH
    mov r12, [r12+32]             ; CURRENT = CURRENT->RIGHT
    jmp .count_width
.width_done:
    mov [rbp-32], r14             ; SAVE WIDTH

    ; CALCULATE HEIGHT BY COUNTING NODES IN THE FIRST COLUMN
    xor r15, r15                  ; HEIGHT = 0
    mov r12, [rbp-16]             ; CURRENT = HEAD
.count_height:
    test r12, r12
    jz .height_done
    inc r15                       ; INCREMENT HEIGHT
    mov r12, [r12+16]             ; CURRENT = CURRENT->DOWN
    jmp .count_height
.height_done:
    mov [rbp-40], r15             ; SAVE HEIGHT

    ; OPEN FILE
    mov rax, SYS_OPEN
    mov rdi, [rbp-8]              ; FILENAME
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, MODE
    syscall
    
    test rax, rax
    js .error_exit                ; JUMP IF SIGN FLAG IS SET (NEGATIVE RESULT)
    mov [rbp-24], rax             ; SAVE FILE DESCRIPTOR

    ; WRITE P6 HEADER
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, p6_header
    mov rdx, 3
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE WIDTH
    mov rdi, r14                  ; WIDTH
    mov rsi, number_buffer
    call number_to_ascii
    mov rdx, rax                  ; LENGTH OF NUMBER STRING
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, number_buffer
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE SPACE
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, space
    mov rdx, 1
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE HEIGHT
    mov rdi, r15                  ; HEIGHT
    mov rsi, number_buffer
    call number_to_ascii
    mov rdx, rax                  ; LENGTH OF NUMBER STRING
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, number_buffer
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE NEWLINE
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, newline
    mov rdx, 1
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE MAX COLOR VALUE
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, maxval
    mov rdx, 4
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    ; WRITE PIXEL DATA
    mov r12, [rbp-16]            ; CURRENT ROW = HEAD
.row_loop:
    test r12, r12
    jz .write_done
   
    mov r13, r12                 ; CURRENT PIXEL = CURRENT ROW

.pixel_loop:
    test r13, r13
    jz .next_row

    ; WRITE RGB VALUES (EACH IS 1 BYTE)
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]            ; FILE DESCRIPTOR
    mov rsi, r13                 ; ADDRESS OF RGB VALUES (RED, GREEN, BLUE)
    mov rdx, 3                   ; WRITE 3 BYTES (R, G, B)
    syscall
    test rax, rax
    js .error_exit                ; CHECK FOR WRITE ERROR

    mov r13, [r13+32]            ; CURRENT PIXEL = CURRENT PIXEL->RIGHT
    jmp .pixel_loop

.next_row:
    mov r12, [r12+16]            ; CURRENT ROW = CURRENT ROW->DOWN
    jmp .row_loop

.write_done:
    ; CLOSE FILE
    mov rax, SYS_CLOSE
    mov rdi, [rbp-24]            ; FILE DESCRIPTOR
    syscall
    xor eax, eax                 ; RETURN SUCCESS
    jmp .end

.error_exit:
    ; PRINT ERROR MESSAGE TO STDERR (FILE DESCRIPTOR 2)
    mov rax, SYS_WRITE
    mov rdi, 2                   ; STDERR
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    
    mov eax, 1                   ; RETURN ERROR CODE

.end:
    ; RESTORE REGISTERS
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; CONVERT NUMBER TO ASCII IN THE BUFFER
number_to_ascii:
    push rbp
    mov rbp, rsp
    mov rax, rdi                ; NUMBER TO CONVERT
    mov rdi, rsi                ; BUFFER TO WRITE TO
    mov rcx, 0                  ; DIGIT COUNT
    mov r8, 10                  ; DIVISOR
    
    ; SPECIAL CASE FOR ZERO
    test rax, rax
    jnz .convert_loop
    mov byte [rdi], '0'
    mov rax, 1
    jmp .done

.convert_loop:
    test rax, rax
    jz .reverse
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rdi + rcx], dl
    inc rcx
    jmp .convert_loop

.reverse:
    mov rax, rcx               ; SAVE LENGTH
    mov r9, rcx
    shr rcx, 1                 ; DIVIDE BY 2
    dec r9                     ; LAST INDEX
    xor r8, r8                 ; FIRST INDEX

.reverse_loop:
    test rcx, rcx
    jz .done
    mov dl, [rdi + r8]
    mov bl, [rdi + r9]
    mov [rdi + r8], bl
    mov [rdi + r9], dl
    inc r8
    dec r9
    dec rcx
    jmp .reverse_loop

.done:
    leave
    ret