	.include "m8535def.inc"
	.def adl=r17
	.def adh=r16
	.def max=r18
	.def min=r19
	rjmp start
	.org $0E
	rjmp conv
start:
	ldi r16,low(RAMEND)
	out spl,r16
	ldi r16,high(RAMEND)
	out sph,r16
	ser r16
	out DDRD,r16
	out DDRB,r16
	ldi r16,$ED ; 1110 1101
	out ADCSRA,r16
	ldi r16,$00
	out ADMUX,r16
	sei
loop:
	out PORTD,adl
	out PORTB,adh
	rjmp loop
conv:
	in adl,ADCL
	in adh,ADCH
	reti
