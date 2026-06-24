.include "m8535def.inc"

.def temp = r16
.org $0000
    rjmp main          ; Vector de Reset (Inicio del programa)

.org $0010             ; $10 es el vector ANA_COMP en el ATmega8535
    rjmp ISR_ANA_COMP  ; Salto a la rutina del Comparador Analógico


main:
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ser temp           
    out DDRC, temp

    ; Habilitar interrupción del comparador
    ldi temp, (1<<ACIE)
    out ACSR, temp

    ldi temp, $40
    out PORTC, temp

    sei

ciclo_infinito:
    rjmp ciclo_infinito


ISR_ANA_COMP:
    in temp, SREG
    push temp

    in temp, PINC      ; Leemos el estado actual del Puerto C

    cpi temp, $39      
    breq poner_guion   

    cpi temp, $40     
    breq poner_c       

    rjmp salir_ISR     ; Si no es ninguno, ignorar

poner_guion:
    ldi temp, $40      
    out PORTC, temp
    rjmp salir_ISR

poner_c:
    ldi temp, $39      
    out PORTC, temp

salir_ISR:
    pop temp
    out SREG, temp
    reti               
