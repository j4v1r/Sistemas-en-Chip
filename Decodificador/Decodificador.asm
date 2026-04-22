.include "m8535def.inc" 
.def dato = r16
 ser dato 
 out ddra,dato 
 out portb,dato 
 ldi r20,$3f 
 ldi r21,6 
 ldi r22,$5b 
 ldi r23,$4f 
 ldi r24,$66 
 ldi r25,$6d 
 ldi r27,7 
 ldi r28,$7f 
 ldi r29,$6f 
 clr zh equi: 
 ldi zl,20 
 in dato,pinb 
 andi dato,$0f 
 add zl,dato 
 ld dato,z 
 out porta,dato 
 rjmp equi
