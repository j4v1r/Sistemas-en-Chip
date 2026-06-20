	.include "m8535def.inc"
	.def aux=r16
	.def cont=r17
	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	out portb,aux
	clr cont


uno:	
	in aux,pinb
	andi aux,$0F
	out porta,cont


dos:
	rcall delay
	dec aux
	brne dos

	inc cont
	rjmp uno


delay:
	ldi r18,3
	ldi r19,3
	ldi r20,100
	;ldi r18,21
	;ldi r19,75
	;ldi r20,191

L1:
	dec r20
	brne L1
	dec r19
	brne L1
	dec r18
	brne L1
	nop
	ret
