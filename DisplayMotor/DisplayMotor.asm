	.include "m8535def.inc"
	.def aux = r16
	.def npul = r17
	.equ a=0
	.equ b=1
	.equ c=2
	.equ d=3
	.equ e=4
	.equ f=5
	.equ g=6
	.equ on=4
	.equ off=2


.macro segm
	ldi npul,5
	
dos:
	sbi porta,@0
	ldi aux,@1

uno:
	rcall medms
	dec aux
	brne uno
	cbi porta,@0
	ldi aux,40-@1

cta:
	rcall medms
	dec aux
	brne cta
	dec npul
	brne dos

.endm;Fin de la macro 'segm'

.macro ver
	segm a,@0
	segm b,@1
	segm c,@2
	segm d,@3
	segm e,@4
	segm f,@5
	segm g,@6
.endm;Fin de la macro 'ver'


	ldi aux,low(RAMEND)
	out spl,aux
	ldi aux,high(RAMEND)
	out sph,aux
	ser aux
	out ddra,aux
	out portd,aux

test:
	ver off,on,on,off,off,off,off
	rcall seg3
	rjmp test

medms:
	ldi r18,164
L1:
	dec r18
	brne L1
	nop
	ret

seg:
	ldi r19,16
	ldi r20,57
	ldi r21,12
L2:
	dec r21
	brne L2
	dec r20
	brne L2
	dec r19
	brne L2
	nop
	ret
