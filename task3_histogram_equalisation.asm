; ==========================
; GROUP MEMBER 01: MICHAEL TODD U23540223
; GROUP MEMBER 02: CORNE DE LANGE U23788862
; GROUP MEMBER 03: COBUS BOTHA U23556502
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
    mov rsi, rdi       ; SET RSI TO POINT TO THE HEAD OF THE PIXEL LIST

outer_loop:
    test rsi, rsi      ; CHECK IF THE CURRENT ROW POINTER IS NULL
    jz done_outer      ; IF NULL, EXIT OUTER LOOP

    mov rbx, rsi       ; SET RBX TO POINT TO THE CURRENT PIXEL (CURRENT ROW)

inner_loop:
    test rbx, rbx      ; CHECK IF THE CURRENT PIXEL POINTER IS NULL
    jz done_inner      ; IF NULL, EXIT INNER LOOP

    movzx eax, byte [rbx + 3]    ; LOAD CDF VALUE FROM PIXEL
    cvtsi2ss xmm0, eax           ; CONVERT CDF VALUE TO FLOAT FOR ROUNDING
    addss xmm0, dword [half]     ; ADD 0.5 FOR ROUNDING
    cvttss2si eax, xmm0          ; CONVERT BACK TO INTEGER WITH TRUNCATION
    
    ; CLAMP THE VALUE BETWEEN 0 AND 255
    cmp eax, 0
    cmovl eax, dword [rel zero]  
    cmp eax, 255
    cmovg eax, dword [rel max_val] 
    
    ; SET RED, GREEN, AND BLUE COMPONENTS TO THE CLAMPED VALUE
    mov byte [rbx], al           ; RED
    mov byte [rbx + 1], al       ; GREEN
    mov byte [rbx + 2], al       ; BLUE
    
    ; MOVE TO THE NEXT PIXEL USING THE RIGHT POINTER (OFFSET 32)
    mov rbx, [rbx + 32]
    jmp inner_loop

done_inner:
    ; MOVE TO THE NEXT ROW USING THE DOWN POINTER (OFFSET 16)
    mov rsi, [rsi + 16]
    jmp outer_loop

done_outer:
    pop rsi
    pop rdi
    pop rbx
    mov rsp, rbp
    pop rbp
    ret