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
loop:
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
    LDI R16, 100
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
