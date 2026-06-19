; ===================================================================
; PROYECTO: Sistema Unifila (Banco) - VERSIÓN 4 DÍGITOS CON EEPROM
; FORMATO: C-t-d-u (ej. 1 t 0 1)
; Cajas: 1 a 5 | Turnos: 01 a 29 (Guarda en EEPROM con botón en INT0)
; ===================================================================
.include "m8535def.inc"

; --- VARIABLES Y REGISTROS ---
.def aux = r16
.def caja_val = r18      ; Guarda el número de caja (1 al 5)
.def turno_d = r19       ; Decenas del turno (0 al 2)
.def turno_u = r20       ; Unidades del turno (0 al 9)

; ===================================================================
; VECTORES DE INTERRUPCIÓN
; ===================================================================
.org 0x0000
    rjmp inicio          ; Vector 1: Reset del sistema

.org 0x0001
    rjmp isr_guardar     ; Vector 2: Interrupción Externa INT0 (Botón Guardar)

; --- TABLA DE CARACTERES (0 al 9) ---
tabla_7seg:
    .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90

; ===================================================================
; MACRO: checa_boton
; ===================================================================
.macro checa_boton
    sbic PINB, @0        
    rjmp fin_macro_@0
    
    ldi caja_val, @1     
    rcall inc_turno      

espera_soltar_@0:
    rcall display_mux    
    sbis PINB, @0        
    rjmp espera_soltar_@0 

fin_macro_@0:
.endm

; ===================================================================
; CONFIGURACIÓN INICIAL
; ===================================================================
inicio:
    ; 1. Configurar Stack Pointer
    ldi aux, low(RAMEND)
    out spl, aux
    ldi aux, high(RAMEND)
    out sph, aux

    ; 2. Configurar Puertos de Salida
    ser aux
    out DDRA, aux        ; Puerto A = Salida (Segmentos)
    out DDRC, aux        ; Puerto C = Salida (Selectores de dígitos)

    ; 3. Configurar Puerto B (Botones de Cajas)
    clr aux
    out DDRB, aux        ; Puerto B = Entrada
    ser aux
    out PORTB, aux       ; Pull-ups del Puerto B activos

    ; 4. Configurar Pin PD2 para el botón de INT0 (Guardar)
    cbi DDRD, 2          ; PD2 como entrada
    sbi PORTD, 2         ; Activar pull-up interno en PD2

    ; 5. Configurar Interrupción Externa INT0
    ldi aux, (1 << ISC01) ; Configura INT0 para activarse por flanco de bajada (Falling Edge)
    out MCUCR, aux
    ldi aux, (1 << INT0)  ; Habilita la interrupción externa INT0
    out GICR, aux

    ; 6. Cargar datos previamente guardados en la EEPROM
    rcall cargar_eeprom
    
    sei                  ; Habilitar interrupciones globales

; ===================================================================
; BUCLE PRINCIPAL
; ===================================================================
loop:
    checa_boton 0, 1     ; Botón en PB0 -> Caja 1
    checa_boton 1, 2     ; Botón en PB1 -> Caja 2
    checa_boton 2, 3     ; Botón en PB2 -> Caja 3
    checa_boton 3, 4     ; Botón en PB3 -> Caja 4
    checa_boton 4, 5     ; Botón en PB4 -> Caja 5
    
    rcall display_mux    
    rjmp loop

; ===================================================================
; INTERRUPCIÓN (ISR): BOTÓN GUARDAR ESTADO
; ===================================================================
isr_guardar:
    rcall guardar_eeprom ; Llama a la escritura de datos
    reti                 ; Regresa al flujo principal restableciendo banderas

; ===================================================================
; SUBRUTINA: GUARDAR EN EEPROM
; ===================================================================
guardar_eeprom:
    ; --- Guardar caja_val en dirección 0x00 ---
wait_w1:
    sbic EECR, EEWE      ; Esperar si hay una escritura en progreso
    rjmp wait_w1
    clr aux
    out EEARH, aux       ; Dirección Alta = 0
    out EEARL, aux       ; Dirección Baja = 0x00
    out EEDR, caja_val   ; Cargar dato de caja
    sbi EECR, EEMWE      ; Master Write Enable
    sbi EECR, EEWE       ; Write Enable

    ; --- Guardar turno_d en dirección 0x01 ---
wait_w2:
    sbic EECR, EEWE      
    rjmp wait_w2
    ldi aux, 1
    out EEARL, aux       ; Dirección Baja = 0x01
    out EEDR, turno_d    ; Cargar dato de decenas
    sbi EECR, EEMWE      
    sbi EECR, EEWE       

    ; --- Guardar turno_u en dirección 0x02 ---
wait_w3:
    sbic EECR, EEWE      
    rjmp wait_w3
    ldi aux, 2
    out EEARL, aux       ; Dirección Baja = 0x02
    out EEDR, turno_u    ; Cargar dato de unidades
    sbi EECR, EEMWE      
    sbi EECR, EEWE       
    ret

; ===================================================================
; SUBRUTINA: CARGAR DESDE EEPROM
; ===================================================================
cargar_eeprom:
wait_r:
    sbic EECR, EEWE      ; Asegurar que no se esté escribiendo nada
    rjmp wait_r

    ; Leer dirección 0x00 (Caja)
    clr aux
    out EEARH, aux
    out EEARL, aux
    sbi EECR, EERE       ; Read Enable
    in caja_val, EEDR

    ; Leer dirección 0x01 (Decenas)
    ldi aux, 1
    out EEARL, aux
    sbi EECR, EERE       
    in turno_d, EEDR

    ; Leer dirección 0x02 (Unidades)
    ldi aux, 2
    out EEARL, aux
    sbi EECR, EERE       
    in turno_u, EEDR

    ; --- CONTROL DE SEGURIDAD ---
    ; Si la EEPROM está en 0xFF (vacía de fábrica), asignamos valores iniciales
    cpi caja_val, 0xFF
    brne eeprom_lista
    
    ldi caja_val, 1
    ldi turno_d, 0
    ldi turno_u, 1

eeprom_lista:
    ret

; ===================================================================
; SUBRUTINA: INCREMENTAR TURNO (Límite 29)
; ===================================================================
inc_turno:
    inc turno_u          
    cpi turno_u, 10      
    brne check_max
    
    clr turno_u          
    inc turno_d          

check_max:
    cpi turno_d, 3
    brne fin_inc
    cpi turno_u, 0
    brne fin_inc
    
    clr turno_d
    ldi turno_u, 1
fin_inc:
    ret

; ===================================================================
; SUBRUTINA: MULTIPLEXAR DISPLAY (4 DÍGITOS)
; ===================================================================
display_mux:
    ; DÍGITO 1 (PC0): Número de Caja
    ser aux
    out PORTC, aux       
    mov aux, caja_val
    rcall get_seg
    out PORTA, aux
    ldi aux, 0x08       
    out PORTC, aux
    rcall delay_1ms

    ; DÍGITO 2 (PC1): Letra 't'
    ser aux
    out PORTC, aux
    ldi aux, 0x87        
    out PORTA, aux
    ldi aux, 0x04     
    out PORTC, aux
    rcall delay_1ms

    ; DÍGITO 3 (PC2): Turno Decenas
    ser aux
    out PORTC, aux
    mov aux, turno_d
    rcall get_seg
    out PORTA, aux
    ldi aux, 0x02      
    out PORTC, aux
    rcall delay_1ms

    ; DÍGITO 4 (PC3): Turno Unidades
    ser aux
    out PORTC, aux
    mov aux, turno_u
    rcall get_seg
    out PORTA, aux
    ldi aux, 0x01      
    out PORTC, aux
    rcall delay_1ms

    ser aux
    out PORTC, aux
    ret

; ===================================================================
; LECTOR DE TABLA
; ===================================================================
get_seg:
    ldi ZH, high(tabla_7seg<<1)
    ldi ZL, low(tabla_7seg<<1)
    add ZL, aux
    brcc no_carry
    inc ZH
no_carry:
    lpm aux, Z
    ret

; ===================================================================
; RETARDO 1 ms
; ===================================================================
delay_1ms:
    ldi r17, 200
L1: dec r17
    nop
    nop
    brne L1
    ret
