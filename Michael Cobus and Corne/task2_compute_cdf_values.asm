; ==========================
; GROUP MEMBER 01: MICHAEL TODD U23540223
; GROUP MEMBER 02: CORNE DE LANGE U23788862
; GROUP MEMBER 03: COBUS BOTHA U23556502
; ==========================

section .data
    ; CONSTANTS FOR GRAYSCALE CALCULATION
    red   dd 0.299    
    green dd 0.587
    blue  dd 0.114
    limit_clamp dd 255.0
    null dd 0.0

section .bss
    histo resd 256    ; HISTOGRAM ARRAY FOR 256 VALUES
    cdf resd 256      ; CUMULATIVE DISTRIBUTION FUNCTION ARRAY

section .text
    global computeCDFValues

computeCDFValues:
    push rbp
    mov rbp, rsp
    ; SAVE REGISTERS
    push rbx                
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi            ; STORE HEAD POINTER
    xor r13, r13            ; INITIALIZE TOTAL PIXELS TO 0
    mov rdi, histo
    mov rcx, 256
    xor eax, eax
    rep stosd               ; CLEAR HISTOGRAM ARRAY
    mov rdi, r12            ; RESTORE HEAD POINTER

; BUILD HISTOGRAM
step_1_first_pass:
    test rdi, rdi           ; CHECK IF HEAD IS NULL
    jz compute_cdf          ; IF NULL, JUMP TO COMPUTE_CDF

    mov rbx, rdi            ; SET CURRENT PIXEL TO CURRENT ROW

encounter_pixel_on_first_pass:
    test rbx, rbx           ; CHECK IF CURRENT PIXEL IS NULL
    jz next_row_on_first_pass

    ; COMPUTE GRAYSCALE VALUE
    xorps xmm0, xmm0

    movzx eax, byte [rbx]   ; LOAD RED COMPONENT
    cvtsi2ss xmm1, eax
    mulss xmm1, [red]
    addss xmm0, xmm1
    
    movzx eax, byte [rbx + 1] ; LOAD GREEN COMPONENT
    cvtsi2ss xmm1, eax
    mulss xmm1, [green]
    addss xmm0, xmm1
    
    movzx eax, byte [rbx + 2] ; LOAD BLUE COMPONENT
    cvtsi2ss xmm1, eax
    mulss xmm1, [blue]
    addss xmm0, xmm1
    
    cvttss2si eax, xmm0     ; CONVERT TO INTEGER

    mov byte [rbx + 3], al  ; STORE GRAYSCALE VALUE TEMPORARILY
    inc dword [histo + rax*4] ; UPDATE HISTOGRAM
    inc r13                 ; INCREMENT TOTAL PIXELS
    mov rbx, [rbx + 32]     ; MOVE TO NEXT PIXEL USING RIGHT POINTER
    jmp encounter_pixel_on_first_pass
    
next_row_on_first_pass:
    mov rdi, [rdi + 16]     ; MOVE TO NEXT ROW USING DOWN POINTER
    jmp step_1_first_pass
    
compute_cdf:
    xor rcx, rcx            ; INITIALIZE INDEX TO 0
    xor rdx, rdx            ; INITIALIZE CDF TO 0
    mov r14d, -1            ; SET CDFMIN TO MAX_INT

cdf_loop:
    mov eax, [histo + rcx*4]
    add edx, eax            ; CDF += HISTO[INDEX]
    mov [cdf + rcx*4], edx

    test eax, eax           ; CHECK IF HISTO[INDEX] > 0
    jz skip_min
    cmp edx, r14d
    jae skip_min
    mov r14d, edx           ; UPDATE CDFMIN
    
skip_min:
    inc rcx
    cmp rcx, 256
    jl cdf_loop
    mov rdi, r12            ; RESTORE HEAD POINTER
    
step_2_second_pass:         ; NORMALIZE CDF VALUES
    test rdi, rdi
    jz return
    mov rbx, rdi            ; SET CURRENT PIXEL TO CURRENT ROW
    
pass_pixel_on_2:
    test rbx, rbx
    jz next_row_on_second_pass
    movzx ecx, byte [rbx + 3] ; LOAD ORIGINAL GRAYSCALE VALUE
    mov eax, [cdf + rcx*4]  ; CALCULATE NORMALIZED VALUE
    sub eax, r14d           ; NUMERATOR: CDF[INDEX] - CDFMIN
    
    cvtsi2ss xmm0, eax      ; CONVERT TO FLOAT
    mov eax, r13d
    sub eax, r14d           ; DENOMINATOR: TOTALPIXELS - CDFMIN
    cvtsi2ss xmm1, eax

    divss xmm0, xmm1        ; PERFORM DIVISION
    mulss xmm0, [limit_clamp]

    maxss xmm0, [null]      ; CLAMP RESULTS
    minss xmm0, [limit_clamp]
    
    cvttss2si eax, xmm0     ; CONVERT BACK TO INTEGER
    mov byte [rbx + 3], al
    mov rbx, [rbx + 32]     ; MOVE TO NEXT PIXEL
    jmp pass_pixel_on_2
    
next_row_on_second_pass:
    mov rdi, [rdi + 16]
    jmp step_2_second_pass
    
return:
    ; RESTORE REGISTERS
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret