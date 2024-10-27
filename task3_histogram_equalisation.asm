; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

section .text
    extern pixel_head           ; Declare pixel_head as external
    global applyHistogramEqualization

applyHistogramEqualization:
    ; Function prologue
    push rbp
    mov rbp, rsp

    ; Traverse linked list
    ; Update RGB values based on the normalized CdfValue
    mov rdi, [pixel_head]       ; Use pixel_head, now declared as external

.apply_pixels:
    test rdi, rdi
    jz .done

    ; Get the normalized CdfValue
    movzx rax, byte [rdi + 3]   ; Assuming CdfValue is at offset 3

    ; Update all RGB values to the new grayscale value
    mov [rdi + 0], al
    mov [rdi + 1], al
    mov [rdi + 2], al

    ; Move to the next pixel
    mov rdi, [rdi + 16]         ; Right pointer offset
    jmp .apply_pixels

.done:
    ; Function epilogue
    mov rsp, rbp
    pop rbp
    ret