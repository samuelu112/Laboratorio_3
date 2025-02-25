; UNIVERSIDAD DEL VALLE DE GUATEMALA
; IE2023: Programaci�n de microcontroladores
; Prelab3.asm
;
; Autor : Eduardo Samuel Urbina P�rez
; Proyecto : Prelaboratorio 3
; Hardware : ATmega 328
; Creado: 12/02/2025
; Descripci�n: el prelaboratorio 3 consiste en hacer un contador de 4 bits con dos pulsadores usando interrupciones

.include "M328PDEF.inc"
.cseg
.org 0x0000
    JMP    START             ; Salto a la rutina de inicio

; Vector para interrupciones por cambio en PORTC (PCINT1)
.org 0x0008
    JMP    ISR_PCINT1

START:
    ; Configuraci�n de la pila
    LDI    R16, LOW(RAMEND)
    OUT    SPL, R16
    LDI    R16, HIGH(RAMEND)
    OUT    SPH, R16

    ; Deshabilitar interrupciones mientras se configura
    CLI

    ; Configurar el prescaler principal para obtener F_CPU = 1MHz
    LDI    R16, (1<<CLKPCE)
    STS    CLKPR, R16
    LDI    R16, 0b00000100
    STS    CLKPR, R16

    ; Configurar PORTB como salida para los 4 leds
    LDI    R16, 0x0F         ; 0000 1111: solo se usan los 4 LEDs
    OUT    DDRB, R16

    ; Configurar PORTC como entrada con pull-ups para los pushbuttons
    LDI    R16, 0x00
    OUT    DDRC, R16
    LDI    R16, 0xFF
    OUT    PORTC, R16

    ; Configurar interrupciones por cambio para PORTC
    ; Habilitar interrupci�n por cambio para el grupo de PORTC (PCIE1 en PCICR)
    LDI    R16, 0b00000010//(1<<PCIE1)
    STS    PCICR, R16
    ; Habilitar interrupciones para PC0 y PC1 (corresponden a PCINT8 y PCINT9)
    LDI    R16, 0b00000011//(1<<PCINT8) | (1<<PCINT9)
    STS    PCMSK1, R16

	;Direccionamiento indirecto de 0x0100 a 0x010F
	LDI		ZL, 0x00
	LDI		ZH, 0x01
	LDI		R19, 0b00111111 ;0
	ST		Z+, R19
	LDI		R19, 0b00000110 ;1
	ST		Z+, R19
	LDI		R19, 0B01011011 ;2
	ST		Z+, R19
	LDI		R19, 0B01001111 ;3
	ST		Z+, R19
	LDI		R19, 0B01100110 ;4
	ST		Z+, R19
	LDI		R19, 0B01101101 ;5
	ST		Z+, R19
	LDI		R19, 0B01111101 ;6
	ST		Z+, R19
	LDI		R19, 0B00000111 ;7
	ST		Z+, R19
	LDI		R19, 0B01111111 ;8
	ST		Z+, R19
	LDI		R19, 0B01100111 ;9


    ; Inicializar el contador binario de 4 bits
    LDI    R24, 0x00

    ; Habilitar interrupciones globales
    SEI

MAIN_LOOP:
    ; En el loop principal solo se actualiza la salida de los Leds
    MOV    R16, R24
    OUT    PORTB, R16
    RJMP   MAIN_LOOP

;---------------------------------------------------------
; Interrupci�n Pin Change Interrupt para PORTC PCINT1_vect
ISR_PCINT1:
    IN     R16, PINC       ; Leer el estado actual de PORTC
    ; Si PC0 est� en 0, incrementa el contador
    SBRS   R16, 0          ; Si bit0 est� seteado, salta la siguiente instrucci�n
    CALL   INCREMENT_COUNTER
    ; Si PC1 est� en 0 (bot�n presionado), decrementa el contador
    SBRS   R16, 1
    CALL   DECREMENT_COUNTER
    RETI

; Incrementa el contador R24 y lo limita a 4 bits
INCREMENT_COUNTER:
    INC    R24
    ANDI   R24, 0x0F
    RET
; Decrementa el contador R24 y lo limita a 4 bits
DECREMENT_COUNTER:
    DEC    R24
    ANDI   R24, 0x0F
    RET
