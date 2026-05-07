.include "m8535def.inc"
	.def aux = r16
	.def cont = r17
	
reset:
	rjmp inicio
	rjmp sube
	rjmp baja

inicio:
	; Inicialización del Stack Pointer
	ldi aux, low(RAMEND)
	out spl, aux
	ldi aux, high(RAMEND)
	out sph, aux

	; Configurar Puerto C como salida (antes era DDRA)
	ser aux
	out ddrc, aux 

	; Configuración de interrupciones en Puerto D
	ldi aux, 0b00001100
	out portd, aux
	ldi aux, 0b00001110
	out mcucr, aux
	ldi aux, 0b11000000
	out gicr, aux

	sei
	clr cont 
	
loop:
	; Enviar el contador al Puerto C (antes era PORTA)
	out portc, cont
	nop
	nop
	nop
	rjmp loop
	
sube:
	inc cont
	reti

baja:
	dec cont
	reti
