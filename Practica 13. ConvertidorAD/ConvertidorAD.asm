.include "m8535def.inc"

.def adh     = r16
.def adl     = r17
.def tecla   = r18
.def temp    = r19
.def dig1    = r20
.def dig2    = r21
.def dig3    = r22
.def dig4    = r23
.def seg     = r24
.def ultima  = r25

; Registros para antirrebote
.def prov    = r13
.def b_cnt   = r14

rjmp start


; =========================================================
; INICIALIZACIÓN
; =========================================================
start:
    ; Inicialización de pila
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; PORTD:
    ; PD0=a, PD1=b, PD2=c, PD3=d,
    ; PD4=e, PD5=f, PD6=g, PD7=dp
    ; Display de ánodo común:
    ; 0 = segmento encendido
    ; 1 = segmento apagado
    ser temp
    out DDRD, temp

    ; PORTB:
    ; PB0=dígito 1
    ; PB1=dígito 2
    ; PB2=dígito 3
    ; PB3=dígito 4
    ; Conexión directa: 1 activa un dígito
    out DDRB, temp

    ; Apaga todos los dígitos
    clr temp
    out PORTB, temp

    ; En ánodo común, FF apaga todos los segmentos
    ldi temp, $FF
    mov dig1, temp
    mov dig2, temp
    mov dig3, temp
    mov dig4, temp
    out PORTD, temp

    clr ultima
    clr prov
    clr b_cnt

    ; ADC0 / PA0
    ; Referencia: AVCC
    ; Resultado ajustado a la izquierda
    ldi temp, $60
    out ADMUX, temp

    ; ADEN=1, prescaler=8
    ldi temp, $83
    out ADCSRA, temp


; =========================================================
; CICLO PRINCIPAL
; =========================================================
loop:
    ; Inicia conversión ADC
    sbi ADCSRA, ADSC

esperar_adc:
    sbic ADCSRA, ADSC
    rjmp esperar_adc

    ; Primero se lee ADCL y después ADCH
    in adl, ADCL
    in adh, ADCH
    mov tecla, adh

    ; Antirrebote
    cp tecla, prov
    breq cuenta_estabilidad

    mov prov, tecla
    clr b_cnt
    rjmp puente_mostrar

cuenta_estabilidad:
    inc b_cnt
    ldi temp, 5
    cp b_cnt, temp
    brlo puente_mostrar

    ; Sin tecla: voltaje bajo, ADC menor que 20h
    cpi tecla, $20
    brlo liberar_tecla

    ; No registra la misma tecla repetidamente
    cp tecla, ultima
    breq puente_mostrar

    mov ultima, tecla
    rjmp procesar_tecla

liberar_tecla:
    clr ultima
    rjmp mostrar

puente_mostrar:
    rjmp mostrar


; =========================================================
; DECODIFICACIÓN CALIBRADA DEL TECLADO ANALÓGICO
;
; Valores reales de ADCH:
;
; 1 = CB–CC    2 = 96      3 = 79      A = 50
; 4 = 6E–6F    5 = 93      6 = 74      B = 4E
; 7 = 60       8 = 8A–8B   9 = 6F      C = 4C
; * = A8       0 = 86      # = 6C      D = 4A
;
; Display de ánodo común:
; 0 = segmento encendido
; =========================================================

procesar_tecla:

    ; 1 = CB–CC
    ; Rango: B9–FF
    cpi tecla, $B9
    brlo tecla_asterisco
    ldi seg, $F9            ; 1
    rjmp guardar


tecla_asterisco:
    ; * = A8
    ; Rango: A0–B8
    ; Se representa como H
    cpi tecla, $A0
    brlo tecla_2
    ldi seg, $89            ; H
    rjmp guardar


tecla_2:
    ; 2 = 96
    ; Rango: 95–9F
    cpi tecla, $95
    brlo tecla_5
    ldi seg, $A4            ; 2
    rjmp guardar


tecla_5:
    ; 5 = 93
    ; Rango: 8F–94
    cpi tecla, $8F
    brlo tecla_8
    ldi seg, $92            ; 5
    rjmp guardar


tecla_8:
    ; 8 = 8A–8B
    ; Rango: 89–8E
    cpi tecla, $89
    brlo tecla_0
    ldi seg, $80            ; 8
    rjmp guardar


tecla_0:
    ; 0 = 86
    ; Rango: 82–88
    cpi tecla, $82
    brlo tecla_3
    ldi seg, $C0            ; 0
    rjmp guardar


tecla_3:
    ; 3 = 79
    ; Rango: 77–81
    cpi tecla, $77
    brlo tecla_6
    ldi seg, $B0            ; 3
    rjmp guardar


tecla_6:
    ; 6 = 74
    ; Rango: 72–76
    cpi tecla, $72
    brlo tecla_9
    ldi seg, $82            ; 6
    rjmp guardar

tecla_9:
    cpi tecla, $6F
    breq mostrar_9
    rjmp tecla_4

mostrar_9:
    ldi seg, $90            ; 9
    rjmp guardar


tecla_4:
    cpi tecla, $6E
    breq mostrar_4
    rjmp tecla_hash

mostrar_4:
    ldi seg, $99            ; 4
    rjmp guardar


tecla_hash:
    ; # = 6C
    ; Acepta 6C–6D
    cpi tecla, $6C
    brlo tecla_7
    ldi seg, $09            ; H.
    rjmp guardar


tecla_7:
    ; 7 = 60
    ; Rango: 58–6B
    cpi tecla, $58
    brlo tecla_A
    ldi seg, $F8            ; 7
    rjmp guardar


; =========================================================
; A, B, C y D:
;
; A = 50
; B = 4E
; C = 4C
; D = 4A
;
; Rangos estrechos para evitar traslapes.
; =========================================================

tecla_A:
    ; A = 50
    ; Rango: 4F–57
    cpi tecla, $4F
    brlo tecla_B
    ldi seg, $88            ; A
    rjmp guardar


tecla_B:
    ; B = 4E
    ; Rango: 4D–4E
    cpi tecla, $4D
    brlo tecla_C
    ldi seg, $83            ; b
    rjmp guardar


tecla_C:
    ; C = 4C
    ; Rango: 4B–4C
    cpi tecla, $4B
    brlo tecla_D
    ldi seg, $C6            ; C
    rjmp guardar


tecla_D:
    ; D = 4A
    ; Rango: 49–4A
    cpi tecla, $49
    brlo t_noise
    ldi seg, $A1            ; d
    rjmp guardar


t_noise:
    rjmp mostrar
; =========================================================
; DESPLAZAMIENTO DE LOS CUATRO DÍGITOS
; =========================================================
guardar:
    mov dig1, dig2
    mov dig2, dig3
    mov dig3, dig4
    mov dig4, seg
    rjmp mostrar


; =========================================================
; MULTIPLEXADO
; DISPLAY DE ÁNODO COMÚN
; ÁNODOS CONECTADOS DIRECTAMENTE A PB0-PB3
;
; PORTB = 00h: todos apagados
; PORTB = 01h: dígito 1
; PORTB = 02h: dígito 2
; PORTB = 04h: dígito 3
; PORTB = 08h: dígito 4
; =========================================================
mostrar:

    ; ---------- Dígito 1 ----------
    clr temp
    out PORTB, temp       ; Apaga todos los dígitos

    mov temp, dig1
    out PORTD, temp       ; Envía segmentos

    ldi temp, $01
    out PORTB, temp       ; PB0 = 1: enciende dígito 1
    rcall delay


    ; ---------- Dígito 2 ----------
    clr temp
    out PORTB, temp

    mov temp, dig2
    out PORTD, temp

    ldi temp, $02
    out PORTB, temp       ; PB1 = 1: enciende dígito 2
    rcall delay


    ; ---------- Dígito 3 ----------
    clr temp
    out PORTB, temp

    mov temp, dig3
    out PORTD, temp

    ldi temp, $04
    out PORTB, temp       ; PB2 = 1: enciende dígito 3
    rcall delay


    ; ---------- Dígito 4 ----------
    clr temp
    out PORTB, temp

    mov temp, dig4
    out PORTD, temp

    ldi temp, $08
    out PORTB, temp       ; PB3 = 1: enciende dígito 4
    rcall delay

    rjmp loop


; =========================================================
; RETARDO PARA EL MULTIPLEXADO
; =========================================================
delay:
    ldi r26, 3
d2:
    ldi r27, 200
d1:
    dec r27
    brne d1
    dec r26
    brne d2
    ret
