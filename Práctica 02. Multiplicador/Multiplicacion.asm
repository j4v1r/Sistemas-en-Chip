	.include "m8535def.inc"
	.def M1=r17
	.def M2=r18
	.def MH=r19
	.def ML=r20

I:
	ser r16
	out ddra,r16
	out ddrc,r16
	out portb,r16
	out portd,r16
	in M1,pinb
	in M2,pind
	clr MH
	mov ML,M1

uno:
	dec M2
	breq dos
	add ML,M1
	brcc uno
	inc MH
	rjmp uno

dos:
	out porta,MH
	out portc,ML

fin:
	rjmp fin
