ORG 0000H

MOV SP, #60H         ; Set stack pointer

ACALL INIT_LCD       ; Initialize LCD

; Write "HELLO"
MOV A, #'H'
ACALL LCD_CHAR
MOV A, #'E'
ACALL LCD_CHAR
MOV A, #'L'
ACALL LCD_CHAR
MOV A, #'L'
ACALL LCD_CHAR
MOV A, #'O'
ACALL LCD_CHAR

HERE: SJMP HERE

;===================================
; Initialize LCD in 4-bit mode
;===================================
INIT_LCD:
    ACALL DELAY_20MS

    MOV A, #03H         ; Wake-up sequence (x3)
    ACALL LCD_CMD_4BIT
    ACALL DELAY_5MS
    ACALL LCD_CMD_4BIT
    ACALL DELAY_5MS
    ACALL LCD_CMD_4BIT
    ACALL DELAY_5MS

    MOV A, #02H         ; Set 4-bit mode
    ACALL LCD_CMD_4BIT
    MOV A, #28H         ; 4-bit, 2-line, 5x8 font
    ACALL LCD_CMD
    MOV A, #0CH         ; Display ON, cursor OFF
    ACALL LCD_CMD
    MOV A, #01H         ; Clear display
    ACALL LCD_CMD
    ACALL DELAY_5MS
    MOV A, #06H         ; Entry mode
    ACALL LCD_CMD
    RET

;===================================
; Write full command (split upper/lower nibbles)
;===================================
LCD_CMD:
    MOV R5, A
    SWAP A
    ANL A, #0F0H
    ACALL SEND_NIBBLE
    MOV A, R5
    ANL A, #0F0H
    ACALL SEND_NIBBLE
    ACALL DELAY_2MS
    RET

;===================================
; Write single upper nibble (used for wake-up)
;===================================
LCD_CMD_4BIT:
    ANL A, #0F0H
    ACALL SEND_NIBBLE
    ACALL DELAY_2MS
    RET

;===================================
; Write character
;===================================
LCD_CHAR:
    SETB P2.0         ; RS = 1
    CLR P2.1          ; RW = 0
    MOV R5, A
    SWAP A
    ANL A, #0F0H
    ACALL SEND_NIBBLE
    MOV A, R5
    ANL A, #0F0H
    ACALL SEND_NIBBLE
    ACALL DELAY_2MS
    RET

;===================================
; Send upper nibble (to P2.4–P2.7)
;===================================
SEND_NIBBLE:
    CLR P2.4
    CLR P2.5
    CLR P2.6
    CLR P2.7
    ORL P2, A          ; Output nibble on P2.4–P2.7
    SETB P2.2          ; EN = 1
    NOP
    CLR P2.2           ; EN = 0
    RET

;===================================
; Delay ~2ms
;===================================
DELAY_2MS:
    MOV R7, #250
DLY1: MOV R6, #250
DLY2: DJNZ R6, DLY2
    DJNZ R7, DLY1
    RET

; Delay ~5ms
DELAY_5MS:
    ACALL DELAY_2MS
    ACALL DELAY_2MS
    ACALL DELAY_2MS
    RET

; Delay ~20ms
DELAY_20MS:
    ACALL DELAY_5MS
    ACALL DELAY_5MS
    ACALL DELAY_5MS
    ACALL DELAY_5MS
    RET

END
