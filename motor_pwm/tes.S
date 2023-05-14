#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main


main:
  LDI R21, 0xFF   
  OUT DDRD, R21   ; Menjadikan port D sebagai output
  OUT DDRB, R21   ; Menjadikan port B sebagai output
  SBI PORTD,1 
  SBI PORTD,2
loop:
 ; Set the duty cycle to 75%
  ldi R16, 0
  out OCR0A, R16

  ; Enable Fast PWM mode using OCR0A
  ldi R16, (1 << COM0A1) | (1 << WGM01) | (1 << WGM00)
  out TCCR0A, R16

  ; Set prescaler to 1 (no prescaling)
  ldi R16, (1 << CS00)
  out TCCR0B, R16

rjmp loop ; 