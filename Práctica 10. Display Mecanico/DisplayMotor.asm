.include "m8535def.inc"

.def aux  = r16
.def npul = r17

.equ ON  = 3      ; Pulso para segmento encendido
.equ OFF = 1      ; Pulso para segmento apagado

; Inicialización

    ldi aux, LOW(RAMEND)
    out SPL, aux
    ldi aux, HIGH(RAMEND)
    out SPH, aux

    ser aux
    out DDRA, aux      ; PORTA como salida
    out PORTB, aux     ; Pull-ups en PORTB
    clr aux
    out PORTA, aux

; Tabla hexadecimal 0-F

    ldi aux, 0x71
    push aux
    ldi aux, 0x79
    push aux
    ldi aux, 0x5E
    push aux
    ldi aux, 0x39
    push aux
    ldi aux, 0x7C
    push aux
    ldi aux, 0x77
    push aux
    ldi aux, 0x6F
    push aux
    ldi aux, 0x7F
    push aux
    ldi aux, 0x07
    push aux
    ldi aux, 0x7D
    push aux
    ldi aux, 0x6D
    push aux
    ldi aux, 0x66
    push aux
    ldi aux, 0x4F
    push aux
    ldi aux, 0x5B
    push aux
    ldi aux, 0x06
    push aux
    ldi aux, 0x3F
    push aux

    in r28, SPL
    in r29, SPH
    adiw r28, 1

; Bucle principal

main_loop:

    ; Leer valor hexadecimal de PB0-PB3
    in   r22, PINB
    andi r22, 0x0F

    ; Obtener patrón correspondiente
    movw r30, r28
    clr  r27
    add  r30, r22
    adc  r31, r27
    ld   r23, Z

    ; Actualizar segmentos
    ldi r24, 7
    ldi r26, 0x01

seg_loop:

    ; Verificar si el segmento está encendido
    mov  r25, r23
    and  r25, r26
    breq segment_off

segment_on:
    ldi  r25, ON
    rjmp do_servo

segment_off:
    ldi  r25, OFF

do_servo:
    ; Generar pulsos para el servomotor
    rcall servo_pulse

    lsl  r26
    dec  r24
    brne seg_loop

    rjmp main_loop

; Genera 5 pulsos PWM para posicionar el servomotor

servo_pulse:

    ldi  npul, 5

sp_pulse_loop:

    ; Fase alta
    in   aux, PORTA
    or   aux, r26
    out  PORTA, aux

    mov  aux, r25

sp_high_wait:
    rcall medms
    dec  aux
    brne sp_high_wait

    ; Fase baja
    in   aux, PORTA
    com  r26
    and  aux, r26
    com  r26
    out  PORTA, aux

    ldi  aux, 40
    sub  aux, r25

sp_low_wait:
    rcall medms
    dec  aux
    brne sp_low_wait

    dec  npul
    brne sp_pulse_loop

    ret

; Retardo aproximado de 0.5 ms a 1 MHz

medms:
    ldi  r18, 164

medms_loop:
    dec  r18
    brne medms_loop
    nop
    ret
