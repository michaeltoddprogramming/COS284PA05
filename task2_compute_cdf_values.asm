; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

section .bss
    histogram resb 256
    cumulativeHistogram resd 256
    totalPixels resd 1
    cdfMin resd 1

section .text
    extern pixel_head          ; Declare pixel_head as external
    global computeCDFValues

computeCDFValues:
    ; Function prologue
    push rbp
    mov rbp, rsp

    ; Initialize histogram
    xor rdi, rdi
    mov rcx, 256
.fill_histogram:
    mov byte [histogram + rdi], 0
    inc rdi
    loop .fill_histogram

    ; First pass to compute the histogram
    ; Traverse linked list and calculate grayscale intensity
    ; grayscale = 0.299 * R + 0.587 * G + 0.114 * B
    ; Update histogram array and count total pixels
    mov rdi, [pixel_head]      ; Use pixel_head, now declared as external
    xor rbx, rbx               ; Total pixel count

.traverse_pixels:
    ; Check if rdi is NULL (end of list)
    test rdi, rdi
    jz .histogram_done

    ; Load RGB values
    movzx rax, byte [rdi + 0]  ; Red
    movzx rbx, byte [rdi + 1]  ; Green
    movzx rcx, byte [rdi + 2]  ; Blue

    ; Calculate grayscale using luminosity method
    ; gray = 0.299 * rax + 0.587 * rbx + 0.114 * rcx
    ; Update histogram[gray]

    ; Advance to the next pixel in linked list
    mov rdi, [rdi + 16]        ; Assuming right pointer is offset 16
    jmp .traverse_pixels

.histogram_done:
    ; Compute the cumulative histogram
    xor rdi, rdi
    xor rbx, rbx
    mov rcx, 256
.cdf_loop:
    movzx rax, byte [histogram + rdi]
    add rbx, rax
    mov [cumulativeHistogram + rdi * 4], rbx
    inc rdi
    loop .cdf_loop

    ; Normalize CDF and update PixelNodes' CdfValue
    ; Find cdfMin (minimum non-zero value)
    ; Traverse linked list again to update each pixel's CdfValue

    ; Function epilogue
    mov rsp, rbp
    pop rbp
    ret