.include "m8535def.inc"
	ldi r16,low(RAMEND)
	out spl,r16
	ldi r16,high(RAMEND)
	out sph,r16
	clr xh
	ldi xl,$60

uno: 
	ld r16,x+
	push r16
	cpi xl,$70
	brne uno
	clr yh
	ldi yl,$5F

dos:
	ld r16,x+
	inc yl
	st y,r16
	cpi xl,$80
	brne dos
	ldi xl,$80

tres:
	pop r16
	st -x,r16
	cpi xl,$6F
	brne tres

fin:
	rjmp fin
