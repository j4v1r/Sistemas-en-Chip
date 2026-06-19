.include "m8535def.inc"
.def aux  = r16
.def mask = r17

; --- TABLA DE VECTORES DE INTERRUPCI?N ---
.org $000
    rjmp inicio
.org $001           ; Vector INT0 (Reloj del JK en PD2)
    rjmp clk_jk
.org $002           ; Vector INT1 (Reloj del T en PD3)
    rjmp clk_t
.org $012           ; Vector INT2 (Reloj del D en PB2)
    rjmp clk_d

; --- INICIALIZACI?N ---
inicio:
    ; Configuraci?n de Pila
    ldi aux, low(RAMEND)
    out spl, aux
    ldi aux, high(RAMEND)
    out sph, aux

    ; Configuraci?n de Puertos
    ser aux
    out ddra, aux       ; PORTA como salida (Q y Q' de todos)
    
    clr aux
    out ddrb, aux       ; PORTB como entrada (Entradas J,K, T, D y CLK_D)
    out ddrd, aux       ; PORTD como entrada (CLK_JK y CLK_T)

	ser aux
    out portb, aux      ; Habilita resistencias Pull-Up en Puerto B
    out portd, aux      ; Habilita resistencias Pull-Up en Puerto D

    ; Estado Inicial: Todos los FF en Q=0, Q'=1 
    ; JK: PA1=1, PA0=0 | T: PA3=1, PA2=0 | D: PA5=1, PA4=0
    ; Binario: 0010 1010 -> Hexadecimal: $2A
    ldi aux, $2A
    out porta, aux

    ; Configuraci?n de Flancos (Rising Edge / Flanco de subida)
    ldi aux, $0F        ; ISC11, ISC10, ISC01, ISC00 en 1 (INT0 e INT1)
    out mcucr, aux
    
    ldi aux, $40        ; Bit ISC2 en 1 (INT2)
    out mcucsr, aux

    ; Habilitar Interrupciones Externas (INT1, INT0, INT2)
    ldi aux, $E0        ; Bits 7, 6 y 5 en 1
    out gicr, aux

    sei                 ; Habilitar interrupciones globales

fin: 
    rjmp fin            ; Ciclo infinito

; =======================================================
; RUTINA: FLIP-FLOP JK (Bits 0 y 1)
; Entradas: PB0 (J), PB1 (K)
; =======================================================
clk_jk:
    in aux, pinb
    andi aux, $03       ; Aislamos J y K (0000 0011)
    
    cpi aux, $00
    breq jk_memoria     ; J=0, K=0 -> No cambia
    cpi aux, $02
    breq jk_borrado     ; J=0, K=1 -> Reset (Q=0)
    cpi aux, $01
    breq jk_puesta      ; J=1, K=0 -> Set (Q=1)
    
    ; Si no es ninguna de las anteriores, es 3 (Toggle)
    in aux, porta
    ldi mask, $03       ; M?scara para invertir bits 0 y 1
    eor aux, mask
    out porta, aux
jk_memoria:
    reti

jk_borrado:
    in aux, porta
    andi aux, $FC       ; 1111 1100 -> Limpia bits 0 y 1 sin afectar el resto
    ori aux, $02        ; 0000 0010 -> Pone Q=0, Q'=1
    out porta, aux
    reti

jk_puesta:
    in aux, porta
    andi aux, $FC       ; 1111 1100 -> Limpia bits 0 y 1
    ori aux, $01        ; 0000 0001 -> Pone Q=1, Q'=0
    out porta, aux
    reti

; =======================================================
; RUTINA: FLIP-FLOP T (Bits 2 y 3)
; Entrada: PB3 (T)
; =======================================================
clk_t:
    sbis pinb, 3        ; Si el pin T es 1, salta la instrucci?n de retorno
    reti                ; Si T es 0, regresa sin hacer nada

    in aux, porta
    ldi mask, $0C       ; 0000 1100 -> M?scara para invertir bits 2 y 3
    eor aux, mask       ; Aplica la basculaci?n
    out porta, aux
    reti

; =======================================================
; RUTINA: FLIP-FLOP D (Bits 4 y 5)
; Entrada: PB4 (D)
; =======================================================
clk_d:
    sbis pinb, 4        ; Si D es 1, salta a la rutina de 'Set'
    rjmp d_reset        ; Si D es 0, va a 'Reset'

d_set:
    in aux, porta
    andi aux, $CF       ; 1100 1111 -> Limpia bits 4 y 5
    ori aux, $10        ; 0001 0000 -> Pone Q=1, Q'=0
    out porta, aux
    reti

d_reset:
    in aux, porta
    andi aux, $CF       ; 1100 1111 -> Limpia bits 4 y 5
    ori aux, $20        ; 0010 0000 -> Pone Q=0, Q'=1
    out porta, aux
    reti
