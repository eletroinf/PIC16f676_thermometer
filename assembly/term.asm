;	******    PIC16F676 THERMOMETER    ********
;	***********************************************
;	*	RICARDO MORIM	eletroinf@yahoo.com.br	  *
;	*	http://geocities.yahoo.com.br/eletroinf   *
;	***********************************************

;MAIN FEATURES:
;INTERNAL OSCILLATOR (RC) 4MHZ.
;EXTERN VREF: 2.048V PIN 12 (RA1).
;SENSOR LM35, CONNECTED TO RA0 PIN (PIN 13).
;MUX BY INTERRUPT FROM COUNTING 1024 MACHINE CLOCK CICLES.
;MEASUREMENT: FROM 2?C TO 150?C (LM35 SENSOR).

;PROGRAMMING PINS PIC16F676: VPP:4; VDD:1; VSS:14; CLK:12; DATA:13.

__CONFIG _INTRC_OSC_NOCLKOUT & _MCLRE_OFF & _WDT_OFF & _PWRTE_ON & _CP_OFF & _BODEN_OFF

;INIT:

#include	<p16f676.inc>
;====================DEFINI??ES====================

#DEFINE	D_CEN	PORTC,0
#DEFINE	D_DEZ	PORTC,1
#DEFINE D_UN	PORTA,2
#DEFINE	DP_DRV	PORTA,5

#DEFINE	BANK0	BCF STATUS,RP0
#DEFINE	BANK1	BSF STATUS,RP0

#DEFINE	AD_OK	FLAGS,0		
#DEFINE	DP		FLAGS,1
;================================================

	ORG		0X00			;reset
	
	GOTO	INICIO

;================================================

	CBLOCK	0X20		;VARI?VEIS QUE SER?O UTILIZADAS (MEM?RIA RAM)

		SOMA_AD_L
		SOMA_AD_H
		DEZ_MILHAR
		MILHAR
		CENTENA
		DEZENA
		UNIDADE
		DISPLAY
		B0
		B1
		TEMP0
		TEMP1
		RESULTADO_L
		RESULTADO_H
		W_TEMP
		STATUS_TEMP
		FLAGS
		UND_ATUAL
		CENT_ATUAL
		DEZ_ATUAL
		D1
		d2
		d3
		PCLATH_TEMP
		FSR_TEMP
		X32
		

	ENDC						;FIM DO BLOCO DE VARI?VEIS.

		

;================================================

ORG		0x04				;vetor de interrup??o.

	MOVWF 	W_TEMP				;COPIA W PARA W_TEMP
	SWAPF 	STATUS,W				
	MOVWF 	STATUS_TEMP			;COPIA STATUS PARA STATUS_TEMP
	MOVF	FSR,W
	MOVWF	FSR_TEMP
	MOVF	PCLATH,W
	MOVWF	PCLATH_TEMP

	BTFSS	INTCON,T0IF			;? INTERRUP??O DO TIMER 0?
	GOTO	SAI_INT				;N?O.
								;SIM.
	BTFSS	AD_OK				;ATUALIZAR VALORES?
	GOTO	PRE_MUX				;N?O.
								;SIM.
	BTFSS	DP					;TEMP. ACIMA DE 99.9 ????
	GOTO	ACIMA_DE999			;SIM.
	MOVF	UNIDADE,W			;N?O.
	MOVWF	UND_ATUAL
	MOVF	DEZENA,W
	MOVWF	DEZ_ATUAL
	MOVF	CENTENA,W
	MOVWF	CENT_ATUAL
	BCF		AD_OK				;LIMPA O FLAG.
	GOTO	PRE_MUX

ACIMA_DE999:
	MOVF	DEZENA,W
	MOVWF	UND_ATUAL
	MOVF	CENTENA,W
	MOVWF	DEZ_ATUAL
	MOVF	MILHAR,W
	MOVWF	CENT_ATUAL
	BCF		AD_OK

PRE_MUX:
	DECFSZ	DISPLAY,F
	GOTO	MULTIPLEXA
	MOVLW	.3
	MOVWF	DISPLAY

MULTIPLEXA:
	MOVF	DISPLAY,W
	ADDWF	PCL,F
	NOP
	GOTO	MOSTRA_UN
	GOTO	MOSTRA_DEZ
	GOTO	MOSTRA_CEN


MOSTRA_UN:
	BCF		DP_DRV		;DESLIGA O DP.
	NOP
	BSF		D_DEZ		;DESLIGA O DISPLAY DE DEZENAS.
	MOVF	UND_ATUAL,W
	CALL	TABELA
	MOVWF	PORTC
	NOP
	BCF		D_UN		;LIGA DISPLAY DAS UNIDADES.
	GOTO	FIM_MULTIPLEXA

MOSTRA_DEZ:
	BTFSC	DP
	BSF		DP_DRV
	NOP
	BSF		D_CEN			;DESLIGA DISPLAY DAS CENTENAS.
	MOVF	DEZ_ATUAL,W
	CALL	TABELA
	MOVWF	PORTC
	NOP
	BCF		D_DEZ		;LIGA DISPLAY DAS DEZENAS.
	GOTO	FIM_MULTIPLEXA

MOSTRA_CEN:
	BCF		DP_DRV
	NOP
	BSF		D_UN		;DESLIGA DISPLAY DAS UNIDADES.
	MOVF	CENT_ATUAL,W
	CALL	TABELA
	MOVWF	PORTC
	NOP
	BCF		D_CEN		;LIGA DISPLAY DA CENTENA.
	GOTO	FIM_MULTIPLEXA


FIM_MULTIPLEXA:
	CLRF	TMR0
	BCF		INTCON,T0IF		;LIMPA O FLAG INDICADOR DE INTER. DO TIMER0.
SAI_INT
	MOVF	PCLATH_TEMP,W
	MOVWF	PCLATH
	MOVF	FSR_TEMP,W
	MOVWF	FSR
	SWAPF   STATUS_TEMP,W
	MOVWF   STATUS			;MOVE STATUS_TEMP PARA STATUS
	SWAPF   W_TEMP,F
	SWAPF   W_TEMP,W		;MOVE W_TEMP PARA W

	
	RETFIE					;sai da interrup??o.

;==============================================================================

;=============================================

TABELA:
	ADDWF	PCL,F
	RETLW	        B'00000011'    ;0   TABELA PARA O CI 4511 - BCD;
	RETLW           B'00000111'    ;1   VALORES PARA O <PORTC5:2> DO PIC 16F676
	RETLW           B'00001011'    ;2   DISPLAYS DE CATODO COMUM.
	RETLW           B'00001111'    ;3
	RETLW           B'00010011'    ;4
	RETLW           B'00010111'    ;5
	RETLW           B'00011011'    ;6
	RETLW           B'00011111'    ;7
	RETLW           B'00100011'    ;8
	RETLW           B'00100111'    ;9

;=============================================

INICIO:

MOVLW	B'00000111'
MOVWF	CMCON		;DESLIGA O COMPARADOR.

CLRF	FLAGS
BSF		DP
MOVLW	.1
MOVWF	DISPLAY
CLRF	UND_ATUAL
CLRF	DEZ_ATUAL
CLRF	CENT_ATUAL

BANK1				
MOVLW	B'00000000'
MOVWF	TRISC		;TODO PORTC ? SA?DA.

MOVLW	B'11011011'	;CONFIGURA O PORTA
MOVWF	TRISA

MOVLW	B'10000001'	;PRESCALE /4 AO TIMER 0, TIMER INCREM. A CADA CICLO DE M?Q.
MOVWF	OPTION_REG
MOVLW	B'01010000'	;VELOCIDADE DE CONVERS?O FOSC/16.
MOVWF	ADCON1
MOVLW	B'00000011'	;RA0 ? ENTRADA ANAL?GICA E RA1 VREF.
MOVWF	ANSEL
BANK0
MOVLW	B'11100000'	;HABILITA INTER. DOS PERIF?RICOS E DO TIMER0. E LIGA GIE.
MOVWF	INTCON
MOVLW	B'11000001'	;RESULTADO DA CONVERS?O A/D ALINHADO ? 	
MOVWF	ADCON0		;ESQUERDA; M?DULO A/D LIGADO; VREF =>RA1.	

GOTO	CONVERTE_AD


;===============================
;ROTINA DE CONVERS?O A/D.

CONVERTE_AD:
	CLRF	RESULTADO_L
	CLRF	RESULTADO_H
	MOVLW	.32
	MOVWF	X32

CONV_AD_A:

; Delay = 0.03 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.03 seconds = 30000 cycles
; Error = 0 %



			;29998 cycles
	movlw	0x6F
	movwf	d1
	movlw	0x18
	movwf	d2
Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_0

			;2 cycles
	goto	$+1

	
	BSF		ADCON0,GO		;INICIA CONVERS?O.
	BTFSC	ADCON0,GO		;TERMINOU A CONVERS?O?
	GOTO	$-1				;N?O.
							;SIM.
DESL_INT:					;DESLIGA INTERRUP??ES PARA ACESSAR O BANK1.
	BCF		INTCON,GIE
	NOP
	BTFSC	INTCON,GIE
	GOTO	DESL_INT
	BANK1
	MOVF	ADRESL,W
	BANK0
	BSF		INTCON,GIE		;LIGA NOVAMENTE AS INTERRUP??ES.
	BCF		STATUS,C
	ADDWF	RESULTADO_L,F
	BTFSC	STATUS,C
	GOTO	SOM_32X_CAR
	MOVF	ADRESH,W
	ADDWF	RESULTADO_H,F
	GOTO	CONTA_32_CONV
SOM_32X_CAR:
	MOVF	ADRESH,W
	ADDWF	RESULTADO_H,F
	MOVLW	.1
	ADDWF	RESULTADO_H,F
CONTA_32_CONV:
	DECFSZ	X32,F
	GOTO	CONV_AD_A
	
DIVIDE_16:
	MOVLW	.4
	MOVWF	X32
DIVIDE_16A:
	RRF		RESULTADO_L,F
	BCF		STATUS,C
	RRF		RESULTADO_H,F
	BTFSC	STATUS,C
	GOTO	DIV16CAR
	BCF		RESULTADO_L,7
	GOTO	LOOP4X
DIV16CAR:
	BSF		RESULTADO_L,7
LOOP4X:
	DECFSZ	X32,F
	GOTO	DIVIDE_16A

;	MOVLW	B'01010000'		;TESTE: 80 EM BIN?RIO.
;	MOVWF	RESULTADO_L
;	CLRF	RESULTADO_H

AJUSTA_20:
	BCF		STATUS,C		;SOMA 20 DECIMAL AO RESULTADO, PARA COMPENSAR OS 2C A 
	MOVLW	.20				;0 mV DO LM35.
	ADDWF	RESULTADO_L,F
	BTFSS	STATUS,C
	GOTO	BIN16DEC
	MOVLW	.1
	ADDWF	RESULTADO_H,F	

	GOTO	BIN16DEC
	
;==============================================================

    
;ROTINA DE CONVERS?O DE BIN?RIO 16 BIT PARA DECIMAL.
;AUTOR: F?BIO PEREIRA.	

BIN16DEC:

	MOVF	RESULTADO_L,W		;VERIFICA SE PASSOU DE 99.9 ?C.
	MOVWF	TEMP0
	MOVF	RESULTADO_H,W
	MOVWF	TEMP1
	BCF		STATUS,C
	MOVLW	B'00011000'
	ADDWF	TEMP0,F
	BTFSC	STATUS,C
	GOTO	COM_CAR
	MOVLW	B'11111100'
	ADDWF	TEMP1,F
	BTFSC	STATUS,C
	GOTO	MAIS_DE99
	BSF		DP
	GOTO	CONTINUA_BIN16DEC	
MAIS_DE99
	BCF		DP
	GOTO	CONTINUA_BIN16DEC
COM_CAR:	
	BCF		STATUS,C
	MOVLW	B'11111101'
	ADDWF	TEMP1,F	
	BTFSC	STATUS,C
	GOTO	MAIS_DE99
	BSF		DP	

CONTINUA_BIN16DEC:
	CLRF	UNIDADE				;VARI?VEIS QUE ARMAZENAM O RESULTADO DA CONVERS?O.
	CLRF	DEZENA
	CLRF	CENTENA
	CLRF	MILHAR
	CLRF	DEZ_MILHAR 

BIN16DEC_1:
	MOVF	RESULTADO_L,W		;RESULTADO_L S?O OS 8 BIT LSB A SEREM CONVERTIDOS PARA
	MOVWF	TEMP0				;DECIMAL.
	MOVF	RESULTADO_H,W		;RESULTADO_H S?O OS 8 BIT MSB A SEREM CONVERTIDOS PARA
	MOVWF	TEMP1				;DECIMAL.
	MOVLW	0X10
	MOVWF	B0
	MOVLW	0X27
	MOVWF	B1
	CALL	SUB16B
	BTFSS	STATUS,C
	GOTO	BIN16DEC_2
	INCF	DEZ_MILHAR,F
	GOTO	BIN16DEC_1
BIN16DEC_2:
	MOVF	TEMP0,W
	MOVWF	RESULTADO_L
	MOVF	TEMP1,W
	MOVWF	RESULTADO_H
BIN16DEC_3:
	MOVF	RESULTADO_L,W
	MOVWF	TEMP0
	MOVF	RESULTADO_H,W
	MOVWF	TEMP1
	MOVLW	0XE8
	MOVWF	B0
	MOVLW	0X03
	MOVWF	B1
	CALL	SUB16B
	BTFSS	STATUS,C
	GOTO	BIN16DEC_4
	INCF	MILHAR,F
	GOTO	BIN16DEC_3
BIN16DEC_4:
	MOVF	TEMP0,W
	MOVWF	RESULTADO_L
	MOVF	TEMP1,W
	MOVWF	RESULTADO_H
BIN16DEC_5:
	MOVF	RESULTADO_L,W
	MOVWF	TEMP0
	MOVF	RESULTADO_H,W
	MOVWF	TEMP1
	MOVLW	.100
	MOVWF	B0
	CLRF	B1
	CALL	SUB16B
	BTFSS	STATUS,C
	GOTO	BIN16DEC_6
	INCF	CENTENA,F
	GOTO	BIN16DEC_5
BIN16DEC_6:
	MOVF	TEMP0,W
	MOVWF	RESULTADO_L
	MOVF	TEMP1,W
	MOVWF	RESULTADO_H
BIN16DEC_7:
	MOVF	RESULTADO_L,W
	MOVWF	TEMP0
	MOVF	RESULTADO_H,W
	MOVWF	TEMP1
	MOVLW	.10
	MOVWF	B0
	CLRF	B1
	CALL	SUB16B
	BTFSS	STATUS,C
	GOTO	BIN16DEC_8
	INCF	DEZENA,F
	GOTO	BIN16DEC_7
BIN16DEC_8:
	MOVF	TEMP0,W
	MOVWF	UNIDADE
	
	BSF		AD_OK
	GOTO	CONVERTE_AD		;FIM DA CONVERS?O PARA DECIMAL.

SUB16B:
	MOVF	B0,W
	SUBWF	RESULTADO_L,F
	MOVLW	0X01
	BTFSS	STATUS,C
	SUBWF	RESULTADO_H,F
	BTFSS	STATUS,C
	GOTO	EMPRESTA
	MOVF	B1,W
	SUBWF	RESULTADO_H,F
FIM_SUB16B:
	MOVF	RESULTADO_L,F
	BTFSC	STATUS,Z
	MOVF	RESULTADO_H,F
	RETURN
EMPRESTA:
	MOVF	B1,W
	SUBWF	RESULTADO_H,F
	BCF	STATUS,C
	GOTO	FIM_SUB16B				
	
							


					END			;AT? QUE EMFIM.
