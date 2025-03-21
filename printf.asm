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

    char_buf: db 0, 0 

    hex_digits: db '0123456789abcdef', 0

    IS_ARG      dw 1         ; const 
    NO_ARG      dw 7         ; const 

    DECIMAL     equ 0         ; const %d  |
    OCTAL       equ 1         ; const %o  |
    HEXADEMICAL equ 2         ; const %x  | 
    BINAR       equ 3         ; const %b  |--------->>> Формируется джамп таблица 
    STRING      equ 4         ; const %s  |
    CHAR        equ 5         ; const %c  |
    
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

    call Output         ; begin output
    call BufferFlush    ; flush remaining part

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

    push rsi 
    jmp Putchar         ; output
Putchar_end:
    pop rsi 

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


_ArgType_end:
    leave 
    ret 
;------------------------------------------------


;------------------------------------------------
;               (BufferHandler)
;   Handles the flushing of buffer 
;
; Entry:
;
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
_octal_process:

    mov rax, rsi                ; take number to convert 
    mov rcx, convert_num_buf + convert_num_buf_size - 2   ; redirect to string, containing result 
    mov rbx, 8                  ; number system size 
_convert_dec_loop:
    xor rdx, rdx 
    div rbx 
    add dl, '0' 
    mov [rcx], dl               ; bytes count from 0, iteration from 1
    dec rcx                     ;
    test rax, rax               ; cmp rax with 0
    jne _convert_dec_loop

    mov rsi, rcx
    inc rsi 

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
_hex_process:     

    mov rax, rsi              ; take number to convert 
    mov rcx, convert_num_buf + convert_num_buf_size - 2   ; redirect to string, containing result 
    mov rbx, 16                 ; number system size 
_convert_hex_loop:
    xor rdx, rdx 
    div rbx 
    mov dl, [hex_digits + rdx]
    mov [rcx], dl               ; bytes count from 0, iteration from 1
    dec rcx                     ;
    test rax, rax               ; cmp rax with 0
    jne _convert_hex_loop

    mov rsi, rcx
    inc rsi 

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
_binar_process:    

    mov rax, rsi                ; take number to convert 
    mov rcx, convert_num_buf + convert_num_buf_size - 2   ; redirect to string, containing result 
    mov rbx, 2                  ; number system size 
_convert_bin_loop:
    xor rdx, rdx 
    div rbx 
    add dl, '0' 
    mov [rcx], dl               ; bytes count from 0, iteration from 1
    dec rcx                     ;
    test rax, rax               ; cmp rax with 0
    jne _convert_bin_loop

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
    
    mov [char_buf], rsi
    mov rsi, char_buf

    jmp _arg_process_end
;------------------------------------------------

