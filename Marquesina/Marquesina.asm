	.include "m8535def.inc"
	.def aux=r16
	.def col=r17

reset:
	rjmp inicio
	.org $009
	rjmp t0_ovf

inicio:
	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	out ddrc,aux
	ldi aux,$77
	mov r0,aux
	ldi aux,$38
	mov r1,aux
	ldi aux,$3f
	mov r2,aux
	ldi aux,$76
	mov r3,aux
	clr zh
	ldi aux,1
	out tccr0,aux
	ldi aux,1
	out timsk,aux
	sei
	rcall val_ini

loop:
	rjmp loop

val_ini:
	ldi col,1
	clr zl
	ld aux,z
	com col
	out portc,col
	com col
	out porta,aux
	ret

t0_ovf:
	out porta,zh
	lsl col
	cpi col,16
	breq uno
	inc zl
	ld aux,z
	com col
	out portc,col
	com col
	out porta,aux

dos:
	reti

uno:
	rcall val_ini
	rjmp dos
	

