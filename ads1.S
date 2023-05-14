// Mengatur offset SFR menjadi 0 dan memanggil header file io.h
#define __SFR_OFFSET 0
#include "avr/io.h"

// Deklarasi fungsi main sebagai global
.global main

// Implementasi fungsi main
main:
    // Load konstanta 0xFF ke dalam R21
    LDI R21, 0xFF

    // Menjadikan port D dan B sebagai output
    OUT DDRD, R21
    OUT DDRB, R21

    // Menjadikan pin A0 sebagai input
    CBI DDRC, 0

    // Load konstanta 0xE0 ke dalam R20
    LDI R20, 0xE0

    // Mengatur ADMUX untuk menggunakan internal 2.56V, right-justified data, dan ADC2
    STS ADMUX, R20

    // Load konstanta 0x87 ke dalam R20
    LDI R20,0x87

    // Mengatur ADCSRA untuk ADC Enable
    STS ADCSRA, R20

    // Load konstanta 0xC7 ke dalam R20
    LDI R20, 0xC7

    // Mengatur ADCSRA untuk ADC Start Conversion
    STS ADCSRA, R20

read_ADC:
    // Load nilai dari ADCSRA ke dalam R21 dan cek ADC Interrupt flag
    LDS R21, ADCSRA

    // Skip jump bila konversi sudah selesai atau flag sudah set
    SBRS R21,4

    // Loop sampai ADIF flag set
    RJMP read_ADC

    // Load konstanta 0xD7 ke dalam R17
    LDI R17, 0xD7

    // Menonaktifkan ADC
    STS ADCSRA,R17

    // Load nilai dari ADCL dan ADCH ke dalam R18 dan R19
    LDS R18, ADCL
    LDS R19, ADCH

    // Mengirim nilai ADCL dan ADCH ke PORTD dan PORTB
    OUT PORTD, R18
    OUT PORTB, R19

    // Memeriksa kondisi nilai ADC dan melakukan aksi sesuai kondisi
    MOV R25, R19
    SUBI R25, 128
    BRSH third_condition
    MOV R25, R19
    SUBI R25, 64
    BRSH second_condition
    MOV R25, R19
    SUBI R25, 32
    BRSH first_condition
    RJMP read_ADC

third_condition:
    // Mengaktifkan pin PD1 dan PD0
    SBI PORTD, 1
    SBI PORTD, 0

    // Kembali ke loop pembacaan ADC
    RJMP read_ADC

second_condition:
    // Mengaktifkan pin PD1 dan mematikan PD0
    SBI PORTD, 1
    CBI PORTD, 0

    // Kembali ke loop pembacaan ADC
    RJMP read_ADC

first_condition:
    // Mematikan pin PD1 dan PD0
    CBI PORTD, 1
    CBI PORTD, 0

    // Kembali ke loop pembacaan ADC
    RJMP read_ADC
