; ==========================
; GROUP MEMBER 01: MICHAEL TODD U23540223
; GROUP MEMBER 02: CORNE DE LANGE U23788862
; GROUP MEMBER 03: COBUS BOTHA U23556502
; ==========================

section .data
    align 8
    floatConstant: dq 1071644672   ; FLOAT CONSTANT FOR HISTOGRAM EQUALIZATION

section .text
    global clamp
    global applyHistogramEqualization

clamp:
    push    rbp
    mov     rbp, rsp
    ; STORE INPUT VALUE IN LOCAL VARIABLE
    mov     [rbp-4], edi
    ; CHECK IF VALUE IS GREATER THAN 255
    cmp     dword [rbp-4], 255
    jle     checkLowerBound
    ; IF GREATER THAN 255, SET TO 255
    mov     eax, -1
    jmp     returnClamp

checkLowerBound:
    ; CHECK IF VALUE IS LESS THAN 0
    cmp     dword [rbp-4], 0
    jns     returnInput
    ; IF LESS THAN 0, SET TO 0
    mov     eax, 0
    jmp     returnClamp

returnInput:
    ; RETURN INPUT VALUE
    mov     eax, [rbp-4]

returnClamp:
    pop     rbp
    ret

applyHistogramEqualization:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 40
    ; STORE INPUT POINTER IN LOCAL VARIABLE
    mov     [rbp-40], rdi
    ; CHECK IF INPUT POINTER IS NULL
    cmp     qword [rbp-40], 0
    je      handleNullInput
    ; SET CURRENT ROW POINTER
    mov     rax, [rbp-40]
    mov     [rbp-8], rax
    jmp     outerLoopStart

processNextRow:
    ; SET CURRENT PIXEL POINTER
    mov     rax, [rbp-8]
    mov     [rbp-16], rax
    jmp     innerLoopStart

processPixel:
    ; LOAD CDF VALUE FROM PIXEL
    mov     rax, [rbp-16]
    movzx   eax, byte [rax+3]
    movzx   eax, al
    ; CONVERT CDF VALUE TO FLOAT
    pxor    xmm0, xmm0
    cvtsi2ss xmm0, eax
    movss   [rbp-20], xmm0
    pxor    xmm1, xmm1
    cvtss2sd xmm1, [rbp-20]
    ; ADD FLOAT CONSTANT
    movsd   xmm0, [rel floatConstant]
    addsd   xmm0, xmm1
    ; CONVERT BACK TO INTEGER
    cvttsd2si eax, xmm0
    mov     [rbp-24], eax
    mov     eax, [rbp-24]
    ; CLAMP THE VALUE BETWEEN 0 AND 255
    mov     edi, eax
    call    clamp
    mov     [rbp-25], al
    ; SET RED, GREEN, AND BLUE COMPONENTS TO THE CLAMPED VALUE
    mov     rax, [rbp-16]
    movzx   edx, byte [rbp-25]
    mov     [rax], dl
    mov     rax, [rbp-16]
    movzx   edx, byte [rbp-25]
    mov     [rax+1], dl
    mov     rax, [rbp-16]
    movzx   edx, byte [rbp-25]
    mov     [rax+2], dl
    ; MOVE TO THE NEXT PIXEL USING THE RIGHT POINTER (OFFSET 32)
    mov     rax, [rbp-16]
    mov     rax, [rax+32]
    mov     [rbp-16], rax

innerLoopStart:
    ; CHECK IF CURRENT PIXEL POINTER IS NULL
    cmp     qword [rbp-16], 0
    jne     processPixel
    ; MOVE TO THE NEXT ROW USING THE DOWN POINTER (OFFSET 16)
    mov     rax, [rbp-8]
    mov     rax, [rax+16]
    mov     [rbp-8], rax

outerLoopStart:
    ; CHECK IF CURRENT ROW POINTER IS NULL
    cmp     qword [rbp-8], 0
    jne     processNextRow
    jmp     returnHistogram

handleNullInput:
    nop

returnHistogram:
    leave
    ret