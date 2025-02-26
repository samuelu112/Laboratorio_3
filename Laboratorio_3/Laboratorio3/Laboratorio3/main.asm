; UNIVERSIDAD DEL VALLE DE GUATEMALA
; IE2023: Programación de microcontroladores
; Prelab3.asm
;
; Autor : Eduardo Samuel Urbina Pérez
; Proyecto : Prelaboratorio 3
; Hardware : ATmega 328
; Creado: 12/02/2025
; Descripción: el prelaboratorio 3 consiste en hacer un contador de 4 bits con dos pulsadores usando interrupciones

.include "M328PDEF.inc"
.cseg
.org 0x0000
    JMP		START             ; Salto a la rutina de inicio

; Vector para interrupciones por cambio en PORTC (PCINT1)
.org 0x0008
    JMP    ISR_PCINT1

.org 0x0020
	RJMP		TMR0 ;Salta a rutina de timer0 overflow

START:
    ; Configuración de la pila
    LDI    R16, LOW(RAMEND)
    OUT    SPL, R16
    LDI    R16, HIGH(RAMEND)
    OUT    SPH, R16

    ; Deshabilitar interrupciones mientras se configura
    CLI

	;Configuracion de interrupciones de timer
	LDI		R16, (1<<TOIE0)
	STS		TIMSK0, R16
	LDI		R16, (1<<TOV0)
	STS		TIFR0, R16

	; Inicializar Timer0
    CALL  INIT_TMR0

    ; Configurar el prescaler principal para obtener F_CPU = 1MHz
    LDI    R16, (1<<CLKPCE)
    STS    CLKPR, R16
    LDI    R16, 0b00000100
    STS    CLKPR, R16

    ; Configurar PORTB como salida para los 4 leds
    LDI		R16, 0x0F         ; 0000 1111: solo se usan los 4 LEDs
    OUT		DDRB, R16
	LDI		R16, 0xFF
	OUT		DDRD, R16 //Configurar puerto D como salida

    ; Configurar PORTC como entrada con pull-ups para los pushbuttons
    LDI    R16, 0b00011000
    OUT    DDRC, R16
    LDI    R16, 0b11110011
    OUT    PORTC, R16


    ; Configurar interrupciones por cambio para PORTC
    ; Habilitar interrupción por cambio para el grupo de PORTC (PCIE1 en PCICR)
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
	ST		Z+, R19

	;Valores iniciales, indicador en 0x00FF
	;Direccion
	LDI		ZL, 0x00
	LDI		ZH, 0x01
	LDI		XL, 0x00
	LDI		XL, 0x01
    ; Inicializar el contador binario de 4 bits
    LDI    R24, 0x00

    ; Habilitar interrupciones globales
    SEI

MAIN_LOOP:
    ; En el loop principal solo se actualiza la salida de los Leds
	RJMP	MAIN_LOOP

;Subrutina para inicializar Timer0
INIT_TMR0:
    ;Configurar Timer0: prescaler de 64 para generar un overflow en 10ms
    LDI		R17, (1<<CS01) | (1<<CS00)
    OUT		TCCR0B, R17
    LDI		R17, 100
    OUT		TCNT0, R17
    RET

;---------------------------------------------------------
; Interrupción Pin Change Interrupt para PORTC PCINT1_vect
ISR_PCINT1:
    IN     R16, PINC       ; Leer el estado actual de PORTC
    ; Si PC0 está en 0 (botón presionado), incrementa el contador
    SBRS   R16, 0          ; Si bit0 está seteado (alto), salta la siguiente instrucción
    INC    R24
    ; Si PC1 está en 0 (botón presionado), decrementa el contador
    SBRS   R16, 1
    DEC    R24
	ANDI   R24, 0x0F

    OUT		PORTB, R24
    RETI

TMR0:
	INC		R20
	CPI		R20, 100 //R20 = 100 DESPUES DE 100 OVERFLOWS
	BRNE	REGRESO
	CLR		R20
	LD		R19, Z+
	MOV		R21, ZL
	CPI		R21, 0x0A
	BREQ	REINICIO
	OUT		PORTD, R19
	LDI		R18, 100
	OUT		TCNT0, R18
	RETI
REGRESO:
	RETI
REINICIO:
	LDI		ZL, 0x00
	OUT		PORTD, R19
    RETI
