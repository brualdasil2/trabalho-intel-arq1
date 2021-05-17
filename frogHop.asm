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
playInstruct1 db "1-7 - Movimentacao de pecas.", CR, LF, 0
playInstruct2 db "Z   - Recomecar o jogo.", CR, LF, 0
playInstruct3 db "R   - Ler arquivo de jogo.", CR, LF, 0
playInstruct4 db "G   - Gravar arquivo de jogo", CR, LF, 0
invalidMoveMsg db "Movimento invalido!", 0
youWinMsg  db "Voce VENCEU! Pressione qualquer tecla pra recomecar.", 0
youLoseMsg db "Voce PERDEU! Pressione qualquer tecla pra recomecar.", 0
boardPos db 7 dup(0)
boardInitPos db "AAAxVVV"
charPiece db "x", 0
replaying db 0
recording db 0

stringDigitada  db  100 dup(?)
ptString    dw  0

    .code
    .startup
    call reset
startRound:
    call drawBoard
    call drawPieces
    mov dl, 0
    mov dh, 15
    call setCursor
    call checkWinLoss
    cmp ax, 1
    je  victory
    cmp ax, 2
    je  loss
    jmp keepPlaying
victory:
    lea bx, youWinMsg
    call printf
    call getKey
    call reset
    jmp startRound
loss:
    lea bx, youLoseMsg
    call printf
    call getKey
    call reset
    jmp startRound


keepPlaying:
    lea bx, playInstruct1
    call printf
    lea bx, playInstruct2
    call printf
    lea bx, playInstruct3
    call printf
    lea bx, playInstruct4
    call printf


    call getKey
    push ax
    call clearScreen
    pop ax
    cmp al, 'z'
    je  restartGame
    cmp al, 'Z'
    je  restartGame
    cmp al, 'r'
    je  replayGame
    cmp al, 'R'
    je  replayGame
    cmp al, 'g'
    je  recordGame
    cmp al, 'G'
    je  recordGame
    cmp al, '1'
    jl  ignoreKey
    cmp al, '7'
    jg  ignoreKey
    sub al, 31h
    mov ah, 0
    call movePiece
    jmp startRound
restartGame:
    call reset
    jmp startRound

replayGame:

recordGame:

ignoreKey:
    jmp startRound
    .exit

; ============
;| SUBROTINAS |
; ============
reset PROC near
    ;inicialização de variaveis

    lea si, boardInitPos
    lea di, boardPos
    mov cx, 7
    mov bp, 0
loopResetBoard:
    mov al, byte ptr [si+bp]
    mov [di+bp], al
    inc bp
    loop loopResetBoard


    ;modo de tela
    call clearScreen


    ret
reset ENDP

movePiece proc near
    lea bp, boardPos
    mov si, ax
    cmp [bp+si], byte ptr 'A'
    je  moveA
    cmp [bp+si], byte ptr 'V'
    je  moveV
    jmp invalidMove
moveA:
    cmp [bp+si+1], byte ptr 'x'
    je  moveAone
    cmp [bp+si+1], byte ptr 'V'
    je  skipA1
    jmp invalidMove
moveAone:
    mov [bp+si], byte ptr 'x'
    mov [bp+si+1], byte ptr 'A'
    ret
skipA1:
    cmp [bp+si+2], byte ptr 'x'
    je  skipA2
    jmp invalidMove
skipA2:
    mov [bp+si], byte ptr 'x'
    mov [bp+si+2], byte ptr 'A'
    ret
moveV:
    cmp [bp+si-1], byte ptr 'x'
    je  moveVone
    cmp [bp+si-1], byte ptr 'A'
    je  skipV1
    jmp invalidMove
moveVone:
    mov [bp+si], byte ptr 'x'
    mov [bp+si-1], byte ptr 'V'
    ret
skipV1:
    cmp [bp+si-2], byte ptr 'x'
    je  skipV2
    jmp invalidMove
skipV2:
    mov [bp+si], byte ptr 'x'
    mov [bp+si-2], byte ptr 'V'
    ret

invalidMove:
    mov dl, 0
    mov dh, 20
    call setCursor
    lea bx, invalidMoveMsg
    call printf
    ret
movePiece endp

checkWinLoss proc near
    lea bp, boardPos
    mov si, 0
    mov cx, 7

loopCheckValid:
    cmp [bp+si], byte ptr 'A'
    je  CmoveA
    cmp [bp+si], byte ptr 'V'
    je  CmoveV
    jmp CinvalidMove
CmoveA:
    cmp [bp+si+1], byte ptr 'x'
    je  CvalidMove
    cmp [bp+si+1], byte ptr 'V'
    je  CskipA1
    jmp CinvalidMove
CskipA1:
    cmp [bp+si+2], byte ptr 'x'
    je  CvalidMove
    jmp CinvalidMove
CmoveV:
    cmp [bp+si-1], byte ptr 'x'
    je  CvalidMove
    cmp [bp+si-1], byte ptr 'A'
    je  CskipV1
    jmp CinvalidMove
CskipV1:
    cmp [bp+si-2], byte ptr 'x'
    je  CvalidMove
    jmp CinvalidMove

CvalidMove:
    mov ax, 0
    ret

CinvalidMove:
    inc si
    loop loopCheckValid
    lea bp, boardPos
    cmp [bp], byte ptr 'V'
    jne lostGame
    cmp [bp+1], byte ptr 'V'
    jne lostGame
    cmp [bp+2], byte ptr 'V'
    jne lostGame
    cmp [bp+4], byte ptr 'A'
    jne lostGame
    cmp [bp+5], byte ptr 'A'
    jne lostGame
    cmp [bp+6], byte ptr 'A'
    jne lostGame
    mov ax, 1
    ret
lostGame:
    mov ax, 2
    ret
checkWinLoss endp

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

