; ============================================================
;  servo_7seg.asm  \u2013  ATmega8535 @ 1 MHz
;  Reads a 4-bit hex digit from PORTB (pins PB0-PB3, pull-ups)
;  and drives 7 servos on PORTA (PA0-PA6) as a 7-segment display.
;
;  Segment \u2192 PORTA pin mapping:
;        PA0 = segment a  (top)
;        PA1 = segment b  (upper-right)
;        PA2 = segment c  (lower-right)
;        PA3 = segment d  (bottom)
;        PA4 = segment e  (lower-left)
;        PA5 = segment f  (upper-left)
;        PA6 = segment g  (middle)
;
;  Servo angles:
;        OFF (segment dark) : pulse = 2 ? ~0.5 ms = 1.0 ms \u2192 0?
;        ON  (segment lit)  : pulse = 3 ? ~0.5 ms = 1.5 ms \u2192 90?
;        Period = 40 ? ~0.5 ms = 20 ms (50 Hz standard)
;        5 pulses are sent per segment so the servo reliably reaches
;        its target position before the display is refreshed.
;
;  Register map:
;        r16 (aux)  \u2013 scratch / delay & pulse-width counter
;        r17 (npul) \u2013 pulse repetition counter (5 per segment)
;        r18        \u2013 inner loop counter for medms (DO NOT clobber
;                     between the `mov aux,r25` and `brne high_wait`)
;        r22        \u2013 digit input  0-F
;        r23        \u2013 segment pattern byte for current digit
;        r24        \u2013 outer loop: segments remaining (7 \u2192 1)
;        r25        \u2013 pulse width for the current segment (ON or OFF)
;        r26        \u2013 bitmask for the current PORTA pin
;        r27        \u2013 zero-extend register for Z-pointer arithmetic
;        r28,r29    \u2013 Y: base of the 16-entry lookup table on stack
;        r30,r31    \u2013 Z: Y + digit-index during table lookup
; ============================================================

.include "m8535def.inc"

.def aux  = r16
.def npul = r17

.equ ON  = 3    ; 3 units ? 0.5 ms = 1.5 ms  \u2192  90?
.equ OFF = 1    ; 2 units ? 0.5 ms = 1.0 ms  \u2192   0?

; ------------------------------------------------------------
;  Segment patterns (bit N = segment at PORTA pin N)
;  Identical to the standard common-cathode encoding used in
;  the reference codes, so the same lookup values apply:
;       bit0=a  bit1=b  bit2=c  bit3=d  bit4=e  bit5=f  bit6=g
; ------------------------------------------------------------
;  Digit | Pattern | Hex    Segments ON
;    0   | 0111111 | 0x3F   a b c d e f
;    1   | 0000110 | 0x06   b c
;    2   | 1011011 | 0x5B   a b d e g
;    3   | 1001111 | 0x4F   a b c d g
;    4   | 1100110 | 0x66   b c f g
;    5   | 1101101 | 0x6D   a c d f g
;    6   | 1111101 | 0x7D   a c d e f g
;    7   | 0000111 | 0x07   a b c
;    8   | 1111111 | 0x7F   a b c d e f g
;    9   | 1101111 | 0x6F   a b c d f g
;    A   | 1110111 | 0x77   a b c e f g
;    B   | 1111100 | 0x7C   c d e f g
;    C   | 0111001 | 0x39   a d e f
;    D   | 1011110 | 0x5E   b c d e g
;    E   | 1111001 | 0x79   a d e f g
;    F   | 1110001 | 0x71   a e f g
; ------------------------------------------------------------

; ============================================================
;  INITIALISATION
; ============================================================

    ; Stack pointer
    ldi aux, LOW(RAMEND)
    out SPL, aux
    ldi aux, HIGH(RAMEND)
    out SPH, aux

    ; PORTA = output (7 servo signals on PA0-PA6)
    ; PORTB = input with pull-ups (digit on PB0-PB3)
    ser aux
    out DDRA,  aux      ; all PORTA pins output
    out PORTB, aux      ; enable PORTB pull-ups
    clr aux
    out PORTA, aux      ; all servo pins LOW at startup

; ------------------------------------------------------------
;  Build a 16-byte lookup table on the stack.
;  Push in reverse order (F first, 0 last) so that after all
;  pushes the top-of-stack holds the pattern for digit 0.
;  Y is then set to SP+1, i.e. the address of the '0' entry.
;  Digit N is at address  Y + N.
; ------------------------------------------------------------

    ldi aux, 0x71   ; F
    push aux
    ldi aux, 0x79   ; E
    push aux
    ldi aux, 0x5E   ; D
    push aux
    ldi aux, 0x39   ; C
    push aux
    ldi aux, 0x7C   ; B
    push aux
    ldi aux, 0x77   ; A
    push aux
    ldi aux, 0x6F   ; 9
    push aux
    ldi aux, 0x7F   ; 8
    push aux
    ldi aux, 0x07   ; 7
    push aux
    ldi aux, 0x7D   ; 6
    push aux
    ldi aux, 0x6D   ; 5
    push aux
    ldi aux, 0x66   ; 4
    push aux
    ldi aux, 0x4F   ; 3
    push aux
    ldi aux, 0x5B   ; 2
    push aux
    ldi aux, 0x06   ; 1
    push aux
    ldi aux, 0x3F   ; 0  \u2190 SP now points here
    push aux

    ; Y = address of the '0' entry  (SP + 1 after all 16 pushes)
    in r28, SPL
    in r29, SPH
    adiw r28, 1         ; Y \u2192 pattern for digit 0

; ============================================================
;  MAIN LOOP  \u2013 runs continuously
; ============================================================

main_loop:

    ; --------------------------------------------------------
    ;  1. Read digit from PORTB lower nibble (active-low with
    ;     pull-ups, so no inversion needed \u2013 keys short to GND,
    ;     hardware encoder or BCD switch drives PB0-PB3).
    ; --------------------------------------------------------
    in   r22, PINB
    andi r22, 0x0F          ; keep only lower 4 bits  (0-15)

    ; --------------------------------------------------------
    ;  2. Fetch segment pattern from stack table.
    ;     Z = Y + digit  \u2192  LD r23, Z
    ; --------------------------------------------------------
    movw r30, r28           ; Z = Y (base address of table)
    clr  r27                ; zero for carry-less add
    add  r30, r22           ; Z_low += digit
    adc  r31, r27           ; propagate carry to Z_high
    ld   r23, Z             ; r23 = segment pattern for the digit

    ; --------------------------------------------------------
    ;  3. Drive the 7 servo signals one at a time.
    ;     r24 = segments remaining (counts 7 down to 1)
    ;     r26 = bitmask (starts at 0x01 for PA0, shifts left)
    ; --------------------------------------------------------
    ldi r24, 7              ; 7 segments  (a \u2026 g)
    ldi r26, 0x01           ; start with PA0 (segment a)

seg_loop:

    ; Test whether this segment should be ON or OFF
    mov  r25, r23
    and  r25, r26           ; isolate the bit for this segment
    breq segment_off

segment_on:
    ldi  r25, ON            ; 1.5 ms pulse \u2192 90?
    rjmp do_servo

segment_off:
    ldi  r25, OFF           ; 1.0 ms pulse \u2192 0?

do_servo:
    rcall servo_pulse       ; send 5 pulses  (r26=mask, r25=width)

    lsl  r26                ; advance mask to next pin
    dec  r24
    brne seg_loop           ; repeat for all 7 segments

    rjmp main_loop

; ============================================================
;  SUBROUTINE: servo_pulse
;  Sends 5 standard RC servo pulses to the pin(s) selected by
;  the bitmask in r26.  Pulse width = r25 ? ~0.5 ms.
;  Period = 40 ? ~0.5 ms \u2248 20 ms (50 Hz).
;
;  Entry  : r25 = pulse-width multiplier (ON=3 or OFF=2)
;           r26 = PORTA bitmask for the target pin
;  Exit   : r25, r26 unchanged
;  Modifies: r16 (aux), r17 (npul), r18 (medms scratch)
; ============================================================

servo_pulse:
    ldi  npul, 5            ; send 5 pulses per call

sp_pulse_loop:

    ; \u2500\u2500 HIGH phase \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    in   aux, PORTA
    or   aux, r26
    out  PORTA, aux         ; raise servo pin(s)

    mov  aux, r25           ; load high-time count
sp_high_wait:
    rcall medms             ; ~0.5 ms  (uses r18 only)
    dec  aux
    brne sp_high_wait

    ; \u2500\u2500 LOW phase \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    in   aux, PORTA
    com  r26                ; invert mask  (temporary)
    and  aux, r26
    com  r26                ; restore mask
    out  PORTA, aux         ; lower servo pin(s)

    ldi  aux, 40
    sub  aux, r25           ; low-time count = 40 - width
sp_low_wait:
    rcall medms             ; ~0.5 ms
    dec  aux
    brne sp_low_wait

    dec  npul
    brne sp_pulse_loop

    ret

; ============================================================
;  SUBROUTINE: medms
;  Delay of approximately 0.5 ms at 1 MHz clock.
;  Cycle count: 2 + 3?163 + 2 + 4 = 497 cycles \u2248 0.497 ms
;  (matching the reference codes' 164-iteration loop + nop)
;
;  Modifies: r18
; ============================================================

medms:
    ldi  r18, 164
medms_loop:
    dec  r18
    brne medms_loop
    nop
    ret
