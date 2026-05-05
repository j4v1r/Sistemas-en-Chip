
	clr r16
	clr r17
	clr r18

loop:
	dec r16
	brne loop
	dec r17
	brne loop
	dec r18
	brne loop
	ldi r18,$20
	ldi r19,$10
	mov r20,r16
fin:
	rjmp fin
