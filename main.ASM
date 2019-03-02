;HHH========================================================================HHH;
;HHH                                                                        HHH;
;HHH                      Simple version ofb printf                        HHH;
;HHH                                                                        HHH;
;HHH========================================================================HHH;

.model tiny

;   Machine constants

VIDEO_MEM  = 0b800h

.code

extrn printf : proc
extrn putDec : proc
extrn putBin : proc
extrn putHex : proc

org 100h

start:
    ; clear window
    mov ax, 2h
    int 10h
    
    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax
    
    ; di -> beginning of video vemory
    mov di, 0
    
    ; parameters
    push offset str1 ; 1
    push 'H'        ; 2
    push 3802       ; 3
    push 3802       ; 4
    push 3802       ; 5
    push offset form1 ; 6
    mov ah, 07h     ; color
    call printf
    add sp, 2 * 6
    
    ; parameters
    push 200        ; 1
    push offset form2 ; 2
    mov ah, 03h     ; color
    call printf
    add sp, 2 * 2
    
    mov ax, 4c00h
    int 21h
    
.data

form1           db 'meow\\\n%d(10) = %b(2) = %x(16) %c%s 100%% some\b\b\b\bnone\n\0 trash', 0
str1            db 'ello, world!', 0
form2           db 'This string has just got printed: %d%% gureto\n', 0

end start
