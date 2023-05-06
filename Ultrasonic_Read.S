;------------------------
; Assembly Code
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main
;------------------------

main:
;--------------
    SBI   DDRB, 1         ;pin PB1 as o/p (Trigger)
    CBI   DDRB, 0         ;pin PB0 as i/p (Echo)
	RCALL init_serial
agn:SBI   PORTB, 1
    RCALL delay_timer0
    CBI   PORTB, 1        ;send 10us high pulse to sensor
    ;-----------------------------------------------------------
    RCALL read_distance         ;compute Echo pulse width count
	RCALL print_result
	RCALL print_newline
    ;-----------------------------------------------------------

    ;-----------------------------------------------------------
    RCALL delay_ms
    RJMP  agn
;===============================================================
; HC SR 04 Sensor
;===============================================================
read_distance:
;-------
    LDI   R20, 0b00000000
    STS   TCCR1A, R20     ;Timer 1 normal mode
    LDI   R20, 0b11000101 ;set for rising edge detection &
    STS   TCCR1B, R20     ;prescaler=1024, noise cancellation ON
    ;-----------------------------------------------------------
l1: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l1              ;loop until rising edge is detected
    ;-----------------------------------------------------------
    LDS   R16, ICR1L      ;store count value at rising edge
    ;-----------------------------------------------------------
    OUT   TIFR1, R21      ;clear flag for falling edge detection
    LDI   R20, 0b10000101
    STS   TCCR1B, R20     ;set for falling edge detection
    ;-----------------------------------------------------------
l2: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l2              ;loop until falling edge is detected
    ;-----------------------------------------------------------
    LDS   R28, ICR1L      ;store count value at falling edge
    ;-----------------------------------------------------------
    SUB   R28, R16        ;count diff R28 = R28 - R16
    OUT   TIFR1, R21      ;clear flag for next sensor reading
    RET

delay_timer0:             ;10 usec delay via Timer 0
;------------
    CLR   R20
    OUT   TCNT0, R20      ;initialize timer0 with count=0
    LDI   R20, 20
    OUT   OCR0A, R20      ;OCR0 = 20
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 8
    ;-----------------------------------------------------------
l0: IN    R20, TIFR0      ;get TIFR0 byte & check
    SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  l0              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20      ;clear OCF0 flag
    RET
;===============================================================
; Serial
;===============================================================
init_serial:
	CLR R24
	STS UCSR0A, R24 ;clear UCSR0A register
	STS UBRR0H, R24 ;clear UBRR0H register
	LDI R24, 103 ;& store in UBRR0L 103 value
	STS UBRR0L, R24 ;to set baud rate 9600
	LDI R24, 1<<RXEN0 | 1<<TXEN0 ;enable RXB & TXB
	STS UCSR0B, R24
	LDI R24, 1<<UCSZ00 | 1<<UCSZ01;asynch, no parity, 1 stop, 8 bits
	STS UCSR0C, R24
	RET
agn_buffer:
	LPM R18, Z+ ;load char of string onto R18
	CPI R18, 0 ;check if R18=0 (end of string)
	BRNE buffer ;if yes, exit
	RET
buffer:
	RCALL LCD_buffer
	STS UDR0, R18 ;send char in R18 to serial monitor
	RJMP agn_buffer ;loop back & get next character
ASCII_MSD:
	MOV R23, R16 ;save copy of result
	ANDI R16, 0xF0 ;extract & swap high-nibble
	SWAP R16
	SUBI R16, -48 ;R16 = R16 - (48) = R16 + 48
	MOV R20, R16 ;save a copy of high-byte result
	SUBI R20, 58 ;if +ve
	BRPL A_F_D1 ;branch & add 7 to get ASCII A to F
	RET
A_F_D1:
	SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
	RET
ASCII_LSD:
	MOV R16, R23 ;restore copy of result
	ANDI R16, 0x0F ;extract low-nibble
	SUBI R16, -48 ;R16 = R16 - (48) = R16 + 48
	MOV R20, R16 ;save a copy of high-byte result
	SUBI R20, 58 ;if +ve
	BRPL A_F_D0 ;branch & add 7 to get ASCII A to F]
	RET
A_F_D0:
	SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
	RET
LCD_buffer:
	LDS R27, UCSR0A
	SBRS R27, UDRE0 ;test data buffer if data can be sent
	RJMP LCD_buffer
	RET
print_result:
	MOV R16, R28
	RCALL ASCII_MSD ;generate ASCII of MSD of result
	RCALL LCD_buffer ;LCD buffer ready?
	STS UDR0, R16 ;print digit 3 of 16-bit result (MSD)
	RCALL ASCII_LSD ;generate ASCII of LSD of result
	RCALL LCD_buffer ;LCD buffer ready?
	STS UDR0, R16 ;print LSD of result on serial monitor
	RET
print_newline:
	RCALL LCD_buffer ;LCD buffer ready?
	LDI R18, 32
	STS UDR0, R18 ;print space on serial monitor
	RCALL LCD_buffer ;LCD buffer ready?
	LDI R18, 0x0A
	STS UDR0, R18 ;print newline on serial monitor
	RCALL LCD_buffer ;LCD buffer ready?
	LDI R18, 0x0D
	STS UDR0, R18 ;print carriage return on serial monitor
	RET
;===============================================================
delay_ms:
;--------
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 50
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET