;
; In this programm I use HUYCALL calling convention
;

;------------------------------------------------
section .data
    fmt dq 0         ; pointer to format string
    fmt_size  dq 0   ; length in bytes
    fmt_shift dq 0   ; shift from begining

    arg dq 0         ; pointer to string with arguments 
    arg_size  dq 0   ; length in bytes
    arg_shift dq 0   ; shift from begining

    output_buf: times 256 db 0                    
    output_buf_shift:     dw 0

    arg_buf: times 30 dq 0    ; contains addr's and values 
    arg_sizes: times 30 dq 0  ; contains sizes of arguments in bytes if needed

    IS_ARG      dw 1         ; const 
    NO_ARG      dw 0         ; const 
    DECIMAL     dw 1         ; const %d
    OCTAL       dw 2         ; const %o
    HEXADEMICAL dw 3         ; const %x
    BINAR       dw 4         ; const %b 
    STRING      dw 5         ; const %s
    CHAR        dw 6         ; const %c 
    
    new_line: db 10, 0
;------------------------------------------------

section .text
    global MyPrintf

;------------------------------------------------
MyPrintf:   
    push rbp 
    mov rbp, rsp 

    jmp TakeArguments   ;
_take_args_end:

    mov al, 0           ; terminated by null
    mov rdi, [arg_buf]  ; 
    call Strlen         ; measure fmt string 
    mov [fmt_size], rax ; save size 
    
    mov rdx, rax        ; length from strlen    
    mov rsi, [arg_buf]  ; print  
    call Output         ;


    mov al, 0               ; terminated by null
    mov rdi, [arg_buf + 8]  ; 
    call Strlen             ; measure arg string 
    mov [arg_size], rax     ; save size 

    mov rdx, rax            ; length from strlen    
    mov rsi, [arg_buf + 8]  ; print  
    call Output             ;


    mov rax, 0          ; quit
    leave               ;
    ret                 ;
;------------------------------------------------


;------------------------------------------------
;   Show string
;
; Entry:
;   rsi = addr of string to show
;   rdx = length of string to show 
; Exit:    
;   ---
; Destr:
;   rax, rdi,  rdx 
;------------------------------------------------
Output:
    push rbp        ; make callee frame 
    mov rbp, rsp    ;
    
    mov rax, 1      ; code of writing
    mov rdi, 1      ; console descriptor
    ; mov rsi       ; rsi is set by caller     
    ; mov rdx       ; rdi is set by caller
    syscall 
    
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;               (ParseDriver)
;   Controles the rpocess of parsing the string
;   calls fmt_parser and arg_parser in parallel 
;   to take arguments, convert if needed and 
;   place in output buffer  
;
; Entry:
;   ---
; Exit:    
;   ---
; Destr:
;   ---
;------------------------------------------------
Parser:
    push rbp        ; make callee frame 
    mov rbp, rsp    ;

    xor r8, r8      ; argument counter 

    xor rcx, rcx    ;
    dec rcx         ; no counter limits 
_parser_loop_beg:
    call FmtParser

    cmp rax, 0  
    je _parser_end  ; found the end of string

    mov rdi, rax    ; mov type of argument to take 
    jmp _parser_arg

_parser_loop_end:
    loop _parser_loop_beg 


_parser_arg:
    push rcx        ; save counter
    call ArgParser  ; take argument     
    pop rcx
;--------------------------------------  
    inc r8          ; inc arg counter 
    mov rcx, [arg_sizes + r8 * 8] 
    mov rsi, [arg_buf + r8 * 8]
    mov rdi, 
    rep movsb 
    ;слив в буфер: выставить rsi, rdi + shift, взять длину строки, оконченной нулём, сделать rep movsb              
;--------------------------------------
    jmp _parser_loop_end 

_parser_end:                        
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;               (FmtParser)
;   Parse fmt_string 
;
; Entry:
;   ---           |--> 1 byte
; Exit:           |
;   rax = 1,2,3,4 --> place for found number
;   rax = 5 --> place found for string
;   rax = 6 --> place found for char
;   rax = 0 --> place not found (line ended) 
; Destr:        
;   rcx 
;------------------------------------------------
FmtParser:
    push rbp 
    mov rbp, rsp 
    sub rsp, 32     
    
    xor rcx, rcx 
    dec rcx 
    
    mov rcx, fmt_size       ;
    sub rcx, [fmt_shift]
    mov rdi, fmt            ;
    add rdi, [fmt_shift]
    push rdi                ; save 1st position

_fmt_loop:
    mov al, '%'             ; 
    scasb                   ;
    je _fmt_arg             ; argument found

    mov al, 0               ;
    scasb                   ;
    je _fmt_str_end         ; string end found
loop _fmt_loop

_fmt_arg:
    call IsArgument         ; sets rax
    jmp _fmt_parser_end

_fmt_str_end:
    mov rax, 0              ; string ended 
    jmp _fmt_parser_end

_fmt_parser_end:
    pop rdx                 ;
    sub rdi, rdx            ; count new shift in [fmt]
    mov [fmt_shift], rdi    ;
    
    leave           ; let driver decide 
    ret             ; what to do 
;------------------------------------------------


;------------------------------------------------
;               (IsArgument)
;   Checks if next symbol after % is different
;   from %, and tells the type of argument 
;   judging by type of symbol 
; Entry:
;   rdi is correctly set to symbol next to %            
; Exit:          
;   rax = code of argument( not ascii )
;   rdi++
; Destr:
;   al
;------------------------------------------------
IsArgument:
    push rbp 
    mov rbp, rsp 
    sub rsp, 32     

    mov al, '%'
    scasb 
    je _no_arg

    mov al, 'd'
    scasb 
    je _is_dec_arg

    mov al, 'o'
    scasb                               ; МОЖНО ДЖАМП ТАБЛИЦУ ЕБАНУТЬ 
    je _is_oct_arg

    mov al, 'x'
    scasb
    je _is_hex_arg

    mov al, 's'
    scasb
    je _is_str_arg

    mov al, 'c'
    scasb
    je _is_chr_arg

_no_arg:
    mov rax, 0  
    jmp _is_arg_end

_is_dec_arg:
    mov rax, DECIMAL   
    jmp _is_arg_end
_is_oct_arg:
    mov rax, OCTAL   
    jmp _is_arg_end
_is_hex_arg:
    mov rax, HEXADEMICAL  
    jmp _is_arg_end
_is_bin_arg:
    mov rax, BINAR   
    jmp _is_arg_end
_is_str_arg:
    mov rax, STRING    
    jmp _is_arg_end
_is_chr_arg:
    mov rax, CHAR
    jmp _is_arg_end

_is_arg_end:
    leave       
    ret
;------------------------------------------------


;------------------------------------------------
;               (ArgParser)
;   Parse arg_string 
;
; Entry:
;   rdi = type of argument to extract 
;   r8  = counter of arguments 
; Exit:    
;   ---
; Destr:
;   rcx 
;------------------------------------------------
ArgParser:
    push rbp 
    mov rbp, rsp 
    sub rsp, 32     
    
    cmp rdi, DECIMAL 
    je _arg_parser_dec

    cmp rdi, HEXADEMICAL
    je _arg_parser_hex

    cmp rdi, OCTAL 
    je _arg_parser_oct

    cmp rdi, BINAR 
    je _arg_parser_bin

    cmp rdi, STRING 
    je _arg_parser_str

    cmp rdi, CHAR 
    je _arg_parser_chr 

_arg_parser_dec:
    ; call ConvertDecimal
    jmp _is_arg_end

_arg_parser_hex:
    ; call ConvertHex
    jmp _is_arg_end

_arg_parser_oct:
    ; call ConvertOct
    jmp _is_arg_end

_arg_parser_bin:
    ; call ConvertBinary
    jmp _is_arg_end

_arg_parser_str:
    call ConvertString 
    jmp _is_arg_end
_arg_parser_chr:
    ; call ConvertChar
    jmp _is_arg_end


_arg_parser_end:

    
    leave           ; let driver decide 
    ret             ; what to do 
;------------------------------------------------


;------------------------------------------------
;           (ConvertString)
;   Takes link to string and copies it 
;
; Entry:
;   
; Exit: 
;
; Destr:
;   al 
;------------------------------------------------
ConvertString: 
    push rbp        ; make callee frame 
    mov rbp, rsp    ;

    mov al, '0'                     ; terminating 
    mov rdi, [arg_buf + r8 * 8]     ; string
    call Strlen 
    mov [arg_sizes + r8 * 8], rax   ; length of string  

    mov rax, rdi    ; return value 
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;   Skips spaces and return pointer 
;   of first symbol in the given part 
;   of string 
;
; Entry:
;   rdi = string addr  
; Exit: 
;   rdi = addr of first symbol
; Destr:
;   al 
;------------------------------------------------
SkipSpace: 
    push rbp        ; make callee frame 
    mov rbp, rsp    ;

    mov al, ' '     ; ascii of space

    xor rcx, rcx    ; remove iteration counter
    sub rcx, 1      ; 

    repe scasb      ; 
    dec rdi         ; rdi++ till space
    
    mov rax, rdi    ; return value 
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;           (GiveArguments)
;
;
; Entry:
;   r8 = counter of arguments 
; Exit: 
; 
; Destr:
;  
;------------------------------------------------
GiveArguments: 
    push rbp        ; make callee frame 
    mov rbp, rsp    ;



    mov rax, rdi    ; return value 
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;           (TakeArguments)
;   Fills the buffer of arguments up to 20 
;   arguments 
;   
;   it is not a function, cause I recieve 
;   arguments through stack, so I have to 
;   not spoil stack frame 
;
; Entry:
;    
; Exit: 
; 
; Destr:
;  
;------------------------------------------------
TakeArguments: 
    mov [arg_buf], rdi 
    mov [arg_buf + 8], rsi     
    mov [arg_buf + 16], rdx
    mov [arg_buf + 24], rcx
    mov [arg_buf + 32], r8
    mov [arg_buf + 40], r9

    mov rcx, 15         ; 15 + 5 = 20 arguments 
    mov rdi, arg_buf    ; begining
    add rdi, 48         ; shift
_take_loop:
    pop rax 
    stosq 
    loop _take_loop

    mov rax, rdi    ; return value 
    jmp _take_args_end
;------------------------------------------------


;------------------------------------------------
;           (ExtractString) 
; Extract string that is located between 
; two symbols starter and terminator
;
; Entry:
;   rdi = addr of string, to extract from 
;   1st and 2nd args through stack in RTL 
;   order 
; Exit: 
;   [fmt_string] is ready 
; Destr:
;   ---
;------------------------------------------------
ExtractString:
    push rbp            ; make callee frame 
    mov rbp, rsp        ;

    xor rcx, rcx        ; remove iteration counter
    dec rcx             ; 

    ; mov al, '"'     
    mov rax, [rbp+16]   ; starting symbol 
    repne scasb         ; rdi++ till " symbol

    ; mov al, '"'         
    mov rax, [rbp+24]   ; terminating symbol
    push rdi            ; save position in string
    call Strlen         ; measure the 
    mov rcx, rax        ; amount of cycles( symbols )          

    pop rdi             ; start from saved position 

    xchg rsi, rdi       ; change path of transfering data   
    rep movsb

    leave               ; get back to caller frame
    ret                 ;
;------------------------------------------------


;------------------------------------------------
;               (Strlen) 
; Meeasures the length og string ended with 
; terminating symbol 
;
; Entry:
;   al = ascii of terminating symbol of string      
;   rdi = string to measure 
; Exit: 
;   rax = length in bytes 
; Destr:
;   
;------------------------------------------------
Strlen:
    push rbp        ; make callee frame 
    mov rbp, rsp    ;

    xor rcx, rcx 
    dec rcx 
    repne scasb     ; rdi++, rcx-- till (al) faced
    neg rcx         ; convert rcx value
    dec rcx         ; to length of the string
    dec rcx 

    mov rax, rcx    ; return value 
    leave           ; get back to caller frame
    ret             ; 
;------------------------------------------------


