#define __SFR_OFFSET 0  
#include "avr/io.h"  

.global main   

main:    
LDI R21, 0xFF   
OUT DDRD, R21   ; Menjadikan port D sebagai output
OUT DDRB, R21   ; Menjadikan port B sebagai output
CBI DDRC, 0     ; Menjadikan port A0 sebagai input

LDI R20, 0xE0   ; Melakukan load ke dalam R20
STS ADMUX, R20   ;mengatur admux untuk menggunakan  internal 2.56V, right-justified data, dan ADC2.
LDI R20,0x87       ; Melakukan load ke dalam R20
STS ADCSRA, R20   ; Mengatur ADCSRA untuk ADC Enable

LDI R20, 0xC7      ; Melakukan load ke dalam R20
STS ADCSRA, R20   ; Mengatur ADCSRA untuk ADC Start Conversion

read_ADC:    
LDS R21, ADCSRA    ;Mengecek ADC Interrupt flag
SBRS R21,4       ;skip jump bila konversi sudah selesai atau flag sudah set
RJMP read_ADC   ; loop sampai ADIF flag set

LDI R17,0xD7   ; Melakukan load ke R17
STS ADCSRA,R17   

LDS R18,ADCL   
LDS R19,ADCH   
OUT PORTD,R18   
OUT PORTB,R19   

MOV R25, R19   
SUBI R25, 128   
BRSH third_condition   
MOV R25,R19   
SUBI R25, 64   
BRSH second_condition   
MOV R25,R19   
SUBI R25, 32   
BRSH first_condition
RJMP read_ADC   

third_condition: 
SBI PORTD, 1   
SBI PORTD, 0   
RJMP read_ADC   

second_condition:
SBI PORTD, 1  
CBI PORTD, 0  
RJMP read_ADC  

first_condition:
CBI PORTD, 1  
CBI PORTD, 0  
RJMP read_ADC  