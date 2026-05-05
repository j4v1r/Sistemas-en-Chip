	.include "m8535def.inc"
	.def aux=r16

.macro pulso
	sbi porta,0
	ldi aux,@0

uno:
	rcall medms
	dec aux
	brne uno
	cbi porta,0
	ldi aux,@1

cta:
	rcall medms
	dec aux
	brne cta

.endm
	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	out portd,aux

checa:
	sbis pind,5
	rcall cero
	sbis pind,6
	rcall noventa
	sbis pind,7
	rcall cien80
	rjmp checa

cero:
	pulso 2,38
	ret

noventa:
	pulso 3,37
	ret

cien80:
	pulso 4,36
	ret

medms:
	ldi r18,164

L1:
	dec r18
	brne L1
	nop
	ret
