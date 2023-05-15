#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

; PD1 = Enable relay 1
; PD2 = Enable relay 2
; PD6 = PWM Output
; PC0 = Analog input untuk potensiometer
; PC5 = RED Pin LED
; PC4 = GREEN Pin LED
; PC3 = BLUE Pin LED
; PC2 = BUZZER
; PB5 = CLK MAX7219
; PB3 = Din MAX7219
; PB2 = Clock Select
; PB1 = Trigger Pin HC-SR04
; PB0 = Echo Pin HC-SR04

;=============================================================================================
; MAIN PROGRAM
;=============================================================================================
main:
  ; Port D dan B sebagai output
  LDI R21, 0xFF   
  OUT DDRD, R21       ; Menjadikan pin D sebagai output
  OUT DDRB, R21       ; Menjadikan pin B sebagai output
  
  ; Analog input
  CBI DDRC, 0         ; Menjadikan pin A0 sebagai input analog
  
  ; Output untuk RGB LED
  SBI DDRC, 5
  SBI DDRC, 4
  SBI DDRC, 3
  ; Output untuk LED brake
  SBI DDRD, 7

  RCALL SPI_MAX7219_INIT
	RCALL MAX7219_disp_text
	RCALL HC_SR04_INIT
loop:
  SBI   PORTB, 1
  CBI PORTD,7 
  RCALL delay_timer0
  CBI   PORTB, 1        ;send 10us high pulse to sensor
  ;-----------------------------------------------------------
  ;-----------------------------------------------------------
  RCALL echo_PW         ;compute Echo pulse width count
  ;-----------------------------------------------------------
  RCALL COMPARE
  RCALL byte2decimal    ;covert & display on MAX7219
  ;-----------------------------------------------------------
  RCALL delay_ms
  RCALL INIT_ADC
  RCALL READ_ADC
RJMP loop ; 

;=============================================================================================
;ADC
;=============================================================================================
INIT_ADC:
    LDI R20, 0xE0     ; Load konstanta 0xE0 ke dalam R20
    STS ADMUX, R20    ; Mengatur ADMUX untuk menggunakan internal 2.56V, right-justified data, dan ADC2
    LDI R20,0x87      ; Load konstanta 0x87 ke dalam R20
    STS ADCSRA, R20   ; Mengatur ADCSRA untuk ADC Enable
    LDI R20, 0xC7     ; Load konstanta 0xC7 ke dalam R20
    STS ADCSRA, R20   ; Mengatur ADCSRA untuk ADC Start Conversion
RET
;---------------------------------------------------------------------------------------------
READ_ADC:
    LDS R21, ADCSRA   ; Load nilai dari ADCSRA ke dalam R21 dan cek ADC Interrupt flag
    SBRS R21,4        ; Skip jump bila konversi sudah selesai atau flag sudah set
    RJMP READ_ADC    ; Loop sampai ADIF flag set
    LDI R17, 0xD7     ; Load konstanta 0xD7 ke dalam R17
    STS ADCSRA,R17    ; Menonaktifkan ADC
    LDS R18, ADCL     ; Load nilai dari ADCL dan ADCH ke dalam R18 dan R19
    LDS R19, ADCH     ; Load nilai dari ADCL dan ADCH ke dalam R18 dan R19

    ; Memeriksa kondisi nilai ADC dan melakukan aksi sesuai kondisi
    MOV R25, R19
    SUBI R25, 128
    BRSH HIGH_SPEED
    MOV R25, R19
    SUBI R25, 64
    BRSH MEDIUM_SPEED
    MOV R25, R19
    SUBI R25, 32
    BRSH LOW_SPEED
    RJMP READ_ADC
;---------------------------------------------------------------------------------------------
HIGH_SPEED:
    ; Enable Relay 1 and 2
    CBI PORTD, 1
    CBI PORTD, 2

    ; PWM Value
    LDI R16, 200
    RCALL PWM
    
    ;LED
    SBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE

    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
MEDIUM_SPEED:
    ; Enable Relay 1 and 2
    CBI PORTD, 1
    CBI PORTD, 2

    ; PWM Value
    LDI R16, 20
    RCALL PWM

    ;LED
    CBI PORTC, 5  ; RED
    SBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE

    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
LOW_SPEED:
    ; Enable Relay 1 and 2
    SBI PORTD, 1
    SBI PORTD, 2

    ; PWM Value
    LDI R16, 0
    RCALL PWM

    ;LED
    CBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    SBI PORTC, 3  ; BLUE

    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
; Kecepatan diatur oleh potensiometer ke paling rendah maka berhenti
STOP_SPEED:
    ; Enable Relay 1 and 2
    SBI PORTD, 1
    SBI PORTD, 2

    ; PWM Value
    LDI R16, 0
    RCALL PWM

    RCALL STOP_LED  ; SEMENTARA
    
    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
; Bila terlalu dekat maka rem mendadak
STOP_EMERGENCY:
    ; Enable Relay 1 and 2
    SBI PORTD, 1
    SBI PORTD, 2

    ; Enable Buzzer
    SBI PORTC, 2

    ; PWM Value
    LDI R16, 0
    RCALL PWM

    RCALL EMERGENCY_BRAKE
    
    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
; Bila jarak terlalu dekat
LOW_SPEED_WARNING_DISTANCE:
    ; Enable Relay 1 and 2
    CBI PORTD, 1
    CBI PORTD, 2

    ; Enable Buzzer
    SBI PORTC, 2

    ; PWM Value
    LDI R16, 20
    RCALL PWM

    RCALL WARNING   
  
    RJMP READ_ADC  ; Kembali ke loop pembacaan ADC
;====================================================
;=============================================================================================
;PWM
;=============================================================================================
PWM:
  OUT OCR0A, R16

  ; Enable Fast PWM mode using OCR0A
  LDI R16, (1 << COM0A1) | (1 << WGM01) | (1 << WGM00)
  OUT TCCR0A, R16

  ; Set prescaler to 1 (no prescaling)
  LDI R16, (1 << CS00)
  OUT TCCR0B, R16
  RET

;=============================================================================================
;SPI
;=============================================================================================

SPI_MAX7219_INIT:
  .equ  SCK, 5
  .equ  MOSI, 3
  .equ  SS, 2
  LDI   R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
  OUT   DDRB, R17       ;set MOSI, SCK, SS as o/p
  ;--------------------------------------------------------
  LDI   R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
  OUT   SPCR, R17       ;enable SPI as master, fsck=fosc/16
  ;--------------------------------------------------------
  LDI   R17, 0x0A       ;set segment intensity (0 to 15)
  LDI   R18, 8          ;intensity level = 8
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x09       ;set decoding mode command
  LDI   R18, 0b00110000 ;decoding byte
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x0B       ;set scan limit command
  LDI   R18, 0x07       ;8 digits connected to MAX7219
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x0C       ;set turn ON/OFF command
  LDI   R18, 0x01       ;turn ON MAX7219
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET
;---------------------------------------------------------------------------------------------
MAX7219_disp_text:
  ; Sending the bytes to MAX 7219 Display
  LDI   R17, 0x03       ;select digit 2
  LDI   R18, 0x0D       ;data = c
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x02       ;select digit 1
  LDI   R18, 0b00010101 ;data = (paruh pertama karakter 'm')
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x01       ;select digit 0
  LDI   R18, 0b00010101 ;data = (paruh kedua karakter 'm')
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET
;---------------------------------------------------------------------------------------------
send_bytes:
    CBI   PORTB, SS       ;enable slave device MAX7219
    OUT   SPDR, R17       ;transmit command
    ;--------------------------------------------------------
ll2:IN    R19, SPSR
    SBRS  R19, SPIF       ;wait for byte transmission
    RJMP  ll2             ;to complete
    ;--------------------------------------------------------
    OUT   SPDR, R18       ;transmit data
    ;--------------------------------------------------------
ll3:IN    R19, SPSR
    SBRS  R19, SPIF       ;wait for byte transmission
    RJMP  ll3             ;to complete
    ;--------------------------------------------------------
    SBI   PORTB, SS       ;disable slave device MAX7219
    RET
;---------------------------------------------------------------------------------------------
byte2decimal:
;------------
    CLR   R26             ;set counter1, initial value 0
    CLR   R27             ;set counter2, initial value 0
    ;--------------------------------------------------------
l70:CPI   R28, 100        ;compare R28 with 100
Ret:BRMI  l80             ;jump when R28 < 100
    INC   R26             ;increment counter1 by 1
    SUBI  R28, 100        ;R28 = R28 - 100
    RJMP  l70
    ;--------------------------------------------------------
l80:CPI   R28, 10         ;compare R28 with 10
    BRMI  dsp             ;jump when R28 < 10
    INC   R27             ;increment counter2 by 1
    SUBI  R28, 10         ;R28 = R28 - 10
    RJMP  l80
    ;--------------------------------------------------------  
dsp:MOV   R18, R27
    LDI   R17, 0x06       ;select digit 5 for MSD
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    MOV   R18, R28
    LDI   R17, 0x05       ;select digit 4 for LSD
    RCALL send_bytes      ;send command & data to MAX7219    
    ;--------------------------------------------------------
    RET

;=============================================================================================
;Delay
;=============================================================================================

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
;---------------------------------------------------------------------------------------------
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

;---------------------------------------------------------------------------------------------
delay_2sec:
    ldi r17, hi8(4000)  ; Load the high byte of the delay count
    ldi r18, lo8(4000)  ; Load the low byte of the delay count
delay_loop:
    subi r18, 1        ; Decrement the low byte of the delay count
    sbci r17, 0        ; Decrement the high byte if the low byte becomes zero
    brne delay_loop    ; Repeat until both bytes reach zero

    ret                ; Return from the subroutine

;=============================================================================================
;HC-SR 04
;=============================================================================================
 HC_SR04_INIT:
;--------------
    SBI   DDRB, 1         ;pin PB1 as o/p (Trigger)
    CBI   DDRB, 0         ;pin PB0 as i/p (Echo)
	RET
;---------------------------------------------------------------------------------------------
echo_PW:
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

;---------------------------------------------------------------------------------------------
COMPARE:
    CPI R28,14
    BRGE skip
    SBI PORTD,7
    RCALL STOP_EMERGENCY
    RCALL delay_2sec
skip:
    RET 

;=============================================================================================
; LED CASE
;=============================================================================================
EMERGENCY_BRAKE:
    ;LED RED
    SBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE
    RET
NORMAL:
    ;LED GREEN
    CBI PORTC, 5  ; RED
    SBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE
    RET
WARNING:
    ;LED YELLOW
    SBI PORTC, 5  ; RED
    SBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE
    RET    
STOP_LED:
    ;LED YELLOW
    CBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    SBI PORTC, 3  ; BLUE
    RET    



