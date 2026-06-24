#include <avr/io.h>
#include <avr/interrupt.h>
void init_comparador(void){
	DDRC=0b11111111;
	ACSR=_BV(ACIE);
	sei();
}
ISR(ANA_COMP_vect){
	if(PINC==0x39)
		PORTC=0x40;
	else if(PINC==0x40)
		PORTC=0x39;
}
int main(void){
	init_comparador();
	PORTC=0x40;
	while(1);
}
