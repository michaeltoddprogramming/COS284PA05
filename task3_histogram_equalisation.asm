; ==========================
; Group member 01: Michael Todd U23540223
; Group member 02: Corne de Lange u23788862
; Group member 03: Cobus Botha u23556502
; ==========================

section .data
    half dd 0.5         
    zero dd 0             
    max_val db 255        

section .text
    global applyHistogramEqualization


applyHistogramEqualization:
    push rbp
    mov rbp, rsp
    push rbx
    push rdi
    push rsi
    mov rsi, rdi       

outer_loop:
    test rsi, rsi         
    jz done_outer

    mov rbx, rsi          ; rbx = currentPixel = currentRow

inner_loop:
    test rbx, rbx        
    jz done_inner

    movzx eax, byte [rbx + 3]    ;loading cdf value    
    cvtsi2ss xmm0, eax           ; cdfvalue must be taken to float for rounding section in c code
    addss xmm0, dword [half]     ; Add 0.5 for rounding
    cvttss2si eax, xmm0          ; set back to an integer with truncation
    
    ; begining of the if statement in c code for clamping
    cmp eax, 0
    cmovl eax, dword [rel zero]  
    cmp eax, 255
    cmovg eax, dword [rel max_val] 
    
    mov byte [rbx], al           ; Red
    mov byte [rbx + 1], al       ; Green
    mov byte [rbx + 2], al       ; Blue
    ; pixel = right pointer which is at an offset of 32
    mov rbx, [rbx + 32]
    jmp inner_loop

done_inner:
    ;down pointer is at offset 16 hence we move to it
    mov rsi, [rsi + 16]
    jmp outer_loop

done_outer:
    pop rsi
    pop rdi
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
    