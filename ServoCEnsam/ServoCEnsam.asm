.include "m8535def.inc"

.def aux = r16
.org 0x0000
    rjmp inicio

inicio:
    ; Configuraci n de Pila
    ldi aux, low(RAMEND)
    out spl, aux
    ldi aux, high(RAMEND)
    out sph, aux

    ldi aux, $0F        ; 0b00001111
    out ddrc, aux
    ldi aux, $FB        ; 0b11111011 
    out ddrd, aux
    ldi aux, $04        ; 0b00000100 
    out portd, aux


ciclo_principal:
    sbis pind, 2        ; boton no presionado
    rjmp btn_presionado ; 
    
btn_no_presionado:    
    ; secuencia 1
    ldi aux, 8          ; step1
    out portc, aux
    rcall retardo

    ldi aux, 4          ; step2
    out portc, aux
    rcall retardo

    ldi aux, 2          ; step3
    out portc, aux
    rcall retardo

    ldi aux, 1          ; step4
    out portc, aux
    rcall retardo

    rjmp ciclo_principal 

btn_presionado:
    ; secuencia 2
    ldi aux, 1          ; step4
    out portc, aux
    rcall retardo

    ldi aux, 2          ; step3
    out portc, aux
    rcall retardo

    ldi aux, 4          ; step2
    out portc, aux
    rcall retardo

    ldi aux, 8          ; step1
    out portc, aux
    rcall retardo

    rjmp ciclo_principal


retardo:
; Assembly code auto-generated
; by utility from Bret Mulvey
; Delay 250 000 cycles
; 250ms at 1 MHz

    ldi  r18, 2
    ldi  r19, 69
    ldi  r20, 170
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    rjmp PC+1      
	ret       
