;
; In this programm I use HUYCALL calling convention
;
;   addr of args = R9, 
;   stack: [R9] = 1 --> 2 --> 3 --> ... 
;               +1*8  +2*8  +3*8  ...
;------------------------------------------------
%include "print_macros.inc"
;------------------------------------------------
section .data
    output_buf_shift:     dq 0
    output_buf: times 256 db 0       
    output_buf_size equ $ - output_buf               

    arg_counter: dq 1        ; counts amount of written args 

    convert_num_buf: times 30 db 0  ; can fit any number, and unused bytes will be 0( print nothing )
    convert_num_buf_size equ $ - convert_num_buf

    char_buf: times 2 db 0 

    digits: db '0123456789abcdef', 0
;------------------------------------------------

section .text
    global MyPrintf

;------------------------------------------------
;               JUMP TABLE 
_jump_table:
    
    times 5 db 0            ; 'a'
    jmp _binar_process      ; 'b'
    jmp _char_process       ; 'c'
    jmp _decimal_process    ; 'd'
    times 5 db 0            ; 'e'
    times 5 db 0            ; 'f'
    times 5 db 0            ; 'g'
    times 5 db 0            ; 'h'
    times 5 db 0            ; 'i'
    times 5 db 0            ; 'j'
    times 5 db 0            ; 'k'
    times 5 db 0            ; 'l'
    times 5 db 0            ; 'm'
    times 5 db 0            ; 'n'
    jmp _octal_process      ; 'o'        
    times 5 db 0            ; 'p'
    times 5 db 0            ; 'q'
    times 5 db 0            ; 'r'
    jmp _string_process     ; 's'
    times 5 db 0            ; 't'
    times 5 db 0            ; 'u'
    times 5 db 0            ; 'v'
    times 5 db 0            ; 'w'
    jmp _hex_process        ; 'x'
    times 5 db 0            ; 'y'
    times 5 db 0            ; 'z'
;------------------------------------------------

MyPrintf:   
;-----------------
    pop rax     ; save return addr 

    push r9     ;
    push r8     ; 
    push rcx    ;  saving arguments 
    push rdx    ;  
    push rsi    ;
    push rdi    ;

;pointer to arguments 
    mov r9, rsp ; <======  DON'T TOUCH THIS MAN !!!!!!!! 
    
    push rax    ; push return addr
;----------------

    push rbp 
    mov rbp, rsp 

    mov qword [arg_counter], 1
    call Output         ; begin output
    BufferFlush    ; flush remaining part

    xor rsi, rsi 
    xor rdi, rdi 

    mov rax, 0          ; quit
    leave               ;
    ret                 ;
;------------------------------------------------


;------------------------------------------------
;               (Output)
; Entry:
;   nothing
; Exit:
;   takes symbol from format string and sends 
;   it to Putchar to print it 
;------------------------------------------------
Output:
    push rbp 
    mov rbp, rsp 

    xor rcx, rcx        ; delete counter        
    dec rcx             ;
    mov rsi, [r9]       ; = format string( 1 argument )   
print_loop:  
    lodsb               ; rsi --> al   stosb = al --> rdi 
    mov dl, 0 
    cmp al, dl 
    je _output_end
 
    jmp Putchar         ; output
Putchar_end:

    xor rcx, rcx        ; delete counter        
    dec rcx             ;
    loop print_loop 

_output_end:
    leave 
    ret 
;------------------------------------------------


;------------------------------------------------
;               (Putchar)
;   Moves symbols to the buffer  
;
; Entry:
;   al = current outputed symbol 
; Exit:
;   if symbol is regular, outputs it
;   if it is argument calls, inserts argument 
;   with the help of other funcs 
;------------------------------------------------
Putchar:
    cmp al, '%'
;if( != % )
    jne _putc_write
;else
    xor rax, rax
    lodsb                   ; skip %, go to next symbol
;if( <= 'a' || >= 'z', just write )
    cmp al, 'a'
    jle _putc_write
    cmp al, 'z'
    jge _putc_write
;else if( == % )
    cmp al, '%'
    je _putc_write
;else 
    push rsi                ; save shift in format string
    mov rsi, [arg_counter]  ; shift from  
    imul rsi, 8             ; beginning 
    add rsi, r9             ; begin of args in stack
    mov rsi, [rsi]

    sub al, 'a'             ; count shift from begin of jump table
    movzx rax, al
    mov rdx, _jump_table    ;
    imul rax, 5             ; modifing addres of jump
    add rdx, rax            ;
    jmp rdx                 ; process argument
_arg_process_end: 
    call OverwriteArg 
    pop rsi                 ; return shift in format string
    jmp Putchar_end  

_putc_write: 
    BufferStore
    jmp Putchar_end 
;------------------------------------------------


;------------------------------------------------
;               (OwerwriteArg)
;   Arguments, already converted to strings
;   are writed over specificators 
;
; Entry: 
;   rsi is set to string(ended with 0) 
;   with argument 
;
;------------------------------------------------
OverwriteArg:
    push rbp 
    mov rbp, rsp 

    ;------------------------
    xor rcx, rcx            ; 
    dec rcx                 ; infinite cycle 
_overwrite:
    mov dl, 0               ; terminating of string
    cmp [rsi], dl           ;
    je _overwrite_end       ; leave, when \0

    lodsb                   ; rsi -->> al
    push rsi 
    BufferStore             ; al -->> rdi 
    pop rsi 

    xor rcx, rcx            ; 
    dec rcx                 ; infinite cycle 
    loop _overwrite
    ;------------------------

_overwrite_end:
    mov edx, 1
    add [arg_counter], edx  

    leave
    ret
;------------------------------------------------


;------------------------------------------------
;   Convert number, place it to string 
;   ended with \0
;
; Entry: rsi points to argument
;
; Exit: rsi points to string, that contains 
;       ready to print argument 
;
;------------------------------------------------
_decimal_process: 
    mov rax, rsi                ; take number to convert 
    movsx rax, ax               ; int(4 bytes) to 8 bytes 
    push rax 
    cmp rax, 0
    jge _begin_convert_dec
    neg rax

_begin_convert_dec:
    mov rcx, convert_num_buf + convert_num_buf_size - 2   ; redirect to string, containing result 
    mov rbx, 10                 ; number system size 
_convert_loop:
    xor rdx, rdx 
    div rbx 
    add dl, '0' 
    mov [rcx], dl               ; bytes count from 0, iteration from 1
    dec rcx                     ;
    test rax, rax               ; cmp rax with 0
    jne _convert_loop
    pop rax 
    cmp rax, 0 
    jge _end_convert_dec
    mov byte [rcx], '-'
    dec rcx 

_end_convert_dec:
    mov rsi, rcx                ; change number value to addr of string 
    inc rsi                     ; подгон shift'a
    jmp _arg_process_end        ; EXIT


_octal_process:
    mov rbx, 8                  ; number system size 
    jmp _begin_num_convert
_hex_process:
    mov rbx, 16                  ; number system size 
    jmp _begin_num_convert
_binar_process:
    mov rbx, 2                  ; number system size 
    jmp _begin_num_convert


_begin_num_convert:
    mov rax, rsi                ; take number to convert 
    mov rcx, convert_num_buf + convert_num_buf_size - 2   ; redirect to string, containing result 
_convert_num_loop:
    xor rdx, rdx 
    div rbx 
    mov dl, [digits + rdx] 
    mov [rcx], dl               ; bytes count from 0, iteration from 1
    dec rcx                     ;
    test rax, rax               ; cmp rax with 0
    jne _convert_num_loop
    mov rsi, rcx
    inc rsi 
    jmp _arg_process_end        ; EXIT 

_char_process:
    mov rdx, rsi
    mov [char_buf], dl
    mov rsi, char_buf
    jmp _arg_process_end        ; EXIT 

_string_process:  
    jmp _arg_process_end        ; EXIT 
;------------------------------------------------
