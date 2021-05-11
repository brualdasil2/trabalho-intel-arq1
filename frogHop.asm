    .model small
    .stack

    .data
; ============
;| CONSTANTES |
; ============
CR  equ 13
LF  equ 10
BS  equ 8

; ============
;| VARIAVEIS  |
; ============
string  db  "hello world", CR, LF, 0
stringDigitada  db  100 dup(?)
ptString    dw  0

    .code
    .startup
    



    .exit

; ============
;| SUBROTINAS |
; ============
;lea bx, string
;call printf
printf PROC near
inicioPrintf:
    mov dl, [bx]
    cmp dl, 0
    je fimPrintf
    mov ah, 2       
    mov dl, [bx]
    int 21h
    add bx, 1
    jmp inicioPrintf
fimPrintf:
    ret
printf ENDP

;lea bx, stringDigitada
;call readString
readString PROC near
    mov ptString, bx
    mov bx, 0
loopReadString:
    mov ah, 7
    int 21h
    cmp al, CR
    je fimReadString
    cmp al, BS
    je backSpace
    mov di, ptString
    mov [bx+di], al
    inc bx
    ;putchar
    mov ah, 2
    mov dl, al
    int 21h 
    jmp loopReadString
backSpace:
    cmp bx, 0             
    je loopReadString
    dec bx
    mov di, ptString
    mov [bx+di], 0
    mov ah, 2
    mov dl, BS
    int 21h 
    mov ah, 2
    mov dl, ' '
    int 21h 
    mov ah, 2
    mov dl, BS
    int 21h 
    jmp loopReadString
fimReadString:
    mov di, ptString
    mov [bx+di], 0
    mov ah, 2
    mov dl, CR
    int 21h 
    mov ah, 2
    mov dl, LF
    int 21h 
    ret
readString ENDP
    end

