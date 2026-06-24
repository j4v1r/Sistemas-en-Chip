#define F_CPU 1000000UL

#include <avr/io.h>
#include <avr/interrupt.h>

#define SERVO_PIN PA0

volatile uint8_t pos = 3;     // 2=1.0 ms, 3=1.5 ms, 4=2.0 ms
volatile uint8_t tick = 0;    // Cada tick dura 0.5 ms

ISR(TIMER1_COMPA_vect)
{
    if (tick == 0) {
        PORTA |= (1 << SERVO_PIN);      // Inicia pulso alto
    }

    if (tick == pos) {
        PORTA &= ~(1 << SERVO_PIN);     // Termina pulso alto
    }

    tick++;

    if (tick >= 40) {
        tick = 0;                        // 40 × 0.5 ms = 20 ms
    }
}

void configurar_servo(void)
{
    /* PA0: señal del servo */
    DDRA |= (1 << PA0);
    PORTA &= ~(1 << PA0);

    /* PD5, PD6 y PD7: botones con pull-up */
    DDRD &= ~((1 << PD5) | (1 << PD6) | (1 << PD7));
    PORTD |= (1 << PD5) | (1 << PD6) | (1 << PD7);

    /* Timer1 en modo CTC: interrupción cada 0.5 ms */
    TCCR1A = 0x00;
    TCCR1B = (1 << WGM12) | (1 << CS10);

    OCR1A = (F_CPU / 2000UL) - 1;  // 500 µs

    TIMSK = (1 << OCIE1A);

    sei();
}

int main(void)
{
    configurar_servo();

    while (1) {
        if (!(PIND & (1 << PD5))) {
            pos = 2;   // 1.0 ms: extremo inicial
        }
        else if (!(PIND & (1 << PD6))) {
            pos = 3;   // 1.5 ms: centro
        }
        else if (!(PIND & (1 << PD7))) {
            pos = 4;   // 2.0 ms: extremo final
        }
    }
}
