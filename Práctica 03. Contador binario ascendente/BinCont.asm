
	.include "m8535def.inc"
	.def aux=r16
	.def cont=r17

I:
	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	clr cont

uno:	
	out porta,cont
	rcall delay
	inc cont
	rjmp uno

; Assembly code auto-generated
; by utility from Bret Mulvey
; Delay 4 000 000 cycles
; 250ms at 16.0 MHz

delay:
	ldi  r18, 3
    ldi  r19, 3
    ldi  r20, 100

L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    nop
	ret
