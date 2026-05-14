.include "m8535def.inc"

.def temp = r16
.def idx  = r17   
.def cnt  = r18   
.def dig  = r19   

.org 0x00
rjmp START

; =========================================================
; TABLAS DE DATOS
; =========================================================
tabla:
.db 0xBF, 0x8E ; Indice 0: Espacio, Indice 1: E
.db 0xC0, 0xC6 ; Indice 2: S,       Indice 3: C
.db 0x88, 0xBF ; Indice 4: O,       Indice 5: M

mensaje:
.db 0, 0, 0, 0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0

START:
    ; Inicializar Stack Pointer
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Configurar Puertos
    ldi temp, 0xFF
    out DDRA, temp      ; Anodos (PA0-PA3)
    out DDRC, temp      ; Segmentos (PC0-PC7)
    
    clr idx             ; Inicio del scroll

MAIN:
    ldi cnt, 60         ; Velocidad (Aumenta para ir mas lento)
REFRESH_LOOP:
    rcall MULTIPLEXAR
    dec cnt
    brne REFRESH_LOOP

    inc idx
    cpi idx, 10         ; LIMITE CAMBIADO: Subimos a 10 porque ESCOM tiene una letra mas
    brne MAIN
    clr idx
    rjmp MAIN

; =========================================================
; SUBRUTINA DE MULTIPLEXADO
; =========================================================
MULTIPLEXAR:
    ldi dig, 0          
    ldi r21, 0x01       ; Empezar con PA0

CICLO_MUX:
    ldi temp, 0x00      ; Apagar todo (Anti-fantasma)
    out PORTA, temp

    ; Calcular direccion del caracter: (mensaje * 2) + idx + dig
    ldi ZH, high(mensaje << 1)
    ldi ZL, low(mensaje << 1)
    mov temp, idx
    add temp, dig
    add ZL, temp
    ldi temp, 0
    adc ZH, temp
    lpm r23, Z          ; Leer indice de la letra

    ; Calcular direccion de la forma: (tabla * 2) + r23
    ldi ZH, high(tabla << 1)
    ldi ZL, low(tabla << 1)
    add ZL, r23
    adc ZH, temp
    lpm temp, Z         ; Leer segmentos
    out PORTC, temp     

    out PORTA, r21      ; Encender digito actual

    rcall DELAY_4MS

    lsl r21             ; Pasar al siguiente anodo
    inc dig
    cpi dig, 4
    brlo CICLO_MUX
    ret

; =========================================================
; RETARDO 4ms
; =========================================================
DELAY_4MS:
    ldi  r24, 20
D1: ldi  r25, 100
D2: dec  r25
    brne D2
    dec  r24
    brne D1
    ret
