.include "m8535def.inc"

.def adl = r17 ;byte bajo del ADC
.def adh = r16 ;byte alto del ADC
.def col = r18 ;columna matriz
.def aux = r19
.def actual = r20 ;num actual en matriz
;--------------------------------------------------
.macro num ;carga el dibujo del numero
						;cada byte es una fila 
    push zh
    push zl

    ldi ZH, high(@0<<1) ;puntero z
    ldi ZL, low(@0<<1)

    lpm r0, Z+
    lpm r1, Z+
    lpm r2, Z+
    lpm r3, Z+
    lpm r4, Z+
    lpm r5, Z+
    lpm r6, Z+
    lpm r7, Z

    pop zl
    pop zh
.endm

;--------------------------------------------------
    rjmp Start

.org $008
    rjmp nada
    rjmp barre ;encargada de multiplexar la matriz

.org $0E
    rjmp CONV

;--------------------------------------------------
Start:
    ldi r16, LOW(RAMEND)
    out SPL, r16
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    
    ser r16
    out DDRB, r16 ;filas matriz
    out DDRC, r16 ; columnas matriz
    out DDRD, r16 ; barra de leds

    ldi r16, $ED ;config del ADC
    out ADCSRA, r16
    ldi r16, $20 ;ADC0, alineaci n izquierda
    out ADMUX, r16

    ldi aux, 2 ;TIMERS
    out TCCR0, aux
    ldi aux, 2
    out TCCR1B, aux
    ldi aux, 5
    out TIMSK, aux

    sei
    
    ldi col, 1 ;Variables iniciales
    clr ZH
    ldi ZL, 0
    ldi actual, $FF

;--------------------------------------------------
Loop:
    out PORTC, adh ;Muestra ADC en la barra
		tst adh ;Si no hay bot n
		breq sinBoton ;se apaga

    ;---------------------------------------------
    ;rangos de los botones
    cpi adh, 28 ;bot n 0
    brlo num0
    cpi adh, 31 ;bot n 1
    brlo num1
    cpi adh, 35 ;bot n 2
    brlo num2 
    cpi adh, 40 ;bot n 3
    brlo num3 
    cpi adh, 47 ;bot n 4
    brlo num4
    cpi adh, 58 ;bot n 5
    brlo num5
    cpi adh, 75 ;bot n 6
    brlo num6
    cpi adh, 107 ;bot n 7
    brlo num7
    cpi adh, 192 ;bot n 8
    brlo num8
    rjmp num9 ;bot n 9

sinBoton:
    rjmp apagar

;se agregaron porque los saltos no alcanzaban
num0:
    rjmp mostrar0
num1:
    rjmp mostrar1
num2:
    rjmp mostrar2
num3:
    rjmp mostrar3
num4:
    rjmp mostrar4
num5:
    rjmp mostrar5
num6:
    rjmp mostrar6
num7:
    rjmp mostrar7
num8:
    rjmp mostrar8
num9:
    rjmp mostrar9
    
mostrar0:
    cpi actual,0
    brne carga0
    rjmp Loop
carga0:
    cli
    num cero
    sei
    ldi actual,0
    rjmp Loop

mostrar1:
    cpi actual,1
    brne carga1
    rjmp Loop
carga1:
    cli
    num uno
    sei
    ldi actual,1
    rjmp Loop

mostrar2:
    cpi actual,2
    brne carga2
    rjmp Loop
carga2:
    cli
    num dos
    sei
    ldi actual,2
    rjmp Loop

mostrar3:
    cpi actual,3
    brne carga3
    rjmp Loop
carga3:
    cli
    num tres
    sei
    ldi actual,3
    rjmp Loop

mostrar4:
    cpi actual,4
    brne carga4
    rjmp Loop
carga4:
    cli
    num cuatro
    sei
    ldi actual,4
    rjmp Loop

mostrar5:
    cpi actual,5
    brne carga5
    rjmp Loop
carga5:
    cli
    num cinco
    sei
    ldi actual,5
    rjmp Loop

mostrar6:
    cpi actual,6
    brne carga6
    rjmp Loop
carga6:
    cli
    num seis
    sei
    ldi actual,6
    rjmp Loop

mostrar7:
    cpi actual,7
    brne carga7
    rjmp Loop
carga7:
    cli
    num siete
    sei
    ldi actual,7
    rjmp Loop

mostrar8:
    cpi actual,8
    brne carga8
    rjmp Loop
carga8:
    cli
    num ocho
    sei
    ldi actual,8
    rjmp Loop

mostrar9:
    cpi actual,9
    brne carga9
    rjmp Loop
carga9:
    cli
    num nueve
    sei
    ldi actual,9
    rjmp Loop

apagar:
    cpi actual,$FF
    breq sin_cambio
    cli
    clr r0
    clr r1
    clr r2
    clr r3
    clr r4
    clr r5
    clr r6
    clr r7
    sei
    ldi actual,$FF


sin_cambio:
    clr adh
    out PORTC,adh
    rjmp Loop

nada:
    reti

CONV:
    in adl,ADCL
    in adh,ADCH
    reti
    
barre:
    out PORTB,ZH ;apaga la columna anterior
    ld aux,Z+ ;lee el numero 
    lsl col ;enciende la sig col
    brcs nbarre ;repite rapido 

sss:
    com col
    out PORTD,col
    com col
    out PORTB,aux
    reti

nbarre:
    ldi col,1
    ldi ZL,0
    ld aux,Z+
    rjmp sss

;patrones de los numeros en la matriz
cero:
    .db $00,$7C,$82,$82,$82,$7C,$00,$00
uno:
    .db $00,$22,$42,$FE,$02,$02,$00,$00
dos:
    .db $00,$42,$86,$8A,$92,$62,$00,$00
tres:
    .db $00,$44,$82,$92,$92,$6C,$00,$00
cuatro:
    .db $00,$08,$18,$28,$48,$FE,$00,$00
cinco:
    .db $00,$F4,$92,$92,$92,$8C,$00,$00
seis:
    .db $00,$7C,$92,$92,$92,$4C,$00,$00
siete:
    .db $00,$80,$8E,$90,$A0,$C0,$00,$00
ocho:
    .db $00,$6C,$92,$92,$92,$6C,$00,$00
nueve:
    .db $00,$64,$92,$92,$92,$7C,$00,$00
