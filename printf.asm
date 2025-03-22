;
; In this programm I use HUYCALL calling convention
;
;   addr of args = R9, 
;   stack: [R9] = 1 --> 2 --> 3 --> ... 
;               +1*8  +2*8  +3*8  ...
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

    IS_ARG      dw 1         ; const 
    NO_ARG      dw 7         ; const 

    DECIMAL     equ 0         ; const %d  |
    OCTAL       equ 1         ; const %o  |
    HEXADEMICAL equ 2         ; const %x  | 
    BINAR       equ 3         ; const %b  |--------->>> Формируется джамп таблица 
    STRING      equ 4         ; const %s  |
    CHAR        equ 5         ; const %c  |
    PERCENT     equ 6         ; const %%  |
    
    err_msg: db 'Buffer oerflowed', 0
    err_len equ $ - err_msg 

    new_line: db 10, 0
;------------------------------------------------

section .text
    global MyPrintf

;------------------------------------------------
;               JUMP TABLE 
_arg_process:
    jmp _decimal_process    ;|
    jmp _octal_process      ;|
    jmp _hex_process        ;|
    jmp _binar_process      ;|<<--------- Jump Table 
    jmp _string_process     ;|
    jmp _char_process       ;|
    jmp _percent_process    ;|
;------------------------------------------------

MyPrintf:   
; ----------------
    pop rax     ; save return addr 

    push r9     ;
    push r8     ; 
    push rcx    ;  saving arguments 
    push rdx    ;  
    push rsi    ;
    push rdi    ;
    mov r9, rsp ; <======  DON'T TOUCH THIS MAN !!!!!!!!
    
    push rax    ; push return addr
;----------------

    push rbp 
    mov rbp, rsp 

    mov qword [arg_counter], 1
    call Output         ; begin output
    call BufferFlush    ; flush remaining part
    call BufferClear    ; clear for next calling of MyPrintf

    xor rsi, rsi 
    xor rdi, rdi 

    mov rax, 0          ; quit
    leave               ;
    ret                 ;
;------------------------------------------------


;------------------------------------------------
;               (Output)
;    
; Entry:
;
; Exit:
;
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
;
; Exit:
;
;------------------------------------------------
Putchar:
    cmp al, '%'                    ;TODO: добавить IsArgument проверку по следующему символу 
;if( != % )
    jne _putc_write
;else
    lodsb                   ; skip %, go to next symbol
    call ArgType  
    push rsi                ; save shift in format string

    mov rsi, [arg_counter]  ; shift from  
    imul rsi, 8             ; beginning 
    add rsi, r9             ; begin of args in stack
    mov rsi, [rsi]

    mov rdx, _arg_process   ;
    imul rax, 5             ; modifing addres of jump
    add rdx, rax            ;
    jmp rdx                 ; process argument
_arg_process_end: 
    call OverwriteArg 
    pop rsi                 ; return shift in format string
    jmp Putchar_end  


_putc_write: 
    call BufferHandler  
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
    call BufferHandler      ; al -->> rdi 
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
;               (ArgType)
;   Returns the type of ArgType 
;
; Entry:
;   al = symbol 
; Exit:
;   rax = code of specifier
;------------------------------------------------
ArgType:
    push rbp 
    mov rbp, rsp 


    mov bl, 'd'
    cmp bl, al 
    je _arg_is_dec 

    mov bl, 'o'
    cmp bl, al                          ; МОЖНО ДЖАМП ТАБЛИЦУ ЕБАНУТЬ 
    je _arg_is_oct 

    mov bl, 'x'
    cmp bl, al 
    je _arg_is_hex

    mov bl, 'b'
    cmp bl, al 
    je _arg_is_bin

    mov bl, 's'
    cmp bl, al 
    je _arg_is_str

    mov bl, 'c'
    cmp bl, al 
    je _arg_is_chr

    mov bl, '%'
    cmp bl, al
    je _arg_is_not_arg


_arg_is_dec:
    mov rax, qword DECIMAL 
    jmp _ArgType_end
_arg_is_oct:
    mov rax, qword OCTAL  
    jmp _ArgType_end
_arg_is_hex:
    mov rax, qword HEXADEMICAL 
    jmp _ArgType_end
_arg_is_bin:
    mov rax, qword BINAR
    jmp _ArgType_end
_arg_is_str:
    mov rax, qword STRING 
    jmp _ArgType_end
_arg_is_chr:
    mov rax, qword CHAR
    jmp _ArgType_end
_arg_is_not_arg:
    mov rax, qword PERCENT
    jmp _ArgType_end


_ArgType_end:
    leave 
    ret 
;------------------------------------------------


;------------------------------------------------
;               (BufferHandler)
;   Handles the flushing of buffer 
;
; Entry:
;   al = symbol to write 
; Exit:
;
;------------------------------------------------
BufferHandler:
    push rbp 
    mov rbp, rsp 

    mov rbx, output_buf_size
    cmp rbx, [output_buf_shift]
    jg _buf_store
    je _buf_flush  
    jl _buf_overflow

_buf_store:
    call BufferStore 
    jmp _buf_end 
    
_buf_flush:
    push rax            ; rember not written symbol 
    push rsi            ; and it's position 
    call BufferFlush
    pop rsi             ; return symbol 
    pop rax             ; and position
    call BufferStore
    jmp _buf_end 

_buf_overflow:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_msg 
    mov rdx, err_len
    jmp _buf_end 

_buf_end:
    leave
    ret 
;------------------------------------------------


;------------------------------------------------
;               (BufferFlush)
;   Manual mode of flushing buffer 
;
; Entry:
;  
; Exit:
;
;------------------------------------------------
BufferFlush:
    push rbp 
    mov rbp, rsp 

    mov rax, 1
    mov rdi, 1
    mov rsi, output_buf              
    mov rdx, qword [output_buf_shift]                    
    syscall                         ; buffer flush 

    xor rdx, rdx 
    mov [output_buf_shift], rdx 

    leave
    ret 
;------------------------------------------------


;------------------------------------------------
;               (BufferStore)
;   Manual mode of storing buffer 
;
; Entry:
;
; Exit:
;
;------------------------------------------------
BufferStore:
    push rbp 
    mov rbp, rsp 

    mov rdi, output_buf 
    add rdi, [output_buf_shift]
    stosb                           ; al --> rdi = buffer 
    inc qword [output_buf_shift]

    leave
    ret 
;------------------------------------------------


;------------------------------------------------
;               (BufferClear)
;   Clears buffer (needed fo multiple calling 
;   of Myprintf) 
;
; Entry:
;
; Exit:
;
;------------------------------------------------
BufferClear:
    push rbp 
    mov rbp, rsp 

    mov rcx, output_buf_size
    mov rdi, output_buf 
    mov al, 0
_buf_clear_loop:
    stosb                           ; al --> rdi = buffer 
    loop _buf_clear_loop 

    leave
    ret 
;------------------------------------------------


;------------------------------------------------
;   Changes symbol in the stack to addr of
;   it's string representation ended with \0
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
    jmp _arg_process_end    
;------------------------------------------------


;------------------------------------------------
;   Changes symbol in the stack to addr of
;   it's string representation ended with \0
;
; Entry: rsi points to argument
;
; Exit: rsi points to string, that contains 
;       ready to print argument 
;
;------------------------------------------------
_numbers_process:

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

    jmp _arg_process_end
;------------------------------------------------


;------------------------------------------------
_string_process:  
    jmp _arg_process_end
;------------------------------------------------


;------------------------------------------------
;   Changes symbol in the stack to addr of
;   it's string representation ended with \0
;
; Entry: rsi points to argument
;
; Exit: rsi points to string, that contains 
;       ready to print argument 
;
;------------------------------------------------
_char_process:
    
    mov rdx, rsi
    mov [char_buf], dl
    mov rsi, char_buf

    jmp _arg_process_end
;------------------------------------------------


;------------------------------------------------
;   Changes symbol in the stack to addr of
;   it's string representation ended with \0
;
; Entry: rsi points to argument
;
; Exit: rsi points to string, that contains 
;       ready to print argument 
;
;------------------------------------------------
_percent_process:

    mov dl, '%'
    mov [char_buf], dl
    mov rsi, char_buf
    sub qword [arg_counter], 1

    jmp _arg_process_end
;------------------------------------------------
