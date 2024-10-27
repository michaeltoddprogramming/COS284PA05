; ==========================
; Group member 01: Michael Todd U23540223
; Group member 02: Corne de Lange u23788862
; Group member 03: Cobus Botha u23556502
; ==========================

section .data
    p6_header db "P6", 10          
    maxval db "255", 10           
    space db " "                   
    newline db 10                  
    err_msg db "Error opening file", 10
    err_len equ $ - err_msg

section .bss
    number_buffer resb 20          ;for number conversion

section .text
global writePPM
extern printf    ; For debugging

; System calls
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_WRITE equ 1
SYS_EXIT equ 60

; File open flags
O_WRONLY equ 1
O_CREAT equ 64
O_TRUNC equ 512

; File permissions
MODE equ 0644o                     ; -rw-r--r--

writePPM:
    push rbp
    mov rbp, rsp
 
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48


    mov [rbp-8], rdi              ; filename
    mov [rbp-16], rsi             ; head pointer

    ; have to calculate width by counting the number of nodes in the first row
    xor r14, r14                  ; width = 0
    mov r12, [rbp-16]             ; current = head
.count_width:
    test r12, r12
    jz .width_done
    inc r14                       ; increment width
    mov r12, [r12+32]             ; curr = curr->right
    jmp .count_width
.width_done:
    mov [rbp-32], r14             ; save width

    ; after have to calculate height by counting the number of nodes in the first column
    xor r15, r15                  ; height = 0
    mov r12, [rbp-16]             ; current = head
.count_height:
    test r12, r12
    jz .height_done
    inc r15                       ; increment height
    mov r12, [r12+16]             ; curr = curr->down
    jmp .count_height
.height_done:
    mov [rbp-40], r15             ; save height

    ; Open file
    mov rax, SYS_OPEN
    mov rdi, [rbp-8]              ; filename
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, MODE
    syscall
    
    test rax, rax
    js .error_exit                ; Jump if sign flag is set (negative result)
    mov [rbp-24], rax             ; save file descriptor

  
    mov rax, SYS_WRITE                ; write P6 header
    mov rdi, [rbp-24]
    mov rsi, p6_header
    mov rdx, 3
    syscall

        ; write width
    mov rdi, r14                  ; width
    mov rsi, number_buffer
    call number_to_ascii
    mov rdx, rax                  ; length of number string
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, number_buffer
    syscall

    ; write space
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, space
    mov rdx, 1
    syscall

    ; write height
    mov rdi, r15                  ; height
    mov rsi, number_buffer
    call number_to_ascii
    mov rdx, rax                  ; length of number string
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, number_buffer
    syscall

    ; write newline
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, newline
    mov rdx, 1
    syscall

    ; write max color value
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]
    mov rsi, maxval
    mov rdx, 4
    syscall

    ; write pixel data
    mov r12, [rbp-16]            ; currRow = head
.row_loop:
    test r12, r12
    jz .write_done
   
    mov r13, r12                 ; currPixel = currRow

.pixel_loop:
    test r13, r13
    jz .next_row

    ; write RGB values each is 1byte
    mov rax, SYS_WRITE
    mov rdi, [rbp-24]            ; file descriptor
    mov rsi, r13                 ; address of RGB values (Red, Green, Blue)
    mov rdx, 3                   ; write 3 bytes (R, G, B)
    syscall

    mov r13, [r13+32]            ; currPixel = currPixel->right
    jmp .pixel_loop

.next_row:
    mov r12, [r12+16]            ; currRow = currRow->down
    jmp .row_loop

.write_done:
    ; Close file
    mov rax, SYS_CLOSE
    mov rdi, [rbp-24]            ; file descriptor
    syscall
    xor eax, eax                 ; return if success
    jmp .end

.error_exit:
    ; print error message to stderr (file descriptor 2)
    mov rax, SYS_WRITE
    mov rdi, 2                   ; stderr
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    
    mov eax, 1                   ; return error code

.end:
    ; restore registers
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; have to convert number to ASCII in the buffer
number_to_ascii:
    push rbp
    mov rbp, rsp
    mov rax, rdi                ; number to convert
    mov rdi, rsi                ; buffer to write to
    mov rcx, 0                  ; digit count
    mov r8, 10                  ; divisor
    
    ; error handling for zero specially
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
    mov rax, rcx               ; save length
    mov r9, rcx
    shr rcx, 1                 ; divide by 2
    dec r9                     ; last index
    xor r8, r8                 ; first index

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