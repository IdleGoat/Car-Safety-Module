#define __SFR_OFFSET 0x00
#include "avr/io.h"
.global main

main:
LDI R21, 0xFF
OUT DDRD, R21 ; Menjadikan port D sebagai output
LDI R21, 0b00000011 ; Melakukan load ke dalam R21
OUT DDRC, R21 ; menjadikan A0 A1 sebagai output sisanya sebagai input

LDI R21, 0b11000010 ; Melakukan load ke dalam R21
STS ADMUX, R21 ;mengatur admux untuk menggunakan  internal 2.56V, 
;right-justified data, dan ADC2.
LDI R21, 0x87 ; Melakukan load ke dalam R21
STS ADCSRA, R21 ; Mengatur ADCSRA untuk ADC Enable

read_ADC:
LDI R21, 0xC7 ; Melakukan load ke dalam R21
STS ADCSRA, R21 ; Mengatur ADCSRA untuk ADC Start Conversion

wait_ADC:
LDS R22, ADCSRA ;Mengecek ADC Interrupt flag
SBRS R22, 4 ;skip jump bila konversi sudah selesai atau flag sudah set
RJMP wait_ADC ; loop sampai ADIF flag set

LDI R18, 0xD7 ; Melakukan load ke R18
STS ADCSRA, R18 ;Mengatur kembali nilai ADIF agar dapat dihapus

LDS R19, ADCL ; Mendapatkan hasil konversi ADC Low-byte
LDS R20, ADCH ; Mendapatkan hasil konversi ADC High-byte
RJMP check_LDR ; Jump ke label check_LDR