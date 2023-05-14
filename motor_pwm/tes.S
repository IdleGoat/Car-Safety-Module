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

rjmp loop ; 

PWM:
  OUT OCR0A, R16

  ; Enable Fast PWM mode using OCR0A
  LDI R16, (1 << COM0A1) | (1 << WGM01) | (1 << WGM00)
  OUT TCCR0A, R16

  ; Set prescaler to 1 (no prescaling)
  LDI R16, (1 << CS00)
  OUT TCCR0B, R16
  RET

STOP:
    LDI R16, 0
    RCALL PWM
    RET

SLOW:
    LDI R16, 50
    RCALL PWM
    RET  