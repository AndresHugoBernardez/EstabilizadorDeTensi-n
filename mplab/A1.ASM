
                list p=16F873A
                include "p16f873a.inc"
                __CONFIG 0x3F39; OSCILADOR XT, SIN WDT









; ESTE PROGRAMA USA EL PUERTO B PARA MOSTRAR 4 DISPLAYS 7 SEGMENTOS 
;  PUERTOB BIT 7.. 4 ELEGIR DISPLAY
;  PUERTOB BIT 3.. 0 AL BCD
;
; EL PUERTO C PARA PRENDER 7 RELES
; EL PUERTO A PARA TOMAR MEDICIONES





MILISEGUNDO EQU 0X30
CUARTOSEGUNDO EQU 0X31
SEGUNDO       EQU 0X32
ADCFLAG       EQU 0X33


FRECFLAG      EQU 0X34   ; ESTA BANDERA SE ACTIVA CADA 250 MILISEGUNDOS
FRECFLAG2     EQU 0X35   ; ESTA BANDERA SE ACTIVA CADA 5 SEGUNDOS

FREC1         EQU 0X36   ; CADA VEZ QUE LA TENSIÓN SE ENCUENTRA EN DETERMINADO NIVEL SE 
                        ;INCREMENTA EL FRECx CORRESPONDIENTE
FREC2         EQU 0X37   ; CADA 250 MSEG APROXIMADAMENTE SE TOMA CUAL ES EL QUE MAS AUMENTÓ.
FREC3         EQU 0X38
FREC4         EQU 0X39
FREC5         EQU 0X3A
FREC6         EQU 0X3B
FREC7         EQU 0X3C
FREC0         EQU 0X4E
FREC8         EQU 0X4F


POSICIONX     EQU 0X3D
INDICEX       EQU 0X3E    ; VARIABLES PARA DIRECCIONAMIENTO INDIRECTO, SE USAN EN LAS COMPARACIONES
                              ; DE LAS FRECUENCIAS
VALORX        EQU 0X3F






WREGAUX       EQU 0X40
STATUSAUX     EQU 0X41
PCLATHAUX     EQU 0X42

FRECUENCIA0   EQU 0X45
FRECUENCIA1   EQU 0X46   ;  CADA VEZ QUE SE DECIDE CUAL FRECUENCIA AUMENTÓ ENTRE LOS FRECx SE INCREMENTE
                         ; EN UNO EL REGISTRO FRECUENCIAx CORRESPONDIENTE
FRECUENCIA2   EQU 0X47   ; CADA 5 SEGUNDOS SE TOMA EL QUE MAS HAYA AUMENTADO Y CON ESO SE PRENDE UN RELÉ
FRECUENCIA3   EQU 0X48   ; EL REGISTRO FRECUENCIAx ES LA CONTINUACION DE FRECx, PERO COMO CADA REGISTRO USA 8 BITS, 
FRECUENCIA4   EQU 0X49   ;SE USAN 2 PARA PODER CONTAR CADA 5 SEGUNDOS CON UNA ESPECIE DE PROMEDIACION
FRECUENCIA5   EQU 0X4A
FRECUENCIA6   EQU 0X4B
FRECUENCIA7   EQU 0X4C
FRECUENCIA8   EQU 0X4D




DISPLAY1    EQU 0X51     ; VARIABLES PARA EL DISPLAY
DISPLAY2    EQU 0X52
DISPLAY3    EQU 0X53
DISPLAY4    EQU 0X54
DISPLAYFLAG   EQU 0X55



ARITCARRIER EQU 0X5C ; VARIABLES PARA OPERACIONES MATEMATICAS GENERALES
ARIT_AUX    EQU 0X5D
NUM1        EQU 0X5E
NUM2        EQU 0X5F
DIVDRTAH    EQU 0X60 
DIVDRTAL    EQU 0X61

NUMDH       EQU 0X62
NUMDL       EQU 0X63

ADPROML     EQU 0X64
ADPROMH     EQU 0X65

UC          EQU 0X66 ; UNIDAD DE CONVERSOR
DCV         EQU 0X67 ; DECIMA DE CONVERSOR
CC          EQU 0X68; LIMPIAR CENTESIMA DE CONVERSOR
MC          EQU 0X69; LIMPIAR MILESIMA DE CONVERSOR
DMC         EQU 0X70; LIMPIAR DECIMA DE MILESIMA DE CONVERSOR
CMC         EQU 0X71; LIMPIAR CENTESIMA DE MILESIMA DE CONVERSOR           

COMPA       EQU 0X75



                ORG 0X00
                GOTO CONFIGURACION
                GOTO CONFIGURACION


;-----------  TEORÍA: COMPARACIONES
;------- USANDO EL SUBWF F,0
;
;   SI W<F   -> Z=0 C=1
;   SI W== F -> Z=1 C=1
;   SI W>F   -> Z=0 C=0
;------- USANDO EL SUBLW K
;
;   SI W<K   -> Z=0 C=1
;   SI W== K -> Z=1 C=1
;   SI W>K   -> Z=0 C=0
;
;




                ORG 0X04
                

                MOVWF WREGAUX   ; GUARDAR REGISTROS IMPORTANTES: PCLATH STATUS Y WREG
                MOVF  STATUS,0
                MOVWF STATUSAUX
                MOVF  PCLATH,0

                MOVWF PCLATHAUX
                
                BCF STATUS,IRP   ; IR AL BANCO 0 (ES IMPORTANTE PORQUE EN MOMENTOS EL PROGRAMA CAMBIA EL BANCO
                                 ; HAY QUE TENER CUIDADO CON LAS INTERRUPCIONES)
                BCF STATUS,RP0
                BCF STATUS,RP1

                CLRF PCLATH
                NOP
                NOP
                NOP

                MOVLW .133
                MOVWF TMR0  ; TIENE QUE CONTAR 125 PERO EMPIEZA EN 133 YA QUE HAY 16 INSTRUCCIONES ANTES


                BCF INTCON,2; TMR0IF:0 SE REINICIA LA INTERRUPCION

                ;BSF DISPLAYFLAG,0;  SE HABILITA PARA ATENDER AL DISPLAY


                BSF ADCFLAG,0;      SE HABILITA PARA ATENDER AL CONVERSOR


                INCF MILISEGUNDO,1       ; MILISEGUNDO++
                MOVF MILISEGUNDO,0     ; MILISEGUNDO> 249??
                SUBLW .249        
                BTFSC STATUS,C
                GOTO  SALIRINT       ;NO
                
                CLRF MILISEGUNDO     ;SI  ;MILISEGUNDO=0

                BSF FRECFLAG,0;  SE HABILITA PARA ATENDER A FRECFLAG
                ;BSF ADCFLAG,1; HABILITACION DE DIGITALIZACION




                INCF CUARTOSEGUNDO,1      ; CUARTOSEGUNDO++
                MOVF CUARTOSEGUNDO,0    ; CUARTOSEGUNDO>3 ??
                SUBLW .3
                BTFSC STATUS,C
                GOTO  SALIRINT        ;NO
                CLRF CUARTOSEGUNDO    ;SI   CUARTOSEGUNO=0  




                INCF SEGUNDO,1      ; SEGUNDO++
                MOVF SEGUNDO,0    ; SEGUNDO>2 ??
                SUBLW .2
                BTFSC STATUS,C
                GOTO  SALIRINT        ;NO
                CLRF SEGUNDO    ;SI   SEGUNDO=0   

                BSF FRECFLAG2,0;  SE HABILITA PARA ATENDER FRECFLAG2






SALIRINT        MOVF PCLATHAUX,0 ; RESCATAR VARIABLES GUARDADAS
                MOVWF PCLATH
                MOVF STATUSAUX,0
                MOVWF STATUS
                MOVF WREGAUX,0   


                RETFIE



;-------------------------------------------------------
;-------------------------------------------------------
;-------------------------------------------------------





CONFIGURACION


                BCF STATUS, IRP

                BCF STATUS, RP1  ; RP1:RP0= 01 *************BANCO 1
                BSF STATUS, RP0;



                                  ;---------TIMER 0

                MOVLW B'00000010'  ;  prescaler = 1:4  ; tiempo = 4*1/4Mhz*8= 8 microsegundos 
                                   ;(cada 125 cuentas pasa un misegundo)
                MOVWF OPTION_REG




                                  ; ----------CONVERSOR PARTE 1 DE 2
                MOVLW B'01001111' ; TOSC 1/16 / PUERTO AN0 (PORTA0)

                                  ; AQUI SE HA ELEGIDO CON REFERENCIA INTERNA
                                  ; EN EL PROGRAMA CON REFRENCIA HAY QUE PONER B'01001111'
                                  ; O SI SE DESEA OTRO CANAL PONER EN B'01001101'
                MOVWF ADCON1    
                CLRF PIE1         ; SIN INTERRUPCIONES  

          




                                    ;-------------PUERTOS

                MOVLW B'00000000'
                MOVWF TRISC
                MOVWF TRISB
                MOVLW 0XFF
                MOVWF TRISA





                BCF STATUS,RP0 ; RP1:RP0= 00  *****************BANCO 0



                                   ; ------------CONVERSOR PARTE 2 DE 2

                MOVLW B'01000001' ; 1/16  // CANAL AN0 // CONVERSOR PRENDIDO
                MOVWF ADCON0



                CLRF PORTC

                CLRF PORTB







                                    ;INICIALIZANDO VARIABLES GENERALES
                CLRF MILISEGUNDO
                CLRF CUARTOSEGUNDO
                CLRF PCLATH

                MOVLW .8
                MOVWF DISPLAY4
                MOVLW .7
                MOVWF DISPLAY3
                MOVLW .6
                MOVWF DISPLAY2
                MOVLW .5
                MOVWF DISPLAY1
                CLRF DISPLAYFLAG
                CLRF ADCFLAG
                





                MOVLW B'10100000' ; <<<<<<<<< GLOBAL INTERRUPTION ACTIVADAS, INTERRUPCION TMR0 ACTIVADO
                MOVWF INTCON

                MOVLW .131 ; INICIALIZAR TIMER 0
                MOVWF TMR0

               
;----------------------------------------------------
;====================================================*******************************************
;----------------------------------------------------


BUCLE          


DISPLAY         

                BTFSS DISPLAYFLAG,0
                GOTO PROMFREC
                CLRF PORTB               
                BCF DISPLAYFLAG,0; SE DESHABILITA LA ATENCIÓN DEL DISPLAY

                MOVF MILISEGUNDO,0
                ANDLW B'00000011'
                ADDWF PCL,1

                GOTO DIS1
                GOTO DIS2
                GOTO DIS3
                GOTO DIS4


DIS1            MOVF DISPLAY1,0
                MOVWF PORTB
                BSF PORTB,7
                GOTO PROMFREC

DIS2            MOVF DISPLAY2,0
                MOVWF PORTB
                BSF PORTB,6
                GOTO PROMFREC

DIS3            MOVF DISPLAY3,0
                MOVWF PORTB
                BSF PORTB,5
                GOTO PROMFREC

DIS4            MOVF DISPLAY4,0
                MOVWF PORTB
                BSF PORTB,4
                GOTO PROMFREC




                      ;-----------------------SACAR EL DE MAYOR FRECUENCIAS CADA 250 MILISEGUNDOS               


PROMFREC
                BTFSS FRECFLAG,0
                GOTO PROMFREC2

                BCF FRECFLAG,0

                
                CLRF INDICEX ; INICIALIZAMOS CON INDICEX=0 EL PRIMERO DE TODOS
                MOVF FREC0,0
                MOVWF VALORX


;------- USANDO EL SUBWF F,0
;
;   SI W<F   -> Z=0 C=1
;   SI W== F -> Z=1 C=1
;   SI W>F   -> Z=0 C=0

PROMFPASO1      MOVF FREC1,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC2> VALORX?
                GOTO PROMFPASO2; NO

                MOVLW .1
                MOVWF INDICEX  ; SI FREC2 ES MAYOR ENTONCES INDICEX=1
                MOVF FREC1,0
                MOVWF VALORX

PROMFPASO2      MOVF FREC2,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC2> VALORX?
                GOTO PROMFPASO3; NO

                MOVLW .2
                MOVWF INDICEX  ; SI FREC2 ES MAYOR ENTONCES INDICEX=1
                MOVF FREC2,0
                MOVWF VALORX

PROMFPASO3      MOVF FREC3,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC3> VALORX?
                GOTO PROMFPASO4; NO

                MOVLW .3
                MOVWF INDICEX ; SI FREC3 ES MAYOR ENTONCES INDICEX=2
                MOVF FREC3,0
                MOVWF VALORX

PROMFPASO4      MOVF FREC4,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC4> VALORX?
                GOTO PROMFPASO5; NO

                MOVLW .4
                MOVWF INDICEX ; SI FREC4 ES MAYOR ENTONCES INDICEX=3
                MOVF FREC4,0
                MOVWF VALORX

PROMFPASO5      MOVF FREC5,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC5> VALORX?
                GOTO PROMFPASO6; NO

                MOVLW .5
                MOVWF INDICEX ; SI FREC5 ES MAYOR ENTONCES INDICEX=4
                MOVF FREC5,0
                MOVWF VALORX

PROMFPASO6      MOVF FREC6,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC6> VALORX?
                GOTO PROMFPASO7; NO

                MOVLW .6
                MOVWF INDICEX ; SI FREC6 ES MAYOR ENTONCES INDICEX=5
                MOVF FREC6,0
                MOVWF VALORX

PROMFPASO7      MOVF FREC7,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC6> VALORX?
                GOTO PROMFPASO8; NO

                MOVLW .7
                MOVWF INDICEX ; SI FREC6 ES MAYOR ENTONCES INDICEX=5
                MOVF FREC7,0
                MOVWF VALORX

PROMFPASO8      MOVF FREC8,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FREC7> VALORX?
                GOTO PROMFBORRAR; NO

                MOVLW .8
                MOVWF INDICEX ; SI FREC7 ES MAYOR ENTONCES INDICEX=6
                MOVF FREC8,0
                MOVWF VALORX

              

PROMFBORRAR
                CLRF FREC0
                CLRF FREC1
                CLRF FREC2
                CLRF FREC3
                CLRF FREC4
                CLRF FREC5
                CLRF FREC6
                CLRF FREC7
                CLRF FREC8




                MOVF INDICEX,0   ; INDICEX ES DONDE SE GUARDA CUAL DE TODOS ES EL MAYOR DE 0 A 6

                ADDWF PCL,1      ; INDICEX SE AÑADE A PCL QUE ES EL CONTADOR DE SENTENCIAS
                                 ; ESTO HACE QUE SALTE TANTAS LINEAS COMO DICE INDICEX (DE 0 A 6)

                GOTO INCFRE0
                GOTO INCFRE1
                GOTO INCFRE2
                GOTO INCFRE3
                GOTO INCFRE4
                GOTO INCFRE5
                GOTO INCFRE6
                GOTO INCFRE7
                GOTO INCFRE8
                NOP
                NOP
                NOP
                             ; AQUEL QUE HAYA TENIDO MAS FRECUENCIA HARA AUMENTAR FRECUENCIAx CORRESPONDIENTE

INCFRE0         INCF FRECUENCIA0,1
                GOTO BUCLE
INCFRE1         INCF FRECUENCIA1,1
                GOTO BUCLE
INCFRE2         INCF FRECUENCIA2,1
                GOTO BUCLE
INCFRE3         INCF FRECUENCIA3,1
                GOTO BUCLE
INCFRE4         INCF FRECUENCIA4,1
                GOTO BUCLE
INCFRE5         INCF FRECUENCIA5,1
                GOTO BUCLE
INCFRE6         INCF FRECUENCIA6,1
                GOTO BUCLE
INCFRE7         INCF FRECUENCIA7,1
                GOTO BUCLE
INCFRE8         INCF FRECUENCIA8,1
                GOTO BUCLE

                GOTO BUCLE


                                  ;--------------------------------------  2 PROMEDIO



PROMFREC2
                BTFSS FRECFLAG2,0
                GOTO LEERAD

                BCF FRECFLAG2,0

                
                CLRF INDICEX ; INICIALIZAMOS CON INDICEX=0  : EL PRIMERO DE TODOS
                MOVF FRECUENCIA0,0
                MOVWF VALORX


;------- USANDO EL SUBWF F,0
;
;   SI W<F   -> Z=0 C=1
;   SI W== F -> Z=1 C=1
;   SI W>F   -> Z=0 C=0

PROMFPASO12     MOVF FRECUENCIA1,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA2> VALORX?
                GOTO PROMFPASO22; NO

                MOVLW .1
                MOVWF INDICEX
                MOVF FRECUENCIA1,0
                MOVWF VALORX


PROMFPASO22     MOVF FRECUENCIA2,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA2> VALORX?
                GOTO PROMFPASO32; NO

                MOVLW .2
                MOVWF INDICEX
                MOVF FRECUENCIA2,0
                MOVWF VALORX

PROMFPASO32     MOVF FRECUENCIA3,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA3> VALORX?
                GOTO PROMFPASO42; NO

                MOVLW .3
                MOVWF INDICEX
                MOVF FRECUENCIA3,0
                MOVWF VALORX

PROMFPASO42     MOVF FRECUENCIA4,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA4> VALORX?
                GOTO PROMFPASO52; NO

                MOVLW .4
                MOVWF INDICEX
                MOVF FRECUENCIA4,0
                MOVWF VALORX

PROMFPASO52     MOVF FRECUENCIA5,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA5> VALORX?
                GOTO PROMFPASO62; NO

                MOVLW .5
                MOVWF INDICEX
                MOVF FRECUENCIA5,0
                MOVWF VALORX

PROMFPASO62     MOVF FRECUENCIA6,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA6> VALORX?
                GOTO PROMFPASO72; NO

                MOVLW .6
                MOVWF INDICEX
                MOVF FRECUENCIA6,0
                MOVWF VALORX

PROMFPASO72     MOVF FRECUENCIA7,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA6> VALORX?
                GOTO PROMFPASO82; NO

                MOVLW .7
                MOVWF INDICEX
                MOVF FRECUENCIA7,0
                MOVWF VALORX

PROMFPASO82     MOVF FRECUENCIA8,0
                SUBWF VALORX,0
                BTFSC STATUS,C ; FRECUENCIA7> VALORX?
                GOTO PROMFBORRAR2; NO

                MOVLW .8
                MOVWF INDICEX
                MOVF FRECUENCIA8,0
                MOVWF VALORX

              

PROMFBORRAR2
                CLRF FRECUENCIA0
                CLRF FRECUENCIA1
                CLRF FRECUENCIA2
                CLRF FRECUENCIA3
                CLRF FRECUENCIA4
                CLRF FRECUENCIA5
                CLRF FRECUENCIA6
                CLRF FRECUENCIA7
                CLRF FRECUENCIA8


                MOVLW .1       ;  SI SE OBSERVA LA MEMORIA DEL PROGRAMA YA ESTAMOS POR ENCIAMA DE LA POSICION 0100
                MOVWF PCLATH   ;  LA POSICION DEL PROGRAMA ES DE 13 BIS Y PCL SOLO TIENE 8 BITS
                               ; LA VARIABLE PCLATH ES LA PARTE SUPERIOR POR ESO SE PONE A 01
                               ; CUANDO TERMINE LA OPERACION DE SALTOS CONVIENE PONER PCLATH EN 00


                MOVF INDICEX,0

                ADDWF PCL,1    ; SE PRODUCE UN SALTO HACIA [PCLATH:(PCL+INDICEX)]

                GOTO INCFRE20
                GOTO INCFRE21
                GOTO INCFRE22
                GOTO INCFRE23
                GOTO INCFRE24
                GOTO INCFRE25
                GOTO INCFRE26
                GOTO INCFRE27
                GOTO INCFRE28
                NOP
                NOP
                NOP


INCFRE20         MOVLW B'00000000'
                 MOVWF PORTC
                 CLRF PCLATH   ; PCLATH SE RESTAURA A 00
                 GOTO BUCLE
INCFRE21         MOVLW B'00000001'
                 MOVWF PORTC
                 CLRF PCLATH   ; PCLATH SE RESTAURA A 00
                 GOTO BUCLE
INCFRE22         MOVLW B'00000010'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE23         MOVLW B'00000100'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE24         MOVLW B'00001000'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE25         MOVLW B'00010000'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE26         MOVLW B'00100000'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE27         MOVLW B'01000000'
                 MOVWF PORTC
                 CLRF PCLATH
                 GOTO BUCLE
INCFRE28         MOVLW B'00000000'
                 MOVWF PORTC
                 CLRF PCLATH   
                 GOTO BUCLE

                GOTO BUCLE



                                 ;--------------------------------



                          ; IR HACIA EL CONVERSOR



LEERAD          BTFSS ADCFLAG,0
                GOTO BUCLE
                GOTO CONVERTIR
                GOTO CONVERTIR







;----------------------------------------------------------------------------
;============================================================================
;----------------------------------------------------------------------------


;   FUNCION NO UTILIZADA EN ESTE PROGRAMA
POSICIONARX     MOVF POSICIONX,0  ; OBTENEMOS EL VALOR DEL POSICIONX:INDICEX
                ADDWF INDICEX,0
                MOVWF FSR ; INDICAMOS POSICION  ACTUAL EN REGISTRO FRS                
                MOVF INDF,0 ; LEEMOS INDIRECTAMETNE
                MOVWF VALORX; SACAMOS EL VALOR
                RETURN








;----------------DIVICION GENERAL PARA UN NUMERO DESDE 0 A 255  
;   FUNCION NO UTILIZADA EN ESTE PROGRAMA

DIV1:           CLRF ARIT_AUX;  WREG= NUM1 /NUM2(DIVISION ENTERA)..Resto en NUM1
               MOVF NUM2,0;    

BUCLEDIV:      INCF ARIT_AUX,1
               SUBWF NUM1,1
               BTFSC STATUS,C;
               GOTO BUCLEDIV

               ADDWF NUM1,1               
               DECF ARIT_AUX
               MOVF ARIT_AUX,0

               RETURN


;------------------DIVIDIR POR 10 --- ESTE METODO ESTA DISEÑADO PARA UN NUMERO DESDE 0 A 255
;x>99 -> resultado=resultado +10  x=x-100
;x>99 -> resultado=resultado +10  x=x-100
;x>49 -> resultado=resultado+5  x=x-50
;x>29-> resultado= resultado+2  x=x-30
;x>9 -> resultado= resultado+1 x=x-10
;x>9 -> resultado= resultado+1 x=x-10


;------- USANDO EL SUBLW K
;
;   SI W<K   -> Z=0 C=1
;   SI W== K -> Z=1 C=1
;   SI W>K   -> Z=0 C=0



;--------------DIVISION POR 10  
;--------------ESTA FUNCION DEVUELVE   WREG=NUM1/10  RESTO EN NUM1
; ESTA FUNCION SE UTILIZA PARA HACER LA CONVERSION DE HEXADECIMAL A DIGITAL Y PODER MOSTRARLO EN DISPLAY
DIV:
             CLRF ARIT_AUX

             MOVF NUM1,0
             SUBLW .99
             BTFSC STATUS,C
             GOTO DIV102

             MOVLW .100
             SUBWF NUM1,1

             MOVLW .10
             ADDWF ARIT_AUX


             MOVF NUM1,0
             SUBLW .99
             BTFSC STATUS,C
             GOTO DIV102

             MOVLW .100
             SUBWF NUM1,1

             MOVLW .10
             ADDWF ARIT_AUX


DIV102       MOVF NUM1,0
             SUBLW .49
             BTFSC STATUS,C
             GOTO DIV103

             MOVLW .50
             SUBWF NUM1,1

             MOVLW .5
             ADDWF ARIT_AUX

DIV103       MOVF NUM1,0
             SUBLW .29
             BTFSC STATUS,C
             GOTO DIV104

             MOVLW .30
             SUBWF NUM1,1

             MOVLW .3
             ADDWF ARIT_AUX

DIV104       MOVF NUM1,0
             SUBLW .9
             BTFSC STATUS,C
             GOTO DIV106

             MOVLW .10
             SUBWF NUM1,1

             MOVLW .1
             ADDWF ARIT_AUX

DIV105       MOVF NUM1,0
             SUBLW .9
             BTFSC STATUS,C
             GOTO DIV106

             MOVLW .10
             SUBWF NUM1,1

             MOVLW .1
             ADDWF ARIT_AUX

DIV106

             MOVF ARIT_AUX,0
             RETURN
;-----------------------------------------------------
;-----------------------------------------------------
;-----------------------------------------------------


CONVERTIR      
               BCF ADCFLAG,0
               BSF ADCON0,2 

    
ESPERAR_AD:    BTFSC ADCON0,2; EN LA DULCE ESPERA DE LA CONVERSION, TA TA RA TA TA
               GOTO ESPERAR_AD     



               MOVF ADPROMH,0 
               MOVWF NUMDH
               MOVF ADPROML,0
               MOVWF NUMDL

; DIVIDIR POR 16. 
; COMO SE TRABAJA EN BINARIO DIVIDIR POR UN MULTIPLO DE 2 EQUIVALE A MOVER ALGUNOS BITS DE LUGAR.
; EN CASO DE 16  EN BINARIO ES 10000 ESO IMPLICA MOVER 4 BITS.
; ASI COMO SI TRABAJAMOS EN DIGITAL DIVIDIR POR 10 EQUIVALE A CORRER LA COMA HACIA IZQUIERDA O
; SEA MOVER LA UNIDAD, LA DECENA ETC. APROVECHO LO MISMO PERO EN HEXADECIMAL


; POR ESTA RAZON SE USA LEFT JUSTIFIED EN EL CONVERSOR
; SE APROBECHA ESOS BITS DE LA DERECHA PARA GUARDAR LO QUE ESTA DESPUES DEL PUNTO 



; SE IMPLEMENTA UNA ESPECIE DE PROMEDIACION
; AL VALOR PROMEDIO SE LE EXTRAE UNA PARTE DE 1/16 Y SE LE SUMA LA NUEVA LECTURA DIVIDIDA EN 16
; TIENE UNA CONVERGENCIA UN POCO MAS LENTA QUE UN PROMEDIO REAL DE 16 DATOS QUE OCUPARIAN 32 REGISTROS
; LA FINALIDAD ES LA MISMA DE HECHO ESTE METODO ES MEJOR

; AUN SE PUEDRIA MEJORAR LA DIVICION AGREGANDO MAS REGISTROS PARA GUARDAR NUMEROS DESPUES DE LA COMA


DIV16          CLRF DIVDRTAH
               CLRF DIVDRTAL
               MOVF NUMDL,0
               SWAPF NUMDH,0
               MOVWF DIVDRTAH  ;  DIVDRTAH=SWAPF (NUMDH)
               ANDLW B'11110000'
               MOVWF DIVDRTAL  ;   DIVDRTAL=(DIVDRTAH) AND(B'11110000') 
               MOVLW B'00001111'
               ANDWF DIVDRTAH,1; DIVDRTAH=(DIVDRTAH) AND(B'00001111')
               SWAPF NUMDL,0
               ANDLW B'00001111'
               ADDWF DIVDRTAL   ; DIVDRTAL=DIVDRTAL+[SWAPF(NUMDL)] AND(B'00001111')

PROMEDIARAD:  

                                          ;PASO1:   RESTARLE 1/16 AL PROMEDIO
                           ; (RESTA DE DOBLE-BYTE)
              MOVF DIVDRTAL,0;
              SUBWF ADPROML,1; ADPROML=ADPROML-DIVDRTAL
              BTFSS STATUS,C; SI CARRIER ES 0 ES PORQUE ADPROML<DIVDRTAL HAY QUE SACARLE 1 A ADPROMH
              DECF ADPROMH;
              MOVF DIVDRTAH,0;
              SUBWF ADPROMH,1; ADPROMH= ADPROMH-DIVDRTAH 
                                     ; POR SER DIVRTA(H:L) EL 10% DE ADPROM(H:L)  LA RESTA DA UN NUMERO POSITIVO



                                      ;PASO2:  LEER REGISTROS DE CONVERSION Y DIVIDIRLOS EN 16
AGREGARLECTURA
               BSF STATUS, RP0 ; (IR AL BANCO 1) 
               MOVF ADRESL,0;
               BCF STATUS, RP0 ; (VOLVER AL BANCO 0) 
               
               ANDLW B'11000000'; SE FILTRA POR LAS DUDAS, SOLO SON UTILES LOS BITS 7 Y 6
               MOVWF NUMDL
               
               MOVF ADRESH,0
               MOVWF NUMDH

DIV162         CLRF DIVDRTAH
               CLRF DIVDRTAL
               MOVF NUMDL,0
               SWAPF NUMDH,0
               MOVWF DIVDRTAH  ;  DIVDRTAH=SWAPF (NUMDH)
               ANDLW B'11110000'
               MOVWF DIVDRTAL  ;   DIVDRTAL=(DIVDRTAH) AND(B'11110000') 
               MOVLW B'00001111'
               ANDWF DIVDRTAH,1; DIVDRTAH=(DIVDRTAH) AND(B'00001111')
               SWAPF NUMDL,0
               ANDLW B'00001111'
               ADDWF DIVDRTAL   ; DIVDRTAL=DIVDRTAL+[SWAPF(NUMDL)] AND(B'00001111')     
               
                                         ;PASO3: SUMARSELO AL PROMEDIO
                                           ;(SUMA DOBLE-BYTE)
               MOVF DIVDRTAL,0;
               ADDWF ADPROML,1; ADPROML= ADPROML+DIVDRTAL
               BTFSC STATUS,C; SI HAY CARRIER HAY QUE SUMARLE 1 A 
               INCF ADPROMH,1;
               MOVF DIVDRTAH,0;
               ADDWF ADPROMH,1; ADPROMH= ADPROMH+DIVDRTAH



;1.75---- 358.4  5980
;2.25---- 460.8  7333

;2.75---- 563.2  8ccc
;3.25---- 665.6  A666

;3.75---- 768    c000
;4.25---- 870.4  D980

;------- USANDO EL SUBLW K
;
;   SI W<K   -> Z=0 C=1
;   SI W== K -> Z=1 C=1
;   SI W>K   -> Z=0 C=0


;*****************************************************************************************************
;*****************************************************************************************************
;*****************************************************************************************************
;*****************************************************************************************************
;*****************************************************************************************************

; ACA ES DONDE SE HACEN LAS COMPARACIONES SI HAY QUE CAMBIAR VALORES DEBE HACERSE ACA
;*****************************************************************************************************


; ESTA TABLA FUE CONFECCIONADA CON UNA TENSION DE REFERENCIA MAXIMA DE 5.1V Y MINIMA DE 0V
; PARA 4 V SE ASUME QUE HAY 220V EFECTIVOS EN LA LINEA
; EL CONVERSOR TRABAJA EN LEFT JUSTIFIED ESO IMPLICA QUE A LA LECTURA DEL CONVERSOR SE LE MULTIPLICA .64
; POR EJEMPLO SI LEEMOS 857 * 64 =  54905  ESTO EN HEXADECIMAL ES  D679 QUE ES LO QUE TENEMOS QUE COMPARAR.

;TensiónVAC	 TensiónVCC    Conversor      LEFT JUSTIFIED   HEXADECIMAL
;275         5		
;235         4,272727273   857,8966132   54905,38324       D679
;225         4,090909091   821,3903743   52568,98396       CD59
;215         3,909090909   784,8841355   50232,58467       C438
;205         3,727272727   748,3778966   47896,18538       BB18
;195         3,545454545   711,8716578   45559,7861        B1F8
;185         3,363636364   675,3654189   43223,38681       A8D7
;175         3,181818182   638,85918     40886,98752       9FB7
;165         3             602,3529412   38550,58824       9697


;COMO LA COMPARACION SE HACE CON NUMEROS DE 16 BITS NECESITAMOS 2 REGISTROS DE 8 BITS Y COMPARA CADA PAR.


;--------------------------------------------------------------------------------
; TABLA VMAX 4.8 VMIN 0   220=4
;
;Tension VCA    Tension VCC Lectura      Hexadecimal
;245            4,454545455 950,3030303  ED93
;235            4,272727273 911,5151515  E3E0
;225            4,090909091 872,7272727  DA2E
;215            3,909090909 833,9393939  D07C
;205            3,727272727 795,1515152  C6C9
;195            3,545454545 756,3636364  BD17
;185            3,363636364 717,5757576  B364
;175            3,181818182 678,7878788  A9B2
;165            3           640          A000
;
;-----------------------------------------------------------------------------------------
; 
;   TABLA VMAX 4.87 VMIN0 220=3.9
;Tension VCA	Tension VCC	Lectura	Hexadecimal	

;250	4,431818182	931,8648497	E8F7	
;245	4,343181818	913,2275527	E44E	
;235	4,165909091	875,9529587	DAFC	*
;230	4,077272727	857,3156618	D654
;225	3,988636364	838,6783648	D1AB	*
;215	3,811363636	801,4037708	C859	*
;205	3,634090909	764,1291768	BF08	*
;195	3,456818182	726,8545828	B5B6	*
;185	3,279545455	689,5799888	AC65	*
;175	3,102272727	652,3053948	A313	*
;165	2,925	615,0308008	99C1
;150	2,659090909	559,1189098	8BC7



;**********************************************************************************************

COMPARARSALIDA

               CLRF ARITCARRIER
               MOVF ADPROMH,0
               MOVWF COMPA
               INCF COMPA,1
             

               
                                                  ;150 -> 8BC7

               MOVF ADPROML,0
               SUBLW 0XC7
               BTFSC STATUS,C ; ADPROML <= 0XA9
               GOTO COMPA1
               MOVF COMPA,0
               GOTO COMPA11  
COMPA1         MOVF ADPROMH,0
COMPA11        SUBLW 0X8B
               BTFSC STATUS,C; ADPROMH<=0XB2
               GOTO APAGARLED0

                                                  ;250 --> E8F7
               MOVF ADPROML,0
               SUBLW 0XF7
               BTFSC STATUS,C ; ADPROML <= 0X59?
               GOTO COMPA2 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA21  
COMPA2         MOVF ADPROMH,0
COMPA21        SUBLW 0XE8
               BTFSS STATUS,C; ADPROMH>.CD ?
               GOTO APAGARLED8 ;SI

                                                  ;175 --> A313
               MOVF ADPROML,0
               SUBLW 0X13
               BTFSC STATUS,C ; ADPROML <= 0XD7?
               GOTO COMPA3 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA31  
COMPA3         MOVF ADPROMH,0 
COMPA31        SUBLW 0XA3
               BTFSC STATUS,C; ADPROMH<=675
               GOTO PRENDERLED1;SI


                                                  ;185 --> AC65
               MOVF ADPROML,0
               SUBLW 0X65
               BTFSC STATUS,C ; ADPROML <= 0XD7?
               GOTO COMPA4 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA41  
COMPA4         MOVF ADPROMH,0 
COMPA41        SUBLW 0XAC
               BTFSC STATUS,C; ADPROMH<=675
               GOTO PRENDERLED2;SI

                                                  ;195 --> B5B6
               MOVF ADPROML,0
               SUBLW 0XB6
               BTFSC STATUS,C ; ADPROML <= 0XF8?
               GOTO COMPA5 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA51  
COMPA5         MOVF ADPROMH,0
COMPA51        SUBLW 0XB5
               BTFSC STATUS,C; ADPROMH<=.771
               GOTO PRENDERLED3;SI

                                                  ;205 --> BF08
               MOVF ADPROML,0
               SUBLW 0X08
               BTFSC STATUS,C ; ADPROML <= 0X18?
               GOTO COMPA6 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA61  
COMPA6         MOVF ADPROMH,0
COMPA61        SUBLW 0XBF
               BTFSC STATUS,C; ADPROMH<=.748
               GOTO PRENDERLED4;SI

                                                  ;215 --> C859
               MOVF ADPROML,0
               SUBLW 0X59
               BTFSC STATUS,C ; ADPROML <= 0X38?
               GOTO COMPA7 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA71  
COMPA7         MOVF ADPROMH,0
COMPA71        SUBLW 0XC8
               BTFSC STATUS,C; ADPROMH<=784
               GOTO PRENDERLED5;SI

                                                  ;230 --> D654
               MOVF ADPROML,0
               SUBLW 0X54
               BTFSC STATUS,C ; ADPROML <= 0X59?
               GOTO COMPA8 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA81  
COMPA8         MOVF ADPROMH,0
COMPA81        SUBLW 0XD6
               BTFSC STATUS,C; ADPROMH<=821
               GOTO PRENDERLED6;SI


                                                    ;250 --> E8F7
               MOVF ADPROML,0
               SUBLW 0XF7
               BTFSC STATUS,C ; ADPROML <= 0X59?
               GOTO COMPA9 ; ACARREO=1
               MOVF COMPA,0; ACARREO=0
               GOTO COMPA91  
COMPA9         MOVF ADPROMH,0
COMPA91        SUBLW 0XE8
               BTFSC STATUS,C; ADPROMH<=821
               GOTO PRENDERLED7;SI



               MOVLW B'00000000'
               MOVWF PORTC                            
               GOTO LEER_AD 

;  SEGUN CUAL SEA EL NIVEL DE TENSION SE INCREMENTA EN UNO LA FRECx CORRESPONDIENTE

APAGARLED0     INCF FREC0,1
               GOTO LEER_AD
PRENDERLED7    INCF FREC7,1               
               GOTO LEER_AD
PRENDERLED6    INCF FREC6,1
               GOTO LEER_AD
PRENDERLED5    INCF FREC5,1
               GOTO LEER_AD
PRENDERLED4    INCF FREC4,1
               GOTO LEER_AD
PRENDERLED3    INCF FREC3,1
               GOTO LEER_AD
PRENDERLED2    INCF FREC2,1
               GOTO LEER_AD
PRENDERLED1    INCF FREC1,1
               GOTO LEER_AD
APAGARLED8     INCF FREC8,1
               GOTO LEER_AD










;**********************************************************

LEER_AD:
               
   ; EL OJO HUMANO TIENE UN LIMITE DE VELOCIDAD, SE ESTA MUESTREANDO CADA MILISEGUNDO
   ; LOS DISPLAYS SE ACTUALIZAN CADA CUARTO DE SEGUNDO O SEA CADA 250 MILISEGUNDO
   ; ESTO TIENE DOS VENTAJAS
   ; > QUE EL PIC TENGA MENOS TAREAS
   ; > LA OTRA ES EVITAR QUE LOS DISPLAYS CAMBIEN BRUSCAMENTE
   ; SI BIEN LA PROMEDIACION DE LA MEDICIONES TIENE UNA CONVERGENCIA LENTA, AUN SIGUE SIENDO RAPIDA
   ; PARA LOS DISPLAYS
   ; NO TIENE SENTIDO AUMENTAR LAS PROMEDIACIONES PARA LOS DISPLAYS
     
   ; IGUAL ESTO NO AFECTA A LOS RELES YA QUE SI SE HACE OTRAS PROMEDIACIONES ADICIONALES PARA ELLOS


               BTFSS ADCFLAG,1   
               GOTO BUCLE
               
               BCF ADCFLAG,1
               

               CLRF UC; LIMPIAR UNIDAD DE CONVERSOR
               CLRF DCV; LIMPIAR DECIMA DE CONVERSOR
               CLRF CC; LIMPIAR CENTESIMA DE CONVERSOR
               CLRF MC; LIMPIAR MILESIMA DE CONVERSOR
               CLRF DMC; LIMPIAR DECIMA DE MILESIMA DE CONVERSOR
               CLRF CMC; LIMPIAR CENTESIMA DE MILESIMA DE CONVERSOR           





BIT9:          BTFSS ADPROMH,7
               GOTO BIT8

               MOVLW .2
               ADDWF UC,1

               MOVLW .5
               ADDWF DCV,1


BIT8:          BTFSS ADPROMH,6
               GOTO BIT7            

               MOVLW .1
               ADDWF UC,1

               MOVLW .2
               ADDWF DCV,1

               MOVLW .5
               ADDWF CC




BIT7:                        
               BTFSS ADPROMH,5
               GOTO BIT6  

               MOVLW .6
               ADDWF DCV,1

               MOVLW .2
               ADDWF CC

               MOVLW .5
               ADDWF MC,1
               
 
           
BIT6:                   
               BTFSS ADPROMH,4
               GOTO BIT5  

          
               MOVLW .3
               ADDWF DCV,1

               MOVLW .1
               ADDWF CC

               MOVLW .2
               ADDWF MC,1
               
               MOVLW .5
               ADDWF DMC,1

 



BIT5:          BTFSS ADPROMH,3
               GOTO BIT4  

               
               MOVLW .1
               ADDWF DCV,1

               MOVLW .5
               ADDWF CC

               MOVLW .6
               ADDWF MC,1
               
               MOVLW .2
               ADDWF DMC,1

               MOVLW .5
               ADDWF CMC,1



BIT4:          BTFSS ADPROMH,2
               GOTO BIT3  

                 

               MOVLW .7
               ADDWF CC

               MOVLW .8
               ADDWF MC,1
               
               MOVLW .1
               ADDWF DMC,1

               MOVLW .2
               ADDWF CMC,1




BIT3:          BTFSS ADPROMH,1
               GOTO BIT2            



               MOVLW .3
               ADDWF CC

               MOVLW .9
               ADDWF MC,1
               
               MOVLW .0
               ADDWF DMC,1

               MOVLW .6
               ADDWF CMC,1


BIT2:          BTFSS ADPROMH,0
               GOTO BIT1            


   
               MOVLW .1
               ADDWF CC

               MOVLW .9
               ADDWF MC,1
               
               MOVLW .5
               ADDWF DMC,1

               MOVLW .3
               ADDWF CMC,1




BIT1:          BTFSS ADPROML,7
               GOTO BIT0  


   
               MOVLW .9
               ADDWF MC,1
               
               MOVLW .7
               ADDWF DMC,1

               MOVLW .7; (SE HA REDONDEADO PARA ARRIBA)
               ADDWF CMC,1


        


BIT0:          BTFSS ADPROML,6
               GOTO  DIGITALIZAR 

               
               MOVLW .4
               ADDWF MC,1
               
               MOVLW .8
               ADDWF DMC,1

               MOVLW .8
               ADDWF CMC,1



DIGITALIZAR:                   ; EL DIVISOR ES NUM2 QUE FUE PREVIAMENTE CARGADO CON .10
               
              MOVLW 0X0A   ; NUM2=.10 QUE ES USADO COMO DIVISOR DE 1 BYTE
              MOVWF NUM2  

               MOVF CMC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=CMC/10  NUM1=RESTO
               ADDWF DMC,1  ; DMC= DMC+CMC/10
               MOVF NUM1,0
               MOVWF CMC    ; CMC=RESTO

               MOVF DMC,0
               MOVWF NUM1; NUM1=DMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=DMC/10  NUM1=RESTO
               ADDWF MC,1  ; MC= MC+DMC/10
               MOVF NUM1,0
               MOVWF DMC    ; DMC=RESTO

               MOVF MC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=MC/10  NUM1=RESTO
               ADDWF CC,1  ; CC= CC+MC/10
               MOVF NUM1,0
               MOVWF MC    ; MC=RESTO

               MOVF CC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=CC/10  NUM1=RESTO
               ADDWF DCV,1  ; DCV= DCV+CC/10
               MOVF NUM1,0
               MOVWF CC    ; CC=RESTO

               MOVF DCV,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=DCV/10  NUM1=RESTO
               ADDWF UC,1  ; UC= UC+DCV/10
               MOVF NUM1,0
               MOVWF DCV    ; DCV=RESTO


TRANSFERIR:               
               MOVF UC,0;        DISPLAY1=UC //DISPLAY2=DCV // DISPLAY3=CC // DISPLAY4=MC
               MOVWF DISPLAY1;
               MOVF DCV,0;
               MOVWF DISPLAY2;
               MOVF CC,0;
               MOVWF DISPLAY3;
               MOVF MC,0;
               MOVWF DISPLAY4;


               GOTO BUCLE
               GOTO BUCLE




                






               

                

               



                END