section .data
    max_buffer_size equ 512
    open_failed_msg db "Error: Could not open the PPM file.", 0
    read_failed_msg db "Error: Could not read the PPM file.", 0
    parse_failed_msg db "Error: Failed to parse the PPM header.", 0
    open_file_msg db "Attempting to open file: ", 0
    newline db 10, 0

section .bss
    buffer resb max_buffer_size
    width resd 1
    height resd 1
    max_color_value resd 1
    pixel_head resq 1
    current_pixel resq 1
    previous_row_head resq 1

section .text
    extern malloc
    extern open, read, close, write
    global readPPM
    global pixel_head

readPPM:
    ; Function prologue
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Initialize pixel_head to NULL
    mov qword [pixel_head], 0

    ; Print the filename to help with debugging
    mov rsi, [rbp+16]          ; Load the filename from function arguments
    call print_filename

    ; Open the file in binary read mode
    mov rdi, rsi               ; Filename from parameter
    xor rsi, rsi               ; O_RDONLY
    call open
    test rax, rax
    js .open_failed            ; If open failed, jump to error
    mov rdi, rax               ; File descriptor

    ; Read the PPM header
    mov rsi, buffer
    mov rdx, max_buffer_size
    call read
    test rax, rax
    js .read_failed            ; If read failed, jump to error

    ; Parse the header to extract width, height, and max_color_value
    call parseHeader
    test rax, rax
    jz .parse_failed

    ; Initialize the linked list of PixelNodes
    call createPixelLinkedList
    test rax, rax
    jz .create_failed          ; If creation failed, jump to error

    ; Close the file
    mov rdi, rax               ; File descriptor
    call close

    ; Set the return value
    mov rax, [pixel_head]
    jmp .exit

.open_failed:
    ; Error handling for file open failure
    mov rdi, open_failed_msg
    call print_error
    xor rax, rax
    jmp .exit

.read_failed:
    ; Error handling for file read failure
    mov rdi, read_failed_msg
    call print_error
    xor rax, rax
    jmp .exit

.parse_failed:
    ; Error handling for header parsing failure
    mov rdi, parse_failed_msg
    call print_error
    xor rax, rax
    jmp .exit

.create_failed:
    ; Error handling for linked list creation failure
    mov rdi, parse_failed_msg
    call print_error
    xor rax, rax

.exit:
    ; Function epilogue
    mov rsp, rbp
    pop rbp
    ret

print_filename:
    ; Print "Attempting to open file: " message
    mov rax, 1                 ; syscall: write
    mov rdi, 1                 ; file descriptor: stdout
    mov rsi, open_file_msg     ; message to print
    mov rdx, 26                ; length of the message
    syscall

    ; Print the filename passed in rsi
    ; Assume rsi points to the filename string
    mov rax, 1                 ; syscall: write
    mov rdi, 1                 ; file descriptor: stdout
    mov rdx, 0                 ; Initialize rdx to 0
find_length:
    ; Calculate the length of the filename
    cmp byte [rsi + rdx], 0    ; Check for null terminator
    je print_name              ; If found, jump to printing
    inc rdx                    ; Increment length
    jmp find_length            ; Repeat until end of string

print_name:
    ; Now rdx holds the length of the filename
    mov rax, 1                 ; syscall: write
    mov rdi, 1                 ; file descriptor: stdout
    syscall

    ; Print a newline
    mov rax, 1                 ; syscall: write
    mov rdi, 1                 ; file descriptor: stdout
    mov rsi, newline           ; newline character
    mov rdx, 1                 ; length of newline
    syscall
    ret

print_error:
    ; Use the write system call to print the error message to stderr
    mov rax, 1                 ; syscall: write
    mov rdi, 2                 ; file descriptor: stderr
    mov rsi, rdi               ; error message to print
    mov rdx, 30                ; length of the message (adjust as needed)
    syscall
    ret

parseHeader:
    ; Parse the PPM header from the buffer
    ; Extract width, height, and max_color_value
    ; Return 1 if successful, 0 if parsing fails
    ; Assume format: P6\n<width> <height>\n<maxColorValue>\n
    ; This implementation needs to handle comments and skip whitespace
    ret

createPixelLinkedList:
    ; Create a 2D array of PixelNodes based on the parsed width and height
    ; Allocate memory for each PixelNode using malloc
    ; Set the up, down, left, right pointers to form a linked list structure
    ; Return 1 if successful, 0 if creation fails
    ret
