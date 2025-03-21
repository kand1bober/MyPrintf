extern	printf

section .data
    msg:	db "Hello world", 0 ; Zero is Null terminator 
    fmt:    db "%d", 10, 0      ; printf format string follow by a newline(10) and a null terminator(0), "\n",'0'

section .text
    global main
    

main:
    push rbp ; Push stack

    ; Set up parameters and call the C function
    mov	rdi,fmt
    mov	rsi, 15

    mov	rax, 0
    
    call printf

    pop	rbp		; Pop stack

    mov rax, 0
    ret

    