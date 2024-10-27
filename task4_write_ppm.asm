; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

section .data
    write_error_msg db "Error writing PPM file.", 0

section .bss
    ; Add any necessary uninitialized data here

section .text
    extern open, write, close  ; Declare open, write, and close as external
    extern pixel_head          ; Declare pixel_head as external
    global writePPM

writePPM:
    ; Function prologue
    push rbp
    mov rbp, rsp

    ; Open the output file in binary write mode
    mov rdi, rsi               ; Output filename from parameter
    mov rsi, 1                 ; O_WRONLY (write-only mode)
    call open
    test rax, rax
    js error                   ; If open failed, jump to error
    mov rdi, rax               ; File descriptor

    ; Write PPM header (P6 width height maxColorValue)
    ; Implement header writing logic here

    ; Iterate over linked list and write RGB values row by row
    ; Implement pixel data writing logic here

    ; Close the file
    mov rdi, rax               ; File descriptor
    call close

    ; Function epilogue
    mov rsp, rbp
    pop rbp
    ret

error:
    ; Error handling
    mov rdi, write_error_msg
    call print_error
    xor rax, rax
    ret

print_error:
    ; Use the write system call to print the error message to stderr
    mov rax, 1                 ; syscall: write
    mov rdi, 2                 ; file descriptor: stderr
    mov rsi, rdi               ; error message to print
    mov rdx, 30                ; length of the message (adjust as needed)
    syscall
    ret