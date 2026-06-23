.include "m8535def.inc"  
.def dato = r16      


	ser dato            ; Pone todos los bits de "dato" en 1 (0xFF)
	out ddra, dato      ; Configura todo el Puerto A como SALIDA (hacia el display)
	out portb, dato     ; Escribe unos en las entradas del Puerto B (Activa Pull-Ups)


aqui: 
	ldi zl, low(tabla_hex * 2) 
	ldi zh, high(tabla_hex * 2) 

	in dato, pinb       
	andi dato, $0f      
	add zl, dato        
	lpm dato, Z   
	com dato        
	out porta, dato      
	rjmp aqui           

tabla_hex:
	.db $3f, 6, $5b, $4f, $66, $6d, $7d, 7, $7f, $6f, $77,$7c, $39, $5e, $79, $71
