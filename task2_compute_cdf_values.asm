; ==========================
; Group member 01: Michael Todd U23540223
; Group member 02: Corne de Lange u23788862
; Group member 03: Cobus Botha u23556502
; ==========================

section .data
    ;needed for calculations
    red   dd 0.299    
    green dd 0.587
    blue  dd 0.114
    limit_clamp      dd 255.0
    null         dd 0.0

section .bss
    histo    resd 256    ;see 1. in spec initialising array for histo[256]
    cdf   resd 256    ; then for the cummulative one
    
section .text
    global computeCDFValues

computeCDFValues:
    push rbp
    mov rbp, rsp
    ;then just save 
    push rbx                
    push r12
    push r13
    push r14
    push r15
    

    mov r12, rdi            ; here we store the head pointer
    xor r13, r13           ; initialising our TotalPixels to 0
    mov rdi, histo
    mov rcx, 256
    xor eax, eax
    rep stosd              ; have to make the histo zero/clear
    mov rdi, r12    ;restore the head pointer

;the first thing we will do is build our histogram
step_1_first_pass:
    test rdi, rdi          ; general check to see if our head is null
    jz compute_cdf          ;if it is we will exit i.e) jump to the compute_cdf function
    
    mov rbx, rdi           ; curr pixel = the row we currently in
    
encounter_pixel_on_first_pass:
    test rbx, rbx          ;generall check to see if the curr pixel is null
    jz next_row_on_first_pass
    
    ;we will now start to compute the grayscale
    xorps xmm0, xmm0

    movzx eax, byte [rbx]       ;so load the red component so we can process it 
    cvtsi2ss xmm1, eax
    mulss xmm1, [red]
    addss xmm0, xmm1
    
    movzx eax, byte [rbx + 1]     ;next the green
    cvtsi2ss xmm1, eax
    mulss xmm1, [green]
    addss xmm0, xmm1
    
    movzx eax, byte [rbx + 2]       ;then blue
    cvtsi2ss xmm1, eax
    mulss xmm1, [blue]
    addss xmm0, xmm1
    
    cvttss2si eax, xmm0     ;just converting back to int

    mov byte [rbx + 3], al  ;temporarily store the grayscale value inside the cdfvalue
    inc dword [histo + rax*4]       ;we then will update our histogram
    inc r13                         ; totalPixels++
    mov rbx, [rbx + 32]             ;then we will now move to the next pixel using the right pointer
    jmp encounter_pixel_on_first_pass
    
next_row_on_first_pass:
    mov rdi, [rdi + 16]             ;after that will then use the down pointer
    jmp step_1_first_pass
    
compute_cdf:
    xor rcx, rcx           ; i = 0
    xor rdx, rdx           ; cdf = 0
    mov r14d, -1           ; nb // cdfMin = MAX_INT

cdf_loop:
    mov eax, [histo + rcx*4]
    add edx, eax           ; cdf += histo[i]
    mov [cdf + rcx*4], edx

    test eax, eax          ;check  if histo[i] > 0
    jz skip_min
    cmp edx, r14d
    jae skip_min
    mov r14d, edx         ; update cdfMin
    
skip_min:
    inc rcx
    cmp rcx, 256
    jl cdf_loop
    mov rdi, r12           ; restore head pointer
    
step_2_second_pass:            ;normalising below
    test rdi, rdi
    jz return
    mov rbx, rdi           ; curr pixel = current row we in
    
pass_pixel_on_2:
    test rbx, rbx
    jz next_row_on_second_pass
    movzx ecx, byte [rbx + 3]   ;we need to load the origianl grayscale value now
    mov eax, [cdf + rcx*4]  ;next cal. the normalised value
    sub eax, r14d          ; the top of the function given(numerator) :  cdf[i] - cdfMin
    
    cvtsi2ss xmm0, eax      ;concerting to float
    mov eax, r13d
    sub eax, r14d          ; then denominator : totalPixels - cdfMin
    cvtsi2ss xmm1, eax
    

    divss xmm0, xmm1        ;perform operation
    mulss xmm0, [limit_clamp]

    maxss xmm0, [null]      ;we have to clamp our results
    minss xmm0, [limit_clamp]
    
    cvttss2si eax, xmm0         ;converting back to int
    mov byte [rbx + 3], al
    mov rbx, [rbx + 32]     ;next pixel
    jmp pass_pixel_on_2
    
next_row_on_second_pass:
    mov rdi, [rdi + 16]
    jmp step_2_second_pass
    
return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret
    