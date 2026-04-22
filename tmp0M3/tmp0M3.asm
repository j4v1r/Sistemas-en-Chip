	.include "m8535def.inc"
	.def aux=r16
	.def cont=r17

reset:
	rjmp inicio
	nop 
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	rjmp sube

inicio:
	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	ldi aux,1
	out tccr0,aux
	ldi aux,1
	out timsk,aux
	sei
	clr cont

loop:
	out porta,cont
	nop
	nop
	nop
	nop
	rjmp loop

sube:
	inc cont
	reti
