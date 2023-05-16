;------------------------
; Assembly Code
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global SPI_MAX7219_init
.global MAX7219_disp_text
.global HC_SR04_sensor
.global main
;===============================================================
main:
  LDI R21, 0xFF   
  OUT DDRD, R21       ; Menjadikan pin D sebagai output

  ; Analog input
  CBI DDRC, 0         ; Menjadikan pin A0 sebagai input analog
  
  ; Output untuk RGB LED
  SBI DDRC, 5
  SBI DDRC, 4
  SBI DDRC, 3

  ; Output untuk Buzzer
  SBI DDRC, 2

  RCALL SPI_MAX7219_init
  RCALL MAX7219_disp_text
  RCALL INIT_ADC
loop:
  RCALL HC_SR04_sensor
  RJMP loop

;===============================================================
HC_SR04_sensor:
;--------------
    SBI   DDRB, 1         ;pin PB1 as o/p (Trigger)
    CBI   DDRB, 0         ;pin PB0 as i/p (Echo)
    ;-----------------------------------------------------------
agn:SBI   PORTB, 1
    CBI   PORTD, 1
    CBI   PORTD, 0
    RCALL delay_timer0
    CBI   PORTB, 1        ;send 10us high pulse to sensor
    ;-----------------------------------------------------------
    RCALL echo_PW         ;compute Echo pulse width count
    ;-----------------------------------------------------------
    RCALL compare
    ;-----------------------------------------------------------    
    RCALL byte2decimal    ;covert & display on MAX7219
    ;-----------------------------------------------------------
    RCALL delay_ms
    RJMP  agn
;===============================================================
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
    SUB   R28, R16        ;count diff R22 = R22 - R16
    ADD   R28, 17
    OUT   TIFR1, R21      ;clear flag for next sensor reading
    RET

;=============================================================================================
; COMPARE
;=============================================================================================
compare:
    CPI R28, 30
    BRCS emergency_brake
    CPI R28, 50
    BRCS warning
   
    ;LED GREEN
    CBI PORTC, 5  ; RED
    SBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE

    ; Disable buzzer
    CBI PORTC, 2

    RCALL READ_ADC
    RJMP skip
;=============================================================================================
warning:
    ;LED YELLOW
    CBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    SBI PORTC, 3  ; BLUE

     ; Disable buzzer
    CBI PORTC, 2

    RCALL READ_ADC
    RJMP skip
    
emergency_brake:
    ; Disable Relay 1 and 2
    SBI PORTD, 1
    SBI PORTD, 2

    ; Enable buzzer
    SBI PORTC, 2

    ;LED RED
    SBI PORTC, 5  ; RED
    CBI PORTC, 4  ; GREEN
    CBI PORTC, 3  ; BLUE

    RJMP skip
skip:
    RET
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
    SUBI R25, 150
    BRSH HIGH_SPEED
    MOV R25, R19
    SUBI R25, 90
    BRSH LOW_SPEED
    MOV R25, R19
    SUBI R25, 32
    BRSH STOP_SPEED
    skipadc:
    RET
;---------------------------------------------------------------------------------------------
; Kecepatan diatur oleh potensiometer
HIGH_SPEED:
    ; Enable Relay 1 and 2
    CBI PORTD, 1
    CBI PORTD, 2

    ;SPEED INDICATOR
    SBI PORTD, 3
    SBI PORTD, 4
    SBI PORTD, 5

    ; PWM Value
    LDI R16, 200
    RCALL PWM


    RJMP skipadc  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
; Kecepatan diatur oleh potensiometer
LOW_SPEED:
    ; Enable Relay 1 and 2
    CBI PORTD, 1
    CBI PORTD, 2

    ;SPEED INDICATOR
    CBI PORTD, 3
    SBI PORTD, 4
    SBI PORTD, 5

    ; PWM Value
    LDI R16, 20
    RCALL PWM

  
    RJMP skipadc  ; Kembali ke loop pembacaan ADC
;---------------------------------------------------------------------------------------------
; Kecepatan diatur oleh potensiometer ke paling rendah maka berhenti
STOP_SPEED:
    ; Enable Relay 1 and 2
    SBI PORTD, 1
    SBI PORTD, 2

    ;SPEED INDICATOR
    CBI PORTD, 3
    CBI PORTD, 4
    SBI PORTD, 5

    RCALL PWM
    RJMP skipadc ; Kembali ke loop pembacaan ADC
;=============================================================================================
; PWM
;=============================================================================================
PWM:
  OUT OCR0A, R16

  ; Enable Fast PWM mode using OCR0A
  LDI R16, (1 << COM0A1) | (1 << WGM01) | (1 << WGM00)
  OUT TCCR0A, R16

  ; Set prescaler to 1 (no prescaling)
  LDI R16, (1 << CS00)
  OUT TCCR0B, R16
  OUT OCR0A, 0
  LDI R16, (0 << COM0A1) | (0 << WGM01) | (0 << WGM00)
  OUT TCCR0A, R16
  LDI R16, (0 << CS00)
  OUT TCCR0B, R16  
  RET


