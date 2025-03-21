;
; In this programm I use STDCALL convention
;

section .data
    fmt_string:   times 100 db 0         ; line passed between "" in printf 
    arg_string:   times 100 db 0         ; line passed after "", in printf

    output_buf: times 256 db 0            
    ; input_buf: times 100 db 0, 0            

    new_line: db 10, 0

section .text
    global MyPrintf

;------------------------------------------------
MyPrintf:   
    push rbp 
    mov rbp, rsp 

    call Input          ; read

    call Parser         ; parse 

    mov rsi, fmt_string ; print     
    call Output         ;

    mov rsi, new_line   ; printf \n
    call Output         ;

    mov rsi, arg_string ; print   
    call Output         ; 

    mov rsi, new_line   ; printf \n
    call Output      

    mov rax, 0          ; quit
    leave               ;
    ret                 ;
;------------------------------------------------


;------------------------------------------------
;   Get string 
;   
;   Gets input from console to [input_buf] 
;
; Entry:
;   ---
; Exit:    
;   ---
; Destr:
;   rax, rdi, rsi, rdx 
;------------------------------------------------
Input:  
    push rbp        ; make callee frame 
    mov rbp, rsp    ;

    mov rax, 0          ; code of reading
    mov rdi, 1          ; console descriptor
    mov rsi, input_buf    
    mov rdx, 100  
    syscall 

    leave           ; get back to caller frame
    ret             ; 
;------------------------------------------------


;------------------------------------------------
;   Show string
;
; Entry:
;   rsi = addr of string to show 
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
    mov rdx, 30
    syscall 
    
    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;               (Parser)
;   Parse string into format string and 
;   string of arguments
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

    push '"'            ; terminator
    push '"'            ; starter
    mov rdi, input_buf  ; take from here
    mov rsi, fmt_string ; place here
    call ExtractString  ;    

    push ')'            ; terminator
    push ','            ; starter
    mov rdi, input_buf  ; take from here
    mov rsi, arg_string ; place here
    call ExtractString  ;                           

    leave           ; get back to caller frame
    ret             ;
;------------------------------------------------


;------------------------------------------------
;               (FmtParser)
;   Parse fmt_string 
;
; Entry:
;   ---
; Exit:    
;   ---
; Destr:
;   
;------------------------------------------------
FmtParser:
    push rbp 
    mov rbp, rsp 
    


    leave 
    ret
;------------------------------------------------


;------------------------------------------------
;               (ArgParser)
;   Parse arg_string 
;
; Entry:
;   ---
; Exit:    
;   ---
; Destr:
;   
;------------------------------------------------
ArgParser:
    push rbp 
    mov rbp, rsp 
    
    

    leave 
    ret
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


