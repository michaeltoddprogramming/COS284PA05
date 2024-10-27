; ==========================
; GROUP MEMBER 01: MICHAEL TODD U23540223
; GROUP MEMBER 02: CORNE DE LANGE U23788862
; GROUP MEMBER 03: COBUS BOTHA U23556502
; ==========================


; READS BINARY P6 FORMAT PPM FILES AND CREATES A LINKED PIXEL STRUCTURE
; EACH PIXEL CONNECTS TO ADJACENT PIXELS (ABOVE, BELOW, LEFT, RIGHT)

; EXTERNAL C LIBRARY FUNCTION DECLARATIONS
extern fgetc    ; READ SINGLE CHARACTER (USES RDI FOR FILE*)
extern ungetc   ; PUSH CHARACTER BACK (USES EDI FOR CHAR, RSI FOR FILE*)
extern fopen    ; OPEN FILE (USES RDI FOR FILENAME, RSI FOR MODE)
extern fscanf   ; READ FORMATTED INPUT (USES RDI FOR FILE*, RSI FOR FORMAT)
extern strcmp   ; COMPARE STRINGS (USES RDI AND RSI FOR STRINGS)
extern malloc   ; ALLOCATE MEMORY (USES RDI FOR SIZE)
extern fread    ; READ BINARY DATA (USES RDI, RSI, RDX, RCX)
extern free     ; FREE MEMORY (USES RDI FOR POINTER)
extern fclose   ; CLOSE FILE (USES RDI FOR FILE*)

section .data
    rb_mode     db "rb", 0       ; BINARY READ MODE FOR FOPEN
    fmt_str     db "%s", 10, 0   ; FORMAT FOR READING MAGIC NUMBER
    fmt_nums    db "%d %d", 10, "%d", 10, 0  ; FORMAT FOR DIMENSIONS AND MAX VALUE
    magic_p6    db "P6", 0       ; PPM P6 FORMAT IDENTIFIER

section .text
global skipComments
global readPPM

; FUNCTION: SKIPCOMMENTS
; PURPOSE: SKIPS COMMENT LINES (STARTING WITH #) IN PPM FILE
; PARAMETERS: RDI - FILE* POINTER TO OPEN PPM FILE
; LOCAL VARIABLES (STACK-BASED):
;   RBP-24: FILE* STORAGE
;   RBP-1:  CURRENT CHARACTER
skipComments:
    push    rbp                 ; SAVE OLD BASE POINTER
    mov     rbp, rsp            ; SET UP NEW STACK FRAME
    sub     rsp, 32             ; ALLOCATE 32 BYTES LOCAL STORAGE
    mov     [rbp-24], rdi       ; STORE FILE* FOR LATER USE

.read_char:                     ; LOOP TO READ CHARACTERS
    mov     rax, [rbp-24]       ; RAX = FILE*
    mov     rdi, rax            ; RDI = PARAMETER FOR FGETC
    call    fgetc               ; READ ONE CHARACTER
    mov     [rbp-1], al         ; STORE CHARACTER (AL = LOWER BYTE OF RAX)
    cmp     byte [rbp-1], 35    ; COMPARE WITH '#' (ASCII 35)
    je      .skip_comment_line
    movsx   eax, byte [rbp-1]   ; SIGN-EXTEND CHAR FOR UNGETC
    mov     rdx, [rbp-24]       
    mov     rsi, rdx            ; RSI = FILE* FOR UNGETC
    mov     edi, eax            ; EDI = CHARACTER TO PUSH BACK
    call    ungetc
    jmp     .skip_comments_end

.skip_comment_line:             
.read_until_newline:            
    mov     rax, [rbp-24]       
    mov     rdi, rax            ; RDI = FILE* FOR FGETC
    call    fgetc               
    mov     [rbp-1], al         ; STORE READ CHARACTER
    cmp     byte [rbp-1], 10    ; COMPARE WITH NEWLINE (ASCII 10)
    je      .read_char          
    cmp     byte [rbp-1], -1    ; COMPARE WITH EOF (-1)
    jne     .read_until_newline
    jmp     .read_char

.skip_comments_end:             
    leave                       ; RESTORE STACK FRAME
    ret

; FUNCTION: READPPM
; PURPOSE: READS PPM FILE AND BUILDS LINKED PIXEL STRUCTURE
; PARAMETERS: RDI - FILENAME STRING POINTER
; RETURNS: RAX - POINTER TO FIRST PIXEL OR NULL IF ERROR
; PIXEL STRUCTURE (40 BYTES):
;   BYTES 0-2:   RGB VALUES
;   BYTE 3:      PADDING
;   BYTES 4-11:  ABOVE PIXEL POINTER
;   BYTES 12-19: BELOW PIXEL POINTER
;   BYTES 20-27: LEFT PIXEL POINTER
;   BYTES 28-35: RIGHT PIXEL POINTER
; LOCAL VARIABLES:
;   RBP-88: FILENAME
;   RBP-80: MAX COLOR VALUE
;   RBP-76: HEIGHT
;   RBP-72: WIDTH
;   RBP-67: MAGIC NUMBER BUFFER
;   RBP-64: CURRENT PIXEL
;   RBP-56: FIRST PIXEL
;   RBP-48: ROW POINTERS ARRAY
;   RBP-40: FILE POINTER
;   RBP-28: COLUMN COUNTER
;   RBP-24: PREVIOUS PIXEL
;   RBP-12: ROW COUNTER
;   RBP-8:  ABOVE PIXEL


readPPM:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 96             ; ALLOCATE LOCAL VARIABLES SPACE

    mov     [rbp-88], rdi       ; STORE FILENAME POINTER

    ; OPEN FILE IN BINARY READ MODE
    mov     rax, [rbp-88]       ; RAX = FILENAME
    mov     rsi, rb_mode        ; RSI = "RB"
    mov     rdi, rax            ; RDI = FILENAME FOR FOPEN
    call    fopen
    mov     [rbp-40], rax       ; STORE FILE*
    
    ; CHECK FILE OPEN SUCCESS
    cmp     qword [rbp-40], 0   ; COMPARE FILE* WITH NULL
    jne     .process_file
    xor     eax, eax            ; RETURN NULL IF OPEN FAILED
    jmp     .readPPM_end

.process_file:                  
    ; READ PPM MAGIC NUMBER
    lea     rdx, [rbp-67]       ; RDX = BUFFER FOR MAGIC NUMBER
    mov     rax, [rbp-40]       ; RAX = FILE*
    mov     rsi, fmt_str        ; RSI = FORMAT STRING
    mov     rdi, rax            ; RDI = FILE* FOR FSCANF
    xor     eax, eax            ; CLEAR AL (VARARGS COUNT)
    call    fscanf

    ; SKIP HEADER COMMENTS
    mov     rax, [rbp-40]       
    mov     rdi, rax            ; RDI = FILE* FOR SKIPCOMMENTS
    call    skipComments

    ; READ IMAGE DIMENSIONS AND MAX VALUE
    lea     rsi, [rbp-80]       ; MAX COLOR VALUE ADDRESS
    lea     rcx, [rbp-76]       ; HEIGHT ADDRESS
    lea     rdx, [rbp-72]       ; WIDTH ADDRESS
    mov     rax, [rbp-40]       ; FILE*
    mov     r8, rsi             ; R8 = MAX VALUE PTR FOR FSCANF
    mov     rsi, fmt_nums       ; RSI = FORMAT STRING
    mov     rdi, rax            ; RDI = FILE*
    xor     eax, eax            ; CLEAR AL (VARARGS COUNT)
    call    fscanf

    ; VERIFY PPM FORMAT
    lea     rax, [rbp-67]       ; MAGIC NUMBER BUFFER
    mov     rsi, magic_p6       ; "P6" STRING
    mov     rdi, rax            ; COMPARE PARAMETERS
    call    strcmp
    test    eax, eax            ; CHECK IF STRINGS MATCH
    jne     .close_invalid_file
    
    mov     eax, [rbp-80]       
    cmp     eax, 255            ; VERIFY MAX COLOR VALUE
    je      .process_valid_file

.close_invalid_file:           
    mov     rax, [rbp-40]       
    mov     rdi, rax            ; RDI = FILE* TO CLOSE
    call    fclose
    xor     eax, eax            ; RETURN NULL
    jmp     .readPPM_end

.process_valid_file:           
    ; ALLOCATE ROW POINTER ARRAY
    mov     eax, [rbp-76]       ; EAX = HEIGHT
    cdqe                        ; SIGN-EXTEND TO 64-BIT
    sal     rax, 3              ; MULTIPLY BY 8 (POINTER SIZE)
    mov     rdi, rax            ; RDI = SIZE FOR MALLOC
    call    malloc
    mov     [rbp-48], rax       ; STORE ROW POINTERS ARRAY

    mov     qword [rbp-56], 0   ; INITIALIZE FIRST PIXEL PTR
    mov     qword [rbp-8], 0    ; INITIALIZE ABOVE PIXEL PTR
    mov     dword [rbp-12], 0   ; INITIALIZE ROW COUNTER

.row_loop:
    mov     dword [rbp-28], 0   ; RESET COLUMN COUNTER
    mov     qword [rbp-24], 0   ; RESET PREVIOUS PIXEL PTR

.pixel_loop:
    ; ALLOCATE PIXEL STRUCTURE
    mov     edi, 40             ; 40 BYTES FOR PIXEL STRUCT
    call    malloc
    mov     [rbp-64], rax       ; STORE NEW PIXEL PTR

    ; READ RGB VALUES
    mov     rax, [rbp-64]       ; DESTINATION FOR RED
    mov     rdx, [rbp-40]       ; FILE*
    mov     rcx, rdx            ; RCX = FILE* FOR FREAD
    mov     edx, 1              ; READ 1 BYTE
    mov     esi, 1              ; READ 1 TIME
    mov     rdi, rax            ; RDI = DESTINATION
    call    fread               ; READ RED VALUE

    mov     rax, [rbp-64]
    lea     rdi, [rax+1]        ; DESTINATION FOR GREEN
    mov     rax, [rbp-40]
    mov     rcx, rax            ; RCX = FILE*
    mov     edx, 1
    mov     esi, 1
    call    fread               ; READ GREEN VALUE

    mov     rax, [rbp-64]
    lea     rdi, [rax+2]        ; DESTINATION FOR BLUE
    mov     rax, [rbp-40]
    mov     rcx, rax            ; RCX = FILE*
    mov     edx, 1
    mov     esi, 1
    call    fread               ; READ BLUE VALUE

    ; INITIALIZE PIXEL POINTERS
    mov     rax, [rbp-64]
    mov     byte [rax+3], 0     ; SET PADDING BYTE
    mov     rax, [rbp-64]
    mov     qword [rax+32], 0   ; CLEAR RIGHT PTR
    mov     rax, [rbp-64]
    mov     rdx, [rax+32]
    mov     qword [rax+24], rdx ; CLEAR LEFT PTR
    mov     rax, [rbp-64]
    mov     rdx, [rax+24]
    mov     qword [rax+16], rdx ; CLEAR BELOW PTR
    mov     rax, [rbp-64]
    mov     rdx, [rax+16]
    mov     qword [rax+8], rdx  ; CLEAR ABOVE PTR

    ; HANDLE ROW START
    cmp     dword [rbp-28], 0   ; FIRST PIXEL IN ROW?
    jne     .skip_row_start
    mov     eax, [rbp-12]       ; CURRENT ROW NUMBER
    cdqe
    lea     rdx, [rax*8]        ; CALCULATE OFFSET
    mov     rax, [rbp-48]       ; ROW POINTERS ARRAY
    add     rdx, rax            ; ADD BASE ADDRESS
    mov     rax, [rbp-64]       ; CURRENT PIXEL
    mov     [rdx], rax          ; STORE ROW START

.skip_row_start:
    ; LINK HORIZONTAL PIXELS
    cmp     qword [rbp-24], 0   ; PREVIOUS PIXEL EXISTS?
    je      .skip_horizontal
    mov     rax, [rbp-24]
    mov     rdx, [rbp-64]
    mov     [rax+32], rdx       ; LINK PREVIOUS->CURRENT
    mov     rax, [rbp-64]
    mov     rdx, [rbp-24]
    mov     [rax+24], rdx       ; LINK CURRENT->PREVIOUS

.skip_horizontal:
    ; LINK VERTICAL PIXELS
    cmp     qword [rbp-8], 0    ; ABOVE PIXEL EXISTS?
    je      .skip_vertical
    mov     rax, [rbp-8]
    mov     rdx, [rbp-64]
    mov     [rax+16], rdx       ; LINK ABOVE->CURRENT
    mov     rax, [rbp-64]
    mov     rdx, [rbp-8]
    mov     [rax+8], rdx        ; LINK CURRENT->ABOVE
    mov     rax, [rbp-8]
    mov     rax, [rax+32]       ; MOVE TO NEXT ABOVE PIXEL
    mov     [rbp-8], rax

.skip_vertical:
    ; LINK HORIZONTAL PIXELS
    mov     rax, [rbp-64]
    mov     [rbp-24], rax       ; UPDATE PREVIOUS PIXEL
    inc     dword [rbp-28]      ; NEXT COLUMN

    mov     eax, [rbp-72]       ; CHECK COLUMN LIMIT
    cmp     [rbp-28], eax
    jl      .pixel_loop         ; CONTINUE IF MORE COLUMNS

    ; PREPARE NEXT ROW
    mov     eax, [rbp-12]
    cdqe
    lea     rdx, [rax*8]
    mov     rax, [rbp-48]
    add     rax, rdx
    mov     rax, [rax]          ; GET ROW START
    mov     [rbp-8], rax        ; STORE FOR VERTICAL LINKING
    inc     dword [rbp-12]      ; NEXT ROW

    mov     eax, [rbp-76]       ; CHECK ROW LIMIT
    cmp     [rbp-12], eax
    jl      .row_loop           ; CONTINUE IF MORE ROWS

    ; CLEANUP AND RETURN
    mov     rax, [rbp-48]
    mov     rax, [rax]
    mov     [rbp-56], rax       ; STORE FIRST PIXEL

    mov     rax, [rbp-48]
    mov     rdi, rax            ; FREE ROW POINTERS
    call    free

    mov     rax, [rbp-40]
    mov     rdi, rax            ; CLOSE FILE
    call    fclose

    mov     rax, [rbp-56]       ; RETURN FIRST PIXEL POINTER

.readPPM_end:                 
    leave                       ; RESTORE STACK FRAME
    ret
