.model tiny

;   Machine constants

VIDEO_MEM = 0b800h
CONS_WIDTH = 80

.code

public printf
public putDec
public putBin
public putHex

;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   printf                        HHH
;HHH - formatted string printing                     HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > format (the format string)    HHH
;HHH                   ...    (arguments)            HHH
;HHH          AH    (color)                          HHH
;HHH          ES:DI (current position)               HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          DI, SI                                 HHH
;HHH                                                 HHH
;HHH=================================================HHH
    
printf proc
    push bp
    mov bp, sp
    
    ; ah - text color
    ; al - current char from format
    ; bh - color (save)
    
    push si
    
    ; si -> format = [bp + 4]
    mov si, [bp + 4]
        add bp, 6
    ; now we are to add 2 to bp every time we get next argument    
    
    ; color (save)
    mov bh, ah
    
    cld
    
printf_next_char:    
    ; getting next char
    lodsb
    
    ; char == 0 <=> EOL
    cmp al, 0
    je printf_longjmp_end
    
    ; char == \ <=> special symbol
    cmp al, '\'
    jne printf_not_specsym
        ; getting the special symbol
        lodsb
        
        cmp al, '0'
        jne printf_not_zero
            mov al, 0
            jmp printf_longjmp_end
    printf_not_zero:
    
        cmp al, '\'
        jne printf_not_rslash
            mov al, '\'
            mov ah, bh
            stosw
            jmp printf_next_char
    printf_not_rslash:
        
        cmp al, 'n'
        jne printf_not_newline
            push bx
            
            mov bx, 0
        printf_newline_loop:
            add bx, CONS_WIDTH * 2
            cmp di, bx
            jnb printf_newline_loop
            
            mov di, bx
            
            pop bx
            jmp printf_next_char
    printf_not_newline:
        
        cmp al, 'b'
        jne printf_not_bkspace
            cmp di, 0
            je printf_next_char
            sub di, 2
            jmp printf_next_char
    printf_not_bkspace:
    
        push bx
    
        push ax
        push offset printf_err_specsym
        mov ah, 04h
        call printf
        add sp, 2 * 2
        
        pop bx
        
        jmp printf_longjmp_end
        
printf_not_specsym:

    ; char == % <=> special parameter output
    cmp al, '%'
    je printf_spec
        ; simple char output
        mov ah, bh
        stosw
        jmp printf_next_char
    
    
    jmp printf_shortjmp
printf_longjmp_end:
    jmp printf_end
printf_shortjmp:
    
    
printf_spec:
    ; getting the parameter's type
    lodsb
    
    ; char == % <=> %
    cmp al, '%'
    jne printf_not_percent
        mov ah, bh
        stosw
        jmp printf_next_char
printf_not_percent:

    ; char == d <=> decimal number
    cmp al, 'd'
    jne printf_not_dec
        push bx
        
        mov ax, [bp]
            add bp, 2
        push ax
        mov ah, bh
        call putDec
        add sp, 2 * 1
        
        pop bx
        jmp printf_next_char
printf_not_dec:    
    
    ; char == b <=> binary number
    cmp al, 'b'
    jne printf_not_bin
        push bx
        
        mov ax, [bp]
            add bp, 2
        push ax
        mov ah, bh
        call putBin
        add sp, 2 * 1
        
        pop bx
        jmp printf_next_char
printf_not_bin:

    ; char == x <=> hex number
    cmp al, 'x'
    jne printf_not_hex
        push bx
        mov ax, [bp]
            add bp, 2
        push ax
        mov ah, bh
        call putHex
        add sp, 2 * 1
        
        pop bx
        jmp printf_next_char
printf_not_hex:
    
    ; char == c <=> char parameter
    cmp al, 'c'
    jne printf_not_char
        mov ax, [bp]
            add bp, 2
        mov ah, bh
        stosw
        
        jmp printf_next_char
printf_not_char:
    
    ; char == s <=> string parameter
    cmp al, 's'
    jne printf_not_str
        mov ax, [bp]
            add bp, 2
        push ax     ; 1
        mov ah, bh  ; color
        call printf
        add sp, 2 * 1
        jmp printf_next_char
printf_not_str:

    push bx
    
    push ax
    push offset printf_err_formattype
    mov ah, 04h
    call printf
    add sp, 2 * 2
    
    pop bx
        
printf_end:
    
    pop si
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   putDec                        HHH
;HHH - print a number as decimal                     HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH          AH    (color)                          HHH
;HHH          ES:DI (current position)               HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          DI                                     HHH
;HHH                                                 HHH
;HHH=================================================HHH

putDec proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    
    ;---------------------------------------------
    
    ; ax - current num
    ; bh - color
    ; bl - current digit
    ; bx - $10 (for division)
    ; ch - color
    ; cl - #digits <=> current displacement
    ; dx (dl actually) - remain (from division)
    
    ; color
    mov ch, ah
    
    ; displacement
    mov cl, 0
    
    ; ax = num
    mov ax, [bp + 4]
    
putDec_step:
    ; ax -> ax*10 + dx, dx<10 => dx <=> dl
    ;          =bx
    mov dx, 0
    mov bx, 10
    div bx

    ; bl = dl (remain)
    mov bl, dl
    
    ; converting bx to char
    add bl, '0'
    mov bh, ch
    push bx
    
    ; ++displacement
    inc cl
    
    cmp ax, 0
    jne putDec_step
    
    ; cl => cx
    mov ch, 0
    
    cld
    
putDec_loop:
    pop ax
    stosw
    loop putDec_loop
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   putBin                        HHH
;HHH - print a number as binary                      HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH          AH    (color)                          HHH
;HHH          ES:DI (current position)               HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, CX                                 HHH
;HHH          DI                                     HHH
;HHH                                                 HHH
;HHH=================================================HHH

putBin proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    
    ;---------------------------------------------
    
    ; ax - current num
    ; ch - text color
    ; cl - #digits <=> current displacement

    ; color
    mov ch, ah
    
    ; displacement
    mov cl, 0
    
    ; num
    mov ax, [bp + 4]
    
putBin_step:      
    ; ax % 2 <=> last bit (mask 0001)
    and ax, 0001h
    
    ; converting to char
    add al, '0'
    mov ah, ch
    push ax
    
    ; ++displacement
    inc cl
    mov ax, [bp + 4]
    shr ax, cl
    
    ; num == 0 <=> end
    cmp ax, 0
    jne putBin_step
    
    ; cl => cx
    mov ch, 0
    
    cld
    
putBin_loop:
    pop ax
    stosw
    loop putBin_loop
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   putHex                        HHH
;HHH - print a number as a hex number                HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH          AH    (color)                          HHH
;HHH          ES:DI (current position)               HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, CX                                 HHH
;HHH          DI                                     HHH
;HHH                                                 HHH
;HHH=================================================HHH

putHex proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    
    ;---------------------------------------------
    
    ; ax - current num
    ; ch - text color
    ; cl - 4*#digits = current displacement
    
    ;color
    mov ch, ah

    ; displacement
    mov cl, 0
    
    ; num
    mov ax, [bp + 4]
    
putHex_step:      
    ; ax % 16 <=> last 4 bits (mask 1111 = F)
    and ax, 0Fh
    
    ; converting to char depends on value:
    ;  0... 9 -> '0'...'9'
    ; 10...15 -> 'A'...'F'
    cmp al, 10
    jb putHex_isnum
        add al, 'A' - 10 - '0'
putHex_isnum:
    add al, '0'
    mov ah, ch
    push ax
    
    ; displacement += 4 bit
    add cl, 4
    mov ax, [bp + 4]
    shr ax, cl
    
    cmp ax, 0
    jne putHex_step
    
    ; cl * 2 => cx
    ; (cl * 2) = #digits / 2 = #bytes to print
    shr cl, 2
    mov ch, 0
    
    cld
    
putHex_loop:
    pop ax
    stosw
    loop putHex_loop
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp

;=======================================================

.data

printf_err_formattype   db '[ERROR: unknown variable type: %%%c]', 0
printf_err_specsym      db '[ERROR: unknown special symbol: \\%c]', 0

end
