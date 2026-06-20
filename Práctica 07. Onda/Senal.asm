.include "m8535def.inc"
.def aux    = r16
.def estado = r17

reset:
    rjmp inicio
    .org $008
    rjmp cambia
    .org $009
    rjmp toggle

inicio:
    ldi aux, low(RAMEND)
    out SPL, aux
    ldi aux, high(RAMEND)
    out SPH, aux

    ldi aux, 0x01
    out DDRA, aux

    ; Timer0: prescaler 8 (CS01=1), recarga 194 para ~0.5ms
    ldi aux, 0b00000010
    out TCCR0, aux
    ldi aux, 194
    out TCNT0, aux

    ; Timer1: prescaler 8 (CS11=1), recarga 64286 para 10ms
    ldi aux, 0b00000010
    out TCCR1B, aux
    ldi aux, high(64286)
    out TCNT1H, aux
    ldi aux, low(64286)
    out TCNT1L, aux

    ldi aux, (1<<TOIE0)|(1<<TOIE1)
    out TIMSK, aux

    sei
    clr estado

loop:
    rjmp loop

toggle:
    ldi aux, 194
    out TCNT0, aux
    tst estado
    brne toggle_fin
    in aux, PORTA
    ldi r18, 0x01
    eor aux, r18
    out PORTA, aux
toggle_fin:
    reti

cambia:
    ldi aux, high(64286)
    out TCNT1H, aux
    ldi aux, low(64286)
    out TCNT1L, aux
    tst estado
    breq apagar
    clr estado
    reti
apagar:
    ldi estado, 1
    cbi PORTA, 0
    reti
