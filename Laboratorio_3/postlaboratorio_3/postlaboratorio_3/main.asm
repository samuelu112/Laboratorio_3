; UNIVERSIDAD DEL VALLE DE GUATEMALA
; IE2023: Programaci�n de microcontroladores
; Laboratorio3.asm
;
; Autor : Eduardo Samuel Urbina P�rez
; Proyecto : Postlaboratorio 3
; Hardware : ATmega 328
; Creado: 12/02/2025
; Descripci�n: el postlaboratorio consiste Implemente un contador de �decenas�. Cada vez que el contador con el TMR0 llegue a
; 10 deber� de resetearlo e incrementar el contador de decenas en un segundo display de
; 7 segmentos, de manera que se muestren las decenas de segundos.
; Cuando �ste llegue a 60s deber� de reiniciar ambos contadores.

.include "M328PDEF.inc"

; Programa Principal (c�digo) 

.cseg
.org 0x0000
    RJMP START            ; Vector de reset

; Vector de interrupci�n por cambio en PORTC (para los pulsadores)
.org 0x0008
    RJMP ISR_PCINT1

; Vector de interrupci�n de Timer0 Overflow (ATmega328P: 0x0020)
.org 0x0020
    RJMP TMR0

START:
    ; Configuraci�n de la pila
    LDI   r16, low(RAMEND)
    OUT   SPL, r16
    LDI   r16, high(RAMEND)
    OUT   SPH, r16

    cli                      ; Deshabilitar interrupciones

    ; Configurar reloj: F_CPU = 1 MHz
    LDI   r16, (1<<CLKPCE)
    STS   CLKPR, r16
    LDI   r16, 0b00000100
    STS   CLKPR, r16

    ; Configurar PORTC:
    ; PC0 y PC1 se usan para entradas con pull-up
    ; PC3 y PC4 se usan para controlar los transistores que activan los displays
    LDI   r16, 0b00011000   ; PC3 y PC4 como salidas, PC0 y PC1 como entradas
    OUT   DDRC, r16
    LDI   r16, 0b11100111   ; Activa pull-ups en PC0 y PC1; deja PC3 y PC4 en 0
    OUT   PORTC, r16

    
	; Configurar interrupciones por cambio para PORTC
    ; Habilitar interrupci�n por cambio para el grupo de PORTC (PCIE1 en PCICR)
    LDI    R16, 0b00000010//(1<<PCIE1)
    STS    PCICR, R16
    ; Habilitar interrupciones para PC0 y PC1 (corresponden a PCINT8 y PCINT9)
    LDI    R16, 0b00000011//(1<<PCINT8) | (1<<PCINT9)
    STS    PCMSK1, R16

    ; Cargar la tabla de 7 segmentos en SRAM (direccionamiento indirecto)
    ;Direccionamiento indirecto de 0x0100 a 0x0109
	LDI		ZL, 0x00
	LDI		ZH, 0x01
    LDI		r19, 0b00111111  ; Patr�n para "0"
    st		Z+, r19
    LDI		r19, 0b00000110  ; Patr�n para "1"
    st		Z+, r19
    LDI		r19, 0B01011011  ; Patr�n para "2"
    st		Z+, r19
    LDI		r19, 0B01001111  ; Patr�n para "3"
    st		Z+, r19
    LDI		r19, 0B01100110  ; Patr�n para "4"
    st		Z+, r19
    LDI		r19, 0B01101101  ; Patr�n para "5"
    st		Z+, r19
    LDI		r19, 0B01111101  ; Patr�n para "6"
    st		Z+, r19
    LDI		r19, 0B00000111  ; Patr�n para "7"
    st		Z+, r19
    LDI		r19, 0B01111111  ; Patr�n para "8"
    st		Z+, r19
    LDI		r19, 0B01100111  ; Patr�n para "9"
    st		Z+, r19

    ;Reiniciar puntero Z
    LDI   r16, 0x00
    MOV   r30, r16         ; ZL = 0x00
    LDI   r16, 0x01
    MOV   r31, r16         ; ZH = 0x01

    
    ; Configurar Timer0 para overflow ~10ms
    LDI   r16, (1<<CS01)|(1<<CS00)   ; Prescaler = 64
    OUT   TCCR0B, r16
    LDI   r16, 100
    OUT   TCNT0, r16
    LDI   r16, (1<<TOIE0)            ; Habilitar interrupci�n por overflow
    STS   TIMSK0, r16

    ; Configurar PORTD como salida (para los displays de 7 segmentos)
    LDI   r16, 0xFF
    OUT   DDRD, r16

    OUT   DDRB, r16


    ; Inicializar contadores:
    ; Contador de pulsadores (binario, 4 bits) en r24 (0�F)
    LDI   r24, 0x00
    ; Contador de overflows de Timer0 (para 1 s) en r20
    LDI   r20, 0
    ; Contador de segundos:
    ; r21: unidades (0�9) y r22: decenas (0�6)
    LDI   r21, 0
    LDI   r22, 0
    ; Condici�n de multiplexado en r23
    LDI   r23, 0

    sei                      ; Habilitar interrupciones globales

main_loop:
    RJMP main_loop           ; MAIN LOOP VAC�O

; ISR: Interrupci�n por cambio en PORTC
ISR_PCINT1:
    IN     R25, PINC       ; Leer el estado actual de PORTC
    ; Si PC0 est� en 0, incrementa el contador
    SBRS   R25, 0          ; Si el bit0 est� alto, salta la siguiente instrucci�n
    INC    R24
    ; Si PC1 est� en 0, decrementa el contador
    SBRS   R25, 1
    DEC    R24
	ANDI   R24, 0x0F       ; Limitar el contador a 4 bits
    OUT    PORTB, R24      ; Actualizar el valor mostrado en PORTB
    RETI

; Timer0 Overflow
; Al llegar 100, actualiza el contador de segundos
; y realiza el multiplexado de los dos displays.
TMR0:
    ; Recargar TCNT0 para el siguiente ciclo (~10ms)
    LDI   r16, 100
    OUT   TCNT0, r16

    INC   r20               ; r20 = acumulador de overflows
    CPI   r20, 100
    BRLO  multiplex         ; Si no se ha llegado a 1 s, ir a multiplexado

    ; 1 segundo transcurrido:
    CLR   r20               ; Reiniciar acumulador de overflows

    inc   r21               ; Incrementar unidades
    CPI   r21, 10
    BRLO  update_sec
    CLR   r21               ; Si r21 == 10, reiniciar unidades
    INC   r22               ; y aumentar decenas
	RETI
update_sec:
    CPI   r22, 6            ; Si decenas < 6, continuar
    BRLO  multiplex
    CLR   r22               ; Si decenas == 6 (60 s), reiniciar decenas
	RETI
multiplex:
    ; Alternar entre mostrar decenas (r22) y unidades (r21) usando r23
    COM   r23               ; Toggle de r23
    ANDI  r23, 0x01         ; Limitar a 0 o 1
    CPI   r23, 0
    BREQ  show_decenas      ; Si r23 == 0, mostrar decenas
    ; Mostrar unidades:
    LDI   r16, low(0x0100)   ; Base baja de la tabla
    LDI   r17, high(0x0100)  ; Base alta
    ADD   r16, r21           ; �ndice = r21 (0�9)
    MOV   r30, r16           ; ZL = r16
    MOV   r31, r17           ; ZH = r17
    LD    r18, Z             ; r18 = patr�n de segmentos
    OUT   PORTD, r18         ; Enviar patr�n a PORTD
    ; Activar transistor para unidades: encender PC4, apagar PC3
    LDI   r16, (1<<PC4)
    OUT   PORTC, r16
    RETI
show_decenas:
    ; Mostrar decenas:
    LDI   r16, low(0x0100)
    LDI   r17, high(0x0100)
    ADD   r16, r22           ; �ndice = r22 (0�6)
    MOV   r30, r16
    MOV   r31, r17
    LD    r18, Z             ; r18 = patr�n para decenas
    OUT   PORTD, r18
    ; Activar transistor para decenas: encender PC3, apagar PC4
    LDI   r16, (1<<PC3)
    OUT   PORTC, r16
	RETI



