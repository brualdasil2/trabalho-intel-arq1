    .model small
    .stack

    .data
; ============
;| CONSTANTES |
; ============
CR  equ 13
LF  equ 10
BS  equ 8
ESCAPECHAR equ 27


; ============
;| VARIAVEIS  |
; ============

newLine db CR, LF, 0
l1Board db  "+--1--2--3--4--5--6--7--+", 0
l2Board db  "|                       |", 0
l3Board db  "+-----------------------+", 0
playInstruct1 db "1-7 - Movimentacao de pecas.", CR, LF, 0
playInstruct2 db "Z   - Recomecar o jogo.", CR, LF, 0
playInstruct3 db "R   - Ler arquivo de jogo.", CR, LF, 0
playInstruct4 db "G   - Gravar arquivo de jogo", CR, LF, 0
replayInstruct1 db "N - Proximo movimento", CR, LF, 0
replayInstruct2 db "Outras teclas - encerra leitura", CR, LF, 0
replayInstruct3 db "Tecla lida: ", 0
recordInstruct1 db "ESC - encerrar a gravacao", CR, LF
confirmExitRecordMsg db "Encerrar a gravacao? (S/N)", 0
requestFileNameMsg db "Digite o nome do arquivo:", CR, LF, 0
invalidMoveMsg db "Movimento invalido!", 0
youWinMsg  db "Voce VENCEU! Pressione qualquer tecla pra recomecar.", 0
youLoseMsg db "Voce PERDEU! Pressione qualquer tecla pra recomecar.", 0
openFileErrorMsg db "Erro ao abrir o arquivo. Pressione qualquer tecla para voltar.", 0
endReplayMsg db "Fim do replay. Pressione qualquer tecla para voltar ao jogo normal.", 0
replayMoveMade db 0, 0
fileBuffer db 10 dup (?)
readMovesIndex dw 0
replayInitPos db 7 dup (0)
replayMoves db 30 dup (0)
replayMovesIndex dw 0
fileHandle dw 0
boardPos db 7 dup (?)
boardInitPos db "AAAxVVV"
charPiece db "x", 0
replaying db 0
recording db 0

fileName  db  100 dup(?)
ptString    dw  0

    .code
    .startup
    call reset
startRound:
    call drawBoard  ;desenha tabuleiro e pecas
    call drawPieces
    mov dl, 0
    mov dh, 15      ;ajusta cursor
    call setCursor
    call checkWinLoss   ;avalia se a posicao é vencedora, perdedora, ou se segue o jogo
    cmp ax, 1
    je  victory
    cmp ax, 2
    je  loss
    jmp keepPlaying
victory:
    lea bx, youWinMsg
    call printf
    call getKey     ;espera qualquer tecla pra reiniciar
    call reset
    jmp startRound
loss:
    lea bx, youLoseMsg
    call printf
    call getKey     ;espera qualquer tecla pra reiniciar
    call reset
    jmp startRound


keepPlaying:
    cmp replaying, 1    ;testa se está dando replay ou gravando
    je  replayPreMove
    jmp normalPlay
replayPreMove:
    lea bx, replayInstruct1 ;exibe instrucoes na tela
    call printf
    lea bx, replayInstruct2
    call printf
    lea bx, replayInstruct3
    call printf
    lea si, replayMoves
    mov bp, replayMovesIndex
    mov bl, byte ptr [si+bp-1]  ;move o movimento passado para bl
    mov al, byte ptr [si+bp]    ;move o proximo movimento para al
    cmp al, '0'
    je  exitReplay      ;se chegou ao fim, sai
    inc replayMovesIndex    ;incrementa indice do movimento
    push ax
    mov replayMoveMade, bl
    lea bx, replayMoveMade  ;exibe na tela o ultimo movimento realizado
    call printf 
    call getKey     ;aguarda tecla N
    cmp al, 'N'
    je  continueReplay
    cmp al, 'n'
    je continueReplay
    jmp exitReplay
continueReplay:
    call clearScreen
    pop ax
    sub al, 31h     ;transforma de ascii para indice de vetor ('1' -> 0; '2' -> 1; etc)
    mov ah, 0
    call movePiece  ;move a peca
    jmp startRound
exitReplay:
    mov replayMoveMade, bl
    lea bx, replayMoveMade  ;exibe na tela o ultimo movimento realizado
    call printf 
    lea bx, newLine
    call printf 
    lea bx, endReplayMsg
    call printf 
    call getKey
    mov replaying, 0    ;sai do modo replay
    call clearScreen
    mov bx, fileHandle
    mov	ah,3eh          ;fecha arquivo
	int	21h
    jmp startRound
checkEndRecording:
    lea bx, confirmExitRecordMsg
    call printf
repeatYesNo:
    call getKey
    cmp al, 's'
    je  yesEndRec
    cmp al, 'S'
    je  yesEndRec
    cmp al, 'n'
    je  noEndRec 
    cmp al, 'N'
    je  noEndRec
    jmp repeatYesNo
yesEndRec:
    mov dl, '0'
    mov bx, fileHandle
    call fPutChar
    mov bx, fileHandle
    call fclose
    mov recording, 0
    call clearScreen
    jmp startRound
noEndRec:
    jmp startRound
normalPlay:
    lea bx, playInstruct1   ;exibe instrucoes na tela
    call printf
    lea bx, playInstruct2
    call printf
    lea bx, playInstruct3
    call printf
    lea bx, playInstruct4
    call printf


    call getKey     ;recebe tecla do usuario
    push ax
    call clearScreen
    pop ax
    cmp recording, 0
    je  skipEsc
    cmp al, ESCAPECHAR
    je  checkEndRecording
    jmp skipNotNumbers
skipEsc:
    cmp al, 'z'     ;testa se é um numero ou uma tecla de comando
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
skipNotNumbers:
    cmp al, '1'
    jl  ignoreKey
    cmp al, '7'
    jg  ignoreKey
    cmp recording, 0
    je  skipRecordMove
    mov bx, fileHandle
    mov dl, al
    push ax
    call fPutChar
    pop ax
skipRecordMove:
    sub al, 31h     ;transforma de ascii para indice de vetor ('1' -> 0; '2' -> 1; etc)
    mov ah, 0
    call movePiece
    jmp startRound  ;retorna ao inicio do loop de jogo
restartGame:
    call reset
    jmp startRound

replayGame:
    mov dl, 0   ;posiciona o cursor
    mov dh, 20
    call setCursor
    lea bx, requestFileNameMsg  ;exibe msg de leitura
    call printf
    lea bx, fileName
    call readString     ;lê o nome do arquivo
    lea dx, fileName
    call readFile
    cmp ax, 1     
    je  erroReadFile
    mov replaying, 1    ;se não houve erro, ativa flag do modo replay
    lea si, replayInitPos
    lea di, boardPos
    mov cx, 7
    call moveByteArea   ;copia os caracteres da posicao inicial do arquivo para o tabuleiro
    mov replayMovesIndex, 0
    jmp startRound
erroReadFile:
    lea bx, openFileErrorMsg    ;mensagem de erro de abertura
    call printf
    call getKey
    jmp startRound
recordGame:
    mov dl, 0   ;posiciona o cursor
    mov dh, 20
    call setCursor
    lea bx, requestFileNameMsg  ;exibe msg de leitura
    call printf
    lea bx, fileName
    call readString     ;lê o nome do arquivo
    lea dx, fileName
    call createFile     ;cria o arquivo e escreve a posicao inicial nele
    mov recording, 1
    jmp startRound
ignoreKey:
    jmp startRound
    .exit

; ============
;| SUBROTINAS |
; ============
reset PROC near
    ;inicialização de variaveis

    lea si, boardInitPos    ;deixa tabuleiro na posicao inicial
    lea di, boardPos
    mov cx, 7
    call moveByteArea


    ;modo de tela
    call clearScreen


    ret
reset ENDP

;move uma área de tamanho cx do endereço si até o di
moveByteArea proc near
    mov bp, 0
loopMoveArea:
    mov al, byte ptr [si+bp]
    mov [di+bp], al
    inc bp
    loop loopMoveArea
    ret
moveByteArea endp

createFile proc near  
    mov ah, 3ch
    mov cx, 0
    int 21h 
    mov fileHandle, ax
    jnc continue1CF
    mov ax, 1
    ret
continue1CF:
    mov cx, 7
    lea si, boardPos
    mov bp, 0
loopWritePosFile:
    mov bx, fileHandle
    mov dl, byte ptr [si+bp]
    call fPutChar
    inc bp
    loop loopWritePosFile
    mov bx, fileHandle
    mov dl, CR
    call fPutChar
    mov bx, fileHandle
    mov dl, LF
    call fPutChar

    ret
createFile endp

fclose	proc	near
	mov	ah, 3eh
	int	21h
	ret
fclose	endp

fPutChar proc near 
    push cx
    mov ah, 40h
    mov cx, 1
    mov fileBuffer, dl
    lea dx, fileBuffer
    int 21h 
    pop cx
    ret
fPutChar endp

;lê o arquivo de texto, copia para var internas seu conteudo, e retorna sucesso em ax
readFile proc near
    mov ah, 3dh
    mov al, 0
    int 21h     ;abre arquivo
    jnc continue1RF
    mov ax, 1   ;erro
    ret
continue1RF:
    mov fileHandle, ax
    mov bx, fileHandle
    mov ah, 3fh
    mov cx, 7  
    lea dx, fileBuffer
    int 21h         ;lê a posicao inicial
    jnc continue2RF
    mov ax, 1
    mov bx, fileHandle
    call fclose
    ret
continue2RF:
    lea si, fileBuffer
    lea di, replayInitPos
    mov cx, 7
    call moveByteArea   ;copia o buffer pro vetor da posicao inicial do replay
skipReadChar:
    mov bx, fileHandle
    mov ah, 3fh
    mov cx, 1 
    lea dx, fileBuffer
    int 21h             ;lê um char de cada vez
    jnc continue3RF
    mov ax, 1
    mov bx, fileHandle
    call fclose
    ret
continue3RF:
    cmp fileBuffer, '1'     ;testa se o char é de 1 a 7 (pra pular o CR ou LF do fim da primeira linha)
    jl  skipReadChar
    cmp fileBuffer, '7'
    jg  skipReadChar
    jmp continue4RF
loopReadFileMoves:
    mov bx, fileHandle
    mov ah, 3fh
    mov cx, 1 
    lea dx, fileBuffer
    int 21h         ;lê um char do arquivo (um numero de movimento)
    jnc continue4RF
    mov ax, 1
    mov bx, fileHandle
    call fclose
    ret
continue4RF:
    cmp fileBuffer, '0' ;se for 0, terminaram as jogadas
    je fimReadFile  
    mov bx, readMovesIndex  ;se nao foi 0, coloca a jogada lida no fim do vetor de jogadas
    lea di, replayMoves
    lea si, fileBuffer
    mov al, byte ptr [si]
    mov [di+bx], al
    inc readMovesIndex
    jmp loopReadFileMoves
fimReadFile:
    mov bx, readMovesIndex
    lea di, replayMoves
    mov [di+bx], '0'    ;salva o 0 no fim do vetor
    mov ax, 0
    ret
readFile endp

;recebe o indice de movimento em al e faz o movimento se possivel
movePiece proc near
    lea bp, boardPos
    mov si, ax
    cmp [bp+si], byte ptr 'A'   ;testa se o char a mover é A ou V
    je  moveA
    cmp [bp+si], byte ptr 'V'
    je  moveV
    jmp invalidMove
moveA:
    cmp [bp+si+1], byte ptr 'x' ;testa se a posicao do lado está vazia
    je  moveAone
    cmp [bp+si+1], byte ptr 'V' ;testa se a posicao do lado tem um V
    je  skipA1
    jmp invalidMove ;caso contrario, movimento invalido
moveAone:
    mov [bp+si], byte ptr 'x'   ;move o A pra direita
    mov [bp+si+1], byte ptr 'A'
    ret
skipA1:
    cmp [bp+si+2], byte ptr 'x' ;testa se a posicao 2 pro lado está vazia
    je  skipA2
    jmp invalidMove
skipA2:
    mov [bp+si], byte ptr 'x'   ;move o A duas casas pra direita
    mov [bp+si+2], byte ptr 'A'
    ret
moveV:
    cmp [bp+si-1], byte ptr 'x' ;movimentação do V é análoga à do A, mas pra esquerda
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
    lea bx, invalidMoveMsg  ;avisa que o movimento é invalido
    call printf
    ret
movePiece endp

;testa todos os movimentos possiveis e retorna 1 em caso de vitoria, 2 em caso de derrota, e 0 caso contrario
checkWinLoss proc near
    lea bp, boardPos
    mov si, 0
    mov cx, 7

loopCheckValid:
    cmp [bp+si], byte ptr 'A'   ;mesma lógica da funcao movePiece: testa se o movimento do indice si é valido (mas nao faz o movimento)
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
    mov ax, 0   ;se algum dos 7 movimentos for válido, retorna 0
    ret

CinvalidMove:
    inc si              ;movimento do indice si era invalido, incrementa e repete para o proximo indice
    loop loopCheckValid
    lea bp, boardPos        ;chegou aqui, os 7 movimentos sao invalidos
    cmp [bp], byte ptr 'V'  ;testa se a posicao é a vencedora (VVVxAAA), se não for, perdeu o jogo
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

;imprime na tela o retangulo do tabuleiro vazio
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

;imprime na tela as pecas do vetor boardPos
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
    lea di, charPiece   ;salva endereço da string pra imprimir
    mov al, [bp+si] ;move a peca do indice atual para al
    cmp al, 'x'     ;se for 'x', deixa al como '.'
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

