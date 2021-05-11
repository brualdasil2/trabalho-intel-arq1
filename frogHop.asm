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

l1Board db  "+--1--2--3--4--5--6--7--+", 0
l2Board db  "|                       |", 0
l3Board db  "+-----------------------+", 0
boardPos db "AAAxVVV"
charPiece db "x", 0

stringDigitada  db  100 dup(?)
ptString    dw  0

    .code
    .startup
    call reset
    call drawBoard
    call drawPieces
    mov dl, 0
    mov dh, 15
    call setCursor

    .exit

; ============
;| SUBROTINAS |
; ============
reset PROC near
    ;inicialização de variaveis

    ;modo de tela
    call clearScreen


    ret
reset ENDP

drawBoard proc near
    mov dh, 5
    mov dl, 20
    call setCursor
    lea bx, l1Board
    call printf
    mov dh, 6
    mov dl, 20
    call setCursor
    lea bx, l2Board
    call printf
    mov dh, 7
    mov dl, 20
    call setCursor
    lea bx, l2Board
    call printf
    mov dh, 8
    mov dl, 20
    call setCursor
    lea bx, l2Board
    call printf
    mov dh, 9
    mov dl, 20
    call setCursor
    lea bx, l3Board
    call printf
    ret
drawBoard endp

drawPieces proc near
    mov dl, 20
    mov cx, 7
    lea bp, boardPos
    mov si, 0
loopDrawPieces:
    mov dh, 7
    add dl, 3
    push dx
    push si
    call setCursor
    lea di, charPiece
    mov al, [bp+si]
    cmp al, 'x'
    jne  skipDot
    mov al, '.'
skipDot:
    mov [di], al   ;charPiece[0] = boardPos[si]
    lea bx, charPiece
    call printf         ;printf charPiece
    pop si
    pop dx
    inc si
    loop loopDrawPieces
    ret
drawPieces endp

clearScreen proc near
    mov ah, 0
    mov al, 07h
    int 10h
    ret
clearScreen endp

;	mov		dh,linha
;	mov		dl,coluna
;	call	SetCursor
setCursor   proc	near
	mov	ah,2
	mov	bh,0
	int	10h
	ret
setCursor	endp

;retorna em al o char lido
getKey	proc	near
	mov		ah,7
	int		21H
	ret
getKey	endp

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

