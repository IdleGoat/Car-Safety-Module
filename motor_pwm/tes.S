#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main


main:
  SBI DDRD, 5 
  SBI DDRD, 6
  SBI PORTD, 1
  SBI PORTD, 3
 
loop:
  LDI R16, (0<<WGM01)|(0<<WGM00)|(0<<COM0A1)|(0<<COM0B1)|(0<<COM0B0)
  OUT TCCR0A, R16
  LDI R16, (0<<CS01)|(0<<CS02)
  OUT TCCR0B, R16

  CBI PORTD, 2
  CBI PORTD, 4
    
  ; Set Fast PWM mode with non-inverting
  ; Output on OC0A and OC0B
  LDI R16, (1<<WGM01)|(1<<WGM00)|(1<<COM0A1)|(1<<COM0B1)|(1<<COM0B0)
  OUT TCCR0A, R16
  LDI R16, (1<<CS00)
  OUT TCCR0B, R16

  ; Set duty cycle of PWM on PD5 to 50%
  LDI R16, 63
  OUT OCR0A, R16

  ; Set duty cycle of PWM on PD6 to 75%
  LDI R16, 127
  OUT OCR0B, R16

rjmp loop ; 
