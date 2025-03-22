;------------------------------------------------
;               (BufferHandler)
;   Handles the flushing of buffer 
;
; Entry:
;   al = symbol to write 
; Exit:
;
;------------------------------------------------
%macro BufferStore 0
    mov rbx, output_buf_size
    cmp rbx, [output_buf_shift]
    jg .buf_store
    je .buf_flush  

.buf_flush:
    push rax            ; rember not written symbol 
    push rsi            ; and it's position 
    BufferFlush
    pop rsi             ; return symbol 
    pop rax             ; and position

.buf_store:
    mov rdi, output_buf 
    add rdi, [output_buf_shift]
    stosb                           ; al --> rdi = buffer 
    inc qword [output_buf_shift]
    
%endmacro 
;------------------------------------------------


;------------------------------------------------
;               (BufferFlush)
;   Manual mode of flushing buffer 
;
; Entry: 
;   nothing 
; Exit:
;   flushed into output buffer 
;------------------------------------------------
%macro BufferFlush 0
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buf              
    mov rdx, qword [output_buf_shift]                    
    syscall                         ; buffer flush 

    xor rdx, rdx 
    mov [output_buf_shift], rdx 
%endmacro 
;------------------------------------------------