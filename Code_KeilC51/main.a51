ORG 0000H
	
;=========================================================
;   -REG_VAL-
;=========================================================
MOV SP, #60H        ; Set up a safe stack pointer
MOV P0, #00H        ; LCD output
MOV P1, #0FFH       ; ADC input
MOV P2, #00H        ; LED output


MOV B,  #00H
MOV R0, #00H        ; TEMP_VAL
MOV R6, #00H        ; Delay Reg
MOV R7, #00H        ; Delay Reg
;=========================================================
;   -DEFINES-
;=========================================================
;I2C Pins
RS  EQU P2.0
RW  EQU P2.1
EN  EQU P2.2

D4  EQU P2.4
D5  EQU P2.5
D6  EQU P2.6
D7  EQU P2.7
;=========================================================
;                           -MAIN-
;=========================================================
MAIN:
	
    ACALL READ_AVG_ADC
    MOV A, R0
    CJNE A, 30h, UPDATE_LCD
    SJMP SKIP_UPDATE

UPDATE_LCD:
    MOV 30h, A
    ACALL LCD_INIT         
    ACALL DISPLAY_TEMP
    MOV A, 30h
    ACALL DISPLAY_VALUE
    ACALL DISPLAY_doC

SKIP_UPDATE:
    ACALL DELAY1MS
    SJMP MAIN
	
;-------------------------
; -ADC0804-    
;-------------------------
READ_ADC:
    CLR P3.7        ; CS = 0
    SETB P3.6       ; RD = 1   
    CLR P3.5        ; WR = 0
    NOP
    SETB P3.5       ; WR = 1
    NOP
WAIT_INTR:
    JB P3.4, WAIT_INTR  
    CLR P3.7        ; CS = 0
    CLR P3.6        ; RD = 0
    ACALL DELAY5US
    MOV R0, P1
    RET
	
; H m t nh trung b nh ADC_Value

READ_AVG_ADC:
    MOV R5, #00H        ; Low byte sum
    MOV R6, #00H        ; High byte sum
    MOV R7, #04H        ; Lay 4 sample 

AVG_LOOP:
    ACALL READ_ADC      ; R0 chua gia tri ADC
    MOV A, R0
    ADD A, R5           ; Cong low byte vao A = A + R5 (neu tran A th  C = 1)
    MOV R5, A           ; Dua 8bit LSB ve R5
    JNC SKIP_INC_HI     ; C = 0 thi tiep tuc lay mau
    INC R6              ; C = 1 thi tang R6 = R6 + 1

SKIP_INC_HI:
    ACALL DELAY1MS
    DJNZ R7, AVG_LOOP

; Chia R6:R5 cho 4
    ; Dich phai 2 lan cac thanh ghi R6, R5
    MOV A, R6         
    RRC A
    MOV R6, A
    MOV A, R5          
    RRC A
    MOV R5, A

    MOV A, R6       
    RRC A
    MOV R6, A
    MOV A, R5
    RRC A
    MOV R0, A          
    RET
;------------------------
; -1602 Interface
;------------------------


SEND_NIBBLE:
	;; CHO A CHUA 4 BIT D4-D7
	;; RESET CAC CHAN DATA
	CLR D4
	CLR D5
	CLR D6
	CLR D7
	
	
	MOV C, ACC.4
	MOV D4, C
	MOV C, ACC.5
	MOV D5, C
	MOV C, ACC.6
	MOV D6, C
	MOV C, ACC.7
	MOV D7, C
	
	;EN 1->0
	SETB EN
	ACALL DELAY1MS
	CLR EN
	ACALL DELAY1MS
	
	RET
	
SEND_CMD_LCD:
	CLR RS  ;RS=0 -> send cmd
	CLR RW  ;RW=0 -> write mode
    ACALL SEND_NIBBLE       ; Send upper nibble
    SWAP A
    ACALL SEND_NIBBLE       ; Send lower nibble
    RET	

SEND_DATA_LCD:	
    SETB RS     ; RS = 1 for data
    CLR RW      ; RW = 0 for write
    ACALL SEND_NIBBLE
    SWAP A
    ACALL SEND_NIBBLE
    RET	
	
LCD_INIT:
	ACALL DELAY20MS
	
	
    ; Optional  robust  entry sequence if you ever see weird behaviors
    MOV A,#03H  
	ACALL SEND_CMD_LCD
    ACALL DELAY5US
    
	MOV A,#03H  
	ACALL SEND_CMD_LCD
    ACALL DELAY5US
	
	; 4bit mode
	MOV A, #02H
	ACALL SEND_CMD_LCD
	; Initialization of 16X2 LCD in 4bit mode
	MOV A, #28H
	ACALL SEND_CMD_LCD
	; Display ON Cursor OFF
	MOV A, #0CH
	ACALL SEND_CMD_LCD
	; Auto Increment cursor
	MOV A, #06H
	ACALL SEND_CMD_LCD
	; Clear display
	MOV A, #01H
	ACALL SEND_CMD_LCD
	ACALL DELAY1MS        ; ? wait for clear ( 1.5 ms)
	ACALL DELAY1MS        ; ? wait for clear ( 1.5 ms)
	; DRAM pos = 0
	MOV A, #80H
	ACALL SEND_CMD_LCD
	ACALL DELAY1MS        ; ? wait for clear ( 1.5 ms)
	ACALL DELAY1MS        ; ? wait for clear ( 1.5 ms)
	
	RET
	
DISPLAY_VALUE:
	;Chuyen doi R0 thanh hang tram/chuc/donvi
	MOV A, R0
	MOV B, #100
	
	DIV AB      ;A chua thuong, B chua so du
	MOV R1, A   ;hang tram
	
	MOV A, B    ;A chua so du
	MOV B, #10
	DIV AB
	MOV R2, A   ;hang chuc
	
	MOV R3, B   ;hang don vi
	
	
    ; Bo qua so 0 o hang tram
    MOV A, R1
    JZ SKIP_HUNDREDS   ; neu R1 == 0, nhay toi in hang chuc
    ADD A, #30H        ; Chuyen doi sang ASCII (+ 0x30 offset)
    ACALL SEND_DATA_LCD	
	
SKIP_HUNDREDS:
    MOV A, R1
    JNZ PRINT_TENS     ; In hang chuc, mac dinh sau khi in hang tram
    
	;Bo qua so 0 o hang chuc
    MOV A, R2
    JZ SKIP_TENS       ; Neu R2 == 0 va R1 == 0, nhay toi SKIP_TENS	
; In hang chuc, mac dinh sau khi in hang tram (JNZ PRINT_TENS)
PRINT_TENS:
    MOV A, R2
    ADD A, #30H
    ACALL SEND_DATA_LCD

SKIP_TENS:
    MOV A, R1
    ORL A, R2          ; R1 va R2 deu bang 0 thi in don vi
    JNZ PRINT_ONES     ; 

    MOV A, R3
    JZ PRINT_ZERO      ; In 0 neu VAL(R0) = 000
PRINT_ONES:
    MOV A, R3
    ADD A, #30H
    ACALL SEND_DATA_LCD
    SJMP END_PRINT

PRINT_ZERO:
    MOV A, #'0'
    ACALL SEND_DATA_LCD

END_PRINT:
	RET
	
	
DISPLAY_TEMP:
    MOV DPTR, #MSG
NEXT_CHAR:
    CLR A 
    MOVC A, @A+DPTR          ;read 1 byte tai DPTR + A(offset, default A=0) 
	                         ;dung A tai day de dung format MOVC
    JZ END_MSG               ;jump neu gap null 0x00
    ACALL SEND_DATA_LCD
    INC DPTR                 ;tang DPTR de doc byte tiep theo
    SJMP NEXT_CHAR
END_MSG:
    RET

MSG: DB 'TEMP: ', 0 ;CHO MSG thanh chuoi cac 8bit v  add nullptr 0x00 o cuoi
	                ;MSG se chua dia chi cua string

DISPLAY_doC:
    MOV DPTR, #MSG_doC
NEXT_CHAR_doC:
    CLR A 
    MOVC A, @A+DPTR          ;read 1 byte tai DPTR + A(offset, default A=0) 
	                         ;dung A tai day de dung format MOVC
    JZ END_MSG_doC           ;jump neu gap null 0x00
    ACALL SEND_DATA_LCD
    INC DPTR                 ;tang DPTR de doc byte tiep theo
    SJMP NEXT_CHAR_doC
END_MSG_doC:
    RET

MSG_doC: DB ' oC', 0 ;CHO MSG thanh chuoi cac 8bit v  add nullptr 0x00 o cuoi

	
;-------------------------
; -ULT FUNC (dùng Timer0)-    
;-------------------------    


DELAY5US:
    NOP
	NOP
	NOP
	RET

DELAY1MS:
    MOV TMOD, #01H
    MOV TH0, #0FCH
    MOV TL0, #018H
    SETB TR0

WAIT_T0_1MS:
    JNB TF0, WAIT_T0_1MS
    CLR TR0
    CLR TF0
    RET

DELAY20MS:
    MOV R7, #20
D20MS_LOOP:
    ACALL DELAY1MS
    DJNZ R7, D20MS_LOOP
    RET

END	