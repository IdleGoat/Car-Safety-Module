#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
  ; Initial staging for nanda's local repo
  RCALL SPI_MAX7219_INIT
  RCALL MAX7219_disp_text

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

MAX7219_disp_text:

send_bytes:
  ; Sending the bytes to MAX 7219 Display
  LDI   R17, 0x03       ;select digit 2
  LDI   R18, 0x0D       ;data = c
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x02       ;select digit 1
  LDI   R18, 0x25       ;data = (paruh pertama karakter 'm')
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  LDI   R17, 0x01       ;select digit 0
  LDI   R18, 0x25       ;data = (paruh kedua karakter 'm')
  RCALL send_bytes      ;send command & data to MAX7219
  ;--------------------------------------------------------
  RET