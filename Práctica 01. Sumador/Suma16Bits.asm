.include "m8535def.inc"

ser r16
out ddra,r16      
out ddrc,r16     
out portb,r16
out portd,r16

otro:
    in r16,pinb   
    in r17,pind   
    
    add r16,r17  
    
    clr r18      
    adc r18,r18   

    out porta,r16 
    out portc,r18

    rjmp otro
