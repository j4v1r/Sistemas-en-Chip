#include<avr/io.h>
#include<util/delay.h>
#define step1  8;
#define step2  4;
#define step3  2;
#define step4  1;
void config_io(void){
	DDRC = 0x0F;
	DDRD = 0b11111011;
	PORTD = _BV(PD2);
}


void secuencia1(void){
	PORTC = step1;
	_delay_ms (250);
	PORTC = step2;
	_delay_ms (250);
	PORTC = step3;
	_delay_ms (250);
	PORTC = step4;
	_delay_ms (250);
}
void secuencia2(void){
	PORTC = step4;
	_delay_ms (250);
	PORTC = step3;
	_delay_ms (250);
	PORTC = step2;
	_delay_ms (250);
	PORTC = step1;
	_delay_ms (250);
}
int main(void){
	config_io();
	while(1){
		switch(PIND){
			case(4):
				secuencia1();
				break;
			case(0):
				secuencia2();
				break;
		}
	}
}
