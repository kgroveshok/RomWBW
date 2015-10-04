;
;==================================================================================================
; UTILITY FUNCTIONS
;==================================================================================================
;
;
CHR_CR		.EQU	0DH
CHR_LF		.EQU	0AH
CHR_BS		.EQU	08H
CHR_ESC		.EQU	1BH
;
;__________________________________________________________________________________________________
;
; UTILITY PROCS TO PRINT SINGLE CHARACTERS WITHOUT TRASHING ANY REGISTERS
;
PC_SPACE:
	PUSH	AF
	LD	A,' '
	JR	PC_PRTCHR

PC_PERIOD:
	PUSH	AF
	LD	A,'.'
	JR	PC_PRTCHR

PC_COLON:
	PUSH	AF
	LD	A,':'
	JR	PC_PRTCHR

PC_COMMA:
	PUSH	AF
	LD	A,','
	JR	PC_PRTCHR

PC_LBKT:
	PUSH	AF
	LD	A,'['
	JR	PC_PRTCHR

PC_RBKT:
	PUSH	AF
	LD	A,']'
	JR	PC_PRTCHR

PC_LT:
	PUSH	AF
	LD	A,'<'
	JR	PC_PRTCHR

PC_GT:
	PUSH	AF
	LD	A,'>'
	JR	PC_PRTCHR

PC_LPAREN:
	PUSH	AF
	LD	A,'('
	JR	PC_PRTCHR

PC_RPAREN:
	PUSH	AF
	LD	A,')'
	JR	PC_PRTCHR

PC_ASTERISK:
	PUSH	AF
	LD	A,'*'
	JR	PC_PRTCHR

PC_CR:
	PUSH	AF
	LD	A,CHR_CR
	JR	PC_PRTCHR

PC_LF:
	PUSH	AF
	LD	A,CHR_LF
	JR	PC_PRTCHR

PC_PRTCHR:
	CALL	COUT
	POP	AF
	RET

NEWLINE:
	CALL	PC_CR
	CALL	PC_LF
	RET
;
; PRINT A CHARACTER REFERENCED BY POINTER AT TOP OF STACK
; USAGE:
;   CALL PRTCH
;   .DB  'X'
;
PRTCH:
	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)
	CALL	COUT
	POP	AF
	INC	HL
	EX	(SP),HL
	RET
;
; PRINT A STRING AT ADDRESS SPECIFIED IN HL
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   LD	HL,MYSTR
;   CALL PRTSTR
;   ...
;   MYSTR: .DB  "HELLO$"
;
PRTSTR:
	LD	A,(HL)
	INC	HL
	CP	'$'
	RET	Z
	CALL	COUT
	JR	PRTSTR
;
; PRINT A STRING DIRECT: REFERENCED BY POINTER AT TOP OF STACK
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   CALL PRTSTR
;   .DB  "HELLO$"
;   ...
;
PRTSTRD:
	EX	(SP),HL
	PUSH	AF
	CALL	PRTSTR
	POP	AF
	EX	(SP),HL
	RET
;
; PRINT A STRING INDIRECT: REFERENCED BY INDIRECT POINTER AT TOP OF STACK
; STRING MUST BE TERMINATED BY '$'
; USAGE:
;   CALL PRTSTRI(MYSTRING)
;   MYSTRING	.DB	"HELLO$"
;
PRTSTRI:
	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)
	INC	HL
	PUSH	HL
	LD	H,(HL)
	LD	L,A
	CALL	PRTSTR
	POP	HL
	INC	HL
	POP	AF
	EX	(SP),HL
	RET
;
; PRINT THE HEX BYTE VALUE IN A
;
PRTHEXBYTE:
	PUSH	AF
	PUSH	DE
	CALL	HEXASCII
	LD	A,D
	CALL	COUT
	LD	A,E
	CALL	COUT
	POP	DE
	POP	AF
	RET
;
; PRINT THE HEX WORD VALUE IN BC
;
PRTHEXWORD:
	PUSH	AF
	LD	A,B
	CALL	PRTHEXBYTE
	LD	A,C
	CALL	PRTHEXBYTE
	POP	AF
	RET
;
; PRINT THE HEX DWORD VALUE IN DE:HL
;
PRTHEX32:
	PUSH	BC
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	RET
;
; CONVERT BINARY VALUE IN A TO ASCII HEX CHARACTERS IN DE
;
HEXASCII:
	LD	D,A
	CALL	HEXCONV
	LD	E,A
	LD	A,D
	RLCA
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV
	LD	D,A
	RET
;
; CONVERT LOW NIBBLE OF A TO ASCII HEX
;
HEXCONV:
	AND	0FH	     ;LOW NIBBLE ONLY
	ADD	A,90H
	DAA	
	ADC	A,40H
	DAA	
	RET	
;
; PRINT A BYTE BUFFER IN HEX POINTED TO BY DE
; REGISTER A HAS SIZE OF BUFFER
;
PRTHEXBUF:
	OR	A
	RET	Z		; EMPTY BUFFER
;
	LD	B,A
PRTHEXBUF1:
	CALL	PC_SPACE
	LD	A,(DE)
	CALL	PRTHEXBYTE
	INC	DE
	DJNZ	PRTHEXBUF1
	RET
;
; PRINT A BLOCK OF MEMORY NICELY FORMATTED
;  DE=BUFFER ADDRESS
;
DUMP_BUFFER:
	CALL	NEWLINE

	PUSH	DE
	POP	HL
	INC	D
	INC	D
	
DB_BLKRD:
	PUSH	BC
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD		; PRINT START LOCATION
	POP	BC
	CALL	PC_SPACE		;
	LD	C,16			; SET FOR 16 LOCS
	PUSH	HL			; SAVE STARTING HL
DB_NXTONE:
	LD 	A,(HL)			; GET BYTE
	CALL	PRTHEXBYTE		; PRINT IT
	CALL	PC_SPACE		;
DB_UPDH:	
	INC	HL			; POINT NEXT
	DEC	C			; DEC. LOC COUNT
	JR	NZ,DB_NXTONE		; IF LINE NOT DONE
					; NOW PRINT 'DECODED' DATA TO RIGHT OF DUMP
DB_PCRLF:
	CALL	PC_SPACE		; SPACE IT
	LD	C,16			; SET FOR 16 CHARS
	POP	HL			; GET BACK START
DB_PCRLF0:
	LD	A,(HL)			; GET BYTE
	AND	060H			; SEE IF A 'DOT'
	LD	A,(HL)			; O.K. TO GET
	JR	NZ,DB_PDOT			;
DB_DOT:
	LD	A,2EH			; LOAD A DOT	
DB_PDOT:
	CALL	COUT			; PRINT IT
	INC	HL			; 
	LD	A,D			;
	CP	H			;
	JR	NZ,DB_UPDH1		;
	LD	A,E			;
	CP	L			;
	JP	Z,DB_END		;
;
;IF BLOCK NOT DUMPED, DO NEXT CHARACTER OR LINE
DB_UPDH1:
	DEC	C			; DEC. CHAR COUNT
	JR	NZ,DB_PCRLF0		; DO NEXT
DB_CONTD:
	CALL	NEWLINE			;
	JP	DB_BLKRD			;

DB_END:	
	RET				;
;
; OUTPUT A '$' TERMINATED STRING
;
WRITESTR:
	PUSH	AF
WRITESTR1:
	LD	A,(DE)
	CP	'$'			; TEST FOR STRING TERMINATOR
	JP	Z,WRITESTR2
	CALL	COUT
	INC	DE
	JP	WRITESTR1
WRITESTR2:
	POP	AF
	RET
;
; PANIC: TRY TO DUMP MACHINE STATE AND HALT
;
PANIC:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	DE,STR_PANIC
	CALL	WRITESTR
	LD	DE,STR_AF
	CALL	WRITESTR
	POP	BC		; AF
	CALL	PRTHEXWORD
	LD	DE,STR_BC
	CALL	WRITESTR
	POP	BC		; BC
	CALL	PRTHEXWORD
	LD	DE,STR_DE
	CALL	WRITESTR
	POP	BC		; DE
	CALL	PRTHEXWORD
	LD	DE,STR_HL
	CALL	WRITESTR
	POP	BC		; HL
	CALL	PRTHEXWORD
	LD	DE,STR_PC
	CALL	WRITESTR
	POP	BC		; PC
	CALL	PRTHEXWORD
	LD	DE,STR_SP
	CALL	WRITESTR
	LD	HL,0
	ADD	HL,SP		; SP
	LD	B,H
	LD	C,L
	CALL	PRTHEXWORD
	
	RST	38
	
	HALT
	
	JP	0
;
;==================================================================================================
; CONSOLE CHARACTER I/O HELPER ROUTINES (REGISTERS PRESERVED)
;==================================================================================================
;
; OUTPUT CHARACTER FROM A
COUT:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
#IF (PLATFORM == PLT_UNA)
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	E,A
	LD	BC,$12
	RST	08
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	E,A
	LD	BC,$12
	RST	08
#ENDIF
#ELSE
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	E,A
	LD	A,(HCB + HCB_CONDEV)
	LD	C,A
	LD	B,BF_CIOOUT
	CALL	HB_DISPATCH
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	E,A
	LD	C,CIODEV_CONSOLE
	LD	B,BF_CIOOUT
	RST	08
#ENDIF
#ENDIF
#IFDEF CIOMODE_CBIOS
  #DEFINE CIOMODE_NONDOS
	LD	C,A
	CALL	CBIOS_CONOUT
#ENDIF
#IFNDEF CIOMODE_NONDOS
	LD	E,A
	LD	C,03H
	CALL	0005H
#ENDIF
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
; INPUT CHARACTER TO A
;
CIN:
	PUSH	BC
	PUSH	DE
	PUSH	HL
#IF (PLATFORM == PLT_UNA)
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	BC,$11
	RST	08
	LD	A,E
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	BC,$11
	RST	08
	LD	A,E
#ENDIF
#ELSE
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	A,(HCB + HCB_CONDEV)
	LD	C,A
	LD	B,BF_CIOIN
	CALL	HB_DISPATCH
	LD	A,E
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	C,CIODEV_CONSOLE
	LD	B,BF_CIOIN
	RST	08
	LD	A,E
#ENDIF
#ENDIF
#IFDEF CIOMODE_CBIOS
  #DEFINE CIOMODE_NONDOS
	CALL	CBIOS_CONIN
#ENDIF
#IFNDEF CIOMODE_NONDOS
	LD	C,01H
	CALL	0005H
#ENDIF
	POP	HL
	POP	DE
	POP	BC
	RET
;
; RETURN INPUT STATUS IN A (0 = NO CHAR, !=0 CHAR WAITING)
;
CST:
	PUSH	BC
	PUSH	DE
	PUSH	HL
#IF (PLATFORM == PLT_UNA)
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	BC,$13
	RST	08
	LD	A,E
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	BC,$13
	RST	08
	LD	A,E
#ENDIF
#ELSE
#IFDEF CIOMODE_CONSOLE
  #DEFINE CIOMODE_NONDOS
	LD	B,BF_CIOIST
	LD	A,(HCB + HCB_CONDEV)
	LD	C,A
	CALL	HB_DISPATCH
#ENDIF
#IFDEF CIOMODE_HBIOS
  #DEFINE CIOMODE_NONDOS
	LD	B,BF_CIOIST
	LD	C,CIODEV_CONSOLE
	RST	08
#ENDIF
#ENDIF
#IFDEF CIOMODE_CBIOS
  #DEFINE CIOMODE_NONDOS
	CALL	CBIOS_CONST
#ENDIF
#IFNDEF CIOMODE_NONDOS
	LD	C,0BH
	CALL	0005H
#ENDIF
	POP	HL
	POP	DE
	POP	BC
	RET
;
STR_PANIC	.DB	"\r\n\r\n>>> FATAL ERROR:$"
STR_AF		.DB	" AF=$"
STR_BC		.DB	" BC=$"
STR_DE		.DB	" DE=$"
STR_HL		.DB	" HL=$"
STR_PC		.DB	" PC=$"
STR_SP		.DB	" SP=$"
;
; INDIRECT JUMP TO ADDRESS IN HL
;
;   MOSTLY USEFUL TO PERFORM AN INDIRECT CALL LIKE:
;     LD	HL,xxxx
;     CALL	JPHL
;
JPHL:	JP	(HL)
;
; ADD HL,A
;
;   A REGISTER IS DESTROYED!
;

ADDHLA:
	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET
;
;****************************
;	A(BCD) => A(BIN) 
;	[00H..99H] -> [0..99]
;****************************
;
BCD2BYTE:
	PUSH	BC
	LD	C,A
	AND	0F0H
	SRL	A
	LD	B,A
	SRL	A
	SRL	A
	ADD	A,B
	LD	B,A
	LD	A,C
	AND	0FH
	ADD	A,B
	POP	BC
	RET
;
;*****************************
;	 A(BIN) =>  A(BCD) 
;	[0..99] => [00H..99H]
;*****************************
;
BYTE2BCD:
	PUSH	BC
	LD	B,10
	LD	C,-1
BYTE2BCD1:
	INC	C
	SUB	B
	JR	NC,BYTE2BCD1
	ADD	A,B
	LD	B,A
	LD	A,C
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	OR	B
	POP	BC
	RET

;#IFDEF PLTWBW
#IFDEF USEDELAY

;
; DELAY 16US (CPU SPEED COMPENSATED) INCUDING CALL/RET INVOCATION
; REGISTER A AND FLAGS DESTROYED
; NO COMPENSATION FOR Z180 MEMORY WAIT STATES
; THERE IS AN OVERHEAD OF 3TS PER INVOCATION
;   IMPACT OF OVERHEAD DIMINISHES AS CPU SPEED INCREASES
;
; CPU SCALER (CPUSCL) = (CPUHMZ - 2) FOR 16US + 3TS DELAY
;   NOTE: CPUSCL MUST BE >= 3!
;
; EXAMPLE: 8MHZ CPU (DELAY GOAL IS 16US)
;   LOOP = ((6 * 16) - 5) = 91TS
;   TOTAL COST = (91 + 40) = 131TS
;   ACTUAL DELAY = (131 / 8) = 16.375US
;
	; --- TOTAL COST = (LOOP COST + 40) TS -----------------+
DELAY:				; 17TS (FROM INVOKING CALL)	|
	LD	A,(CPUSCL)	; 13TS				|
;								|
DELAY1:			;				|
	; --- LOOP = ((CPUSCL * 16) - 5) TS ------------+	|
	DEC	A		; 4TS			|	|
#IFDEF CPU_Z180			;			|	|
	OR	A		; +4TS FOR Z180		|	|
#ENDIF				;			|	|
	JR	NZ,DELAY1	; 12TS (NZ) / 7TS (Z)	|	|
	; ----------------------------------------------+	|
;								|
	RET			; 10TS (RETURN)			|
	;-------------------------------------------------------+
;
; DELAY 16US * DE (CPU SPEED COMPENSATED)
; REGISTER DE, A, AND FLAGS DESTROYED
; NO COMPENSATION FOR Z180 MEMORY WAIT STATES
; THERE IS A 27TS OVERHEAD FOR CALL/RET PER INVOCATION
;   IMPACT OF OVERHEAD DIMINISHES AS DE AND/OR CPU SPEED INCREASES
;
; CPU SCALER (CPUSCL) = (CPUHMZ - 2) FOR 16US OUTER LOOP COST
;   NOTE: CPUSCL MUST BE >= 3!
;
; EXAMPLE: 8MHZ CPU, DE=6250 (DELAY GOAL IS .1 SEC OR 100,000US)
;   INNER LOOP = ((16 * 6) - 5) = 91TS
;   OUTER LOOP = ((91 + 37) * 6250) = 800,000TS
;   ACTUAL DELAY = ((800,000 + 27) / 8) = 100,003US
;
	; --- TOTAL COST = (OUTER LOOP + 27) TS ------------------------+
VDELAY:				; 17TS (FROM INVOKING CALL)		|
;									|
	; --- OUTER LOOP = ((INNER LOOP + 37) * DE) TS ---------+	|
	LD	A,(CPUSCL)	; 13TS				|	|
;								|	|
VDELAY1:			;				|	|
	; --- INNER LOOP = ((CPUSCL * 16) - 5) TS ------+	|	|
#IFDEF CPU_Z180			;			|	|	|
	OR	A		; +4TS FOR Z180		|	|	|
#ENDIF				;			|	|	|
	DEC	A		; 4TS			|	|	|
	JR	NZ,VDELAY1	; 12TS (NZ) / 7TS (Z)	|	|	|
	; ----------------------------------------------+	|	|
;								|	|
	DEC	DE		; 6TS				|	|
#IFDEF CPU_Z180			;				|	|
	OR	A		; +4TS FOR Z180			|	|
#ENDIF				;				|	|
	LD	A,D		; 4TS				|	|
	OR	E		; 4TS				|	|
	JP	NZ,VDELAY	; 10TS				|	|
	;-------------------------------------------------------+	|
;									|
	RET			; 10TS (FINAL RETURN)			|
	;---------------------------------------------------------------+
;
; DELAY ABOUT 0.5 SECONDS
; 500000US / 16US = 31250
;
LDELAY:
	PUSH	AF
	PUSH	DE
	LD	DE,31250
	CALL	VDELAY
	POP	DE
	POP	AF
	RET
;
; INITIALIZE DELAY SCALER BASED ON OPERATING CPU SPEED
; HBIOS *MUST* BE INSTALLED AND AVAILABLE VIA RST 8!!!
; CPU SCALER := MAX(1, (PHIMHZ - 2))
;
DELAY_INIT:
	LD	B,BF_SYSHCBGETB	; HB FUNC: GET HCB BYTE
	LD	C,HCB_CPUMHZ	; CPU SPEED IN MHZ
	RST	08		; DO IT
	LD	A,E		; VALUE TO ACCUM
	SUB	2		; ADJUST AS REQUIRED BY DELAY FUNCTIONS
	LD	(CPUSCL),A	; UPDATE CPU SCALER VALUE
	CP	1		; CHECK FOR MINIMUM VALUE ALLOWED
	RET	NC		; IF >= 1, WE ARE ALL DONE, RETURN
	LD	A,1		; OTHERWISE, SET MIN VALUE
	LD	(CPUSCL),A	; AND SAVE IT
	RET
;
#IF (CPUMHZ < 3)
CPUSCL	.DB	1		; CPU SCALER MUST BE > 0
#ELSE
CPUSCL	.DB	CPUMHZ - 2	; OTHERWISE 2 LESS THAN PHI MHZ
#ENDIF
;
#ENDIF
;#ENDIF
;
; SHORT DELAY FUNCTIONS.  NO CLOCK SPEED COMPENSATION, SO THEY
; WILL RUN LONGER ON SLOWER SYSTEMS.  THE NUMBER INDICATES THE
; NUMBER OF CALL/RET INVOCATIONS.  A SINGLE CALL/RET IS
; 27 T-STATES ON A Z80, 25 T-STATES ON A Z180
;
DLY64:	CALL	DLY32
DLY32:	CALL	DLY16
DLY16:	CALL	DLY8
DLY8:	CALL	DLY4
DLY4:	CALL	DLY2
DLY2:	CALL	DLY1
DLY1:	RET

;
; MULTIPLY 8-BIT VALUES
; IN:  MULTIPLY H BY E
; OUT: HL = RESULT, E = 0, B = 0
;
MULT8:
	LD D,0
	LD L,D
	LD B,8
MULT8_LOOP:
	ADD HL,HL
	JR NC,MULT8_NOADD
	ADD HL,DE
MULT8_NOADD:
	DJNZ MULT8_LOOP
	RET
;;
;; COMPUTE HL / DE
;; RESULT IN BC, REMAINDER IN HL, AND SET ZF DEPENDING ON REMAINDER
;; A, DE DESTROYED
;;
;DIV:
;	XOR	A
;	LD	BC,0
;DIV1:
;	SBC	HL,DE
;	JR	C,DIV2
;	INC	BC
;	JR	DIV1
;DIV2:
;	XOR	A
;	ADC	HL,DE		; USE ADC SO ZF IS SET
;	RET
;===============================================================
;
; COMPUTE HL / DE = BC W/ REMAINDER IN HL
;
DIV16:
	; HL -> AC
	LD	A,H
	LD	C,L

	; SETUP
	LD	HL,0
	LD	B,16
;
DIV16A:
	; LOOP
;	.DB	$CB,$31		; SLL	C
	SLA	C
	SET	0,C
	RLA
	ADC	HL,HL
	SBC	HL,DE
	JR	NC,DIV16B
	ADD	HL,DE
	DEC	C
DIV16B:
	DJNZ	DIV16A

	; AC -> BC
	LD	B,A

	RET
;
; FILL MEMORY AT HL WITH VALUE A, LENGTH IN BC, ALL REGS USED
; LENGTH *MUST* BE GREATER THAN 1 FOR PROPER OPERATION!!!
;
FILL:
	LD	D,H		; SET DE TO HL
	LD	E,L		; SO DESTINATION EQUALS SOURCE
	LD	(HL),A		; FILL THE FIRST BYTE WITH DESIRED VALUE
	INC	DE		; INCREMENT DESTINATION
	DEC	BC		; DECREMENT THE COUNT
	LDIR			; DO THE REST
	RET			; RETURN
;
; SET A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITSET:
	CALL	BITLOC		; LOCATE THE BIT
	OR	(HL)		; SET THE SPECIFIED BIT
	LD	(HL),A		; SAVE IT
	RET			; RETURN
;
; CLEAR A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITCLR:
	CALL	BITLOC		; LOCATE THE BIT
	CPL			; INVERT ALL BITS
	AND	(HL)		; CLEAR SPECIFIED BIT
	LD	(HL),A		; SAVE IT
	RET			; RETURN
;
; GET VALUE OF A BIT IN BYTE ARRAY AT HL, INDEX IN A
;
BITTST:
	CALL	BITLOC		; LOCATE THE BIT
	AND	(HL)		; SET Z FLAG BASED ON BIT
	RET			; RETURN
;
; LOCATE A BIT IN BYTE ARRAY AT HL, INDEX IN A
; RETURN WITH HL POINTING TO BYTE AND A WITH MASK FOR SPECIFIC BIT
;
BITLOC:
	PUSH	AF		; SAVE BIT INDEX
	SRL	A		; DIVIDE BY 8 TO GET BYTE INDEX
	SRL	A		; "
	SRL	A		; "
	LD	C,A		; MOVE TO BC
	LD	B,0		; "
	ADD	HL,BC		; HL NOW POINTS TO BYTE CONTAINING BIT
	POP	AF		; RECOVER A (INDEX)
	AND	$07		; ISOLATE REMAINDER, Z SET IF ZERO
	LD	B,A		; SETUP SHIFT COUNTER
	LD	A,1		; SETUP A WITH MASK
	RET	Z		; DONE IF ZERO
BITLOC1:
	SLA	A		; SHIFT
	DJNZ	BITLOC1		; LOOP AS NEEDED
	RET			; DONE
;
; PRINT VALUE OF A IN DECIMAL WITH LEADING ZERO SUPPRESSION
;
PRTDECB:
	PUSH	HL
	PUSH	AF
	LD	L,A
	LD	H,0
	CALL	PRTDEC
	POP	AF
	POP	HL
	RET
;
; PRINT VALUE OF HL IN DECIMAL WITH LEADING ZERO SUPPRESSION
;
PRTDEC:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	E,'0'
	LD	BC,-10000
	CALL	PRTDEC1
	LD	BC,-1000
	CALL	PRTDEC1
	LD	BC,-100
	CALL	PRTDEC1
	LD	C,-10
	CALL	PRTDEC1
	LD	E,0
	LD	C,-1
	CALL	PRTDEC1
	POP	HL
	POP	DE
	POP	BC
	RET
PRTDEC1:
	LD	A,'0' - 1
PRTDEC2:
	INC	A
	ADD	HL,BC
	JR	C,PRTDEC2
	SBC	HL,BC
	CP	E
	JR	Z,PRTDEC3
	LD	E,0
	CALL	COUT
PRTDEC3:
	RET
;
; SHIFT HL:DE BY B BITS
;
SRL32:
	; ROTATE RIGHT 32 BITS, HIGH ORDER BITS BECOME ZERO
	SRL	D
	RR	E
	RR	H
	RR	L
	DJNZ	SRL32
	RET
;
SLA32:
	; ROTATE LEFT 32 BITS, LOW ORDER BITS BECOME ZERO
	SLA	L
	RL	H
	RL	E
	RL	D
	DJNZ	SLA32
	RET
;
; LOAD OR STORE DE:HL
;
LD32:
	; LD DE:HL,(HL)
	PUSH	AF
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	POP	AF
	EX	DE,HL
	RET
;
ST32:
	; LD (BC),DE:HL
	PUSH	AF
	LD	A,L
	LD	(BC),A
	INC	BC
	LD	A,H
	LD	(BC),A
	INC	BC
	LD	A,E
	LD	(BC),A
	INC	BC
	LD	A,D
	LD	(BC),A
	POP	AF
	RET
;
;==================================================================================================
; DSKY KEYBOARD ROUTINES
;==================================================================================================
;
#IF (DSKYENABLE)

PPIA		.EQU 	PPIBASE + 0	; PORT A
PPIB		.EQU 	PPIBASE + 1	; PORT B
PPIC		.EQU 	PPIBASE + 2	; PORT C
PPIX	 	.EQU 	PPIBASE + 3	; PPI CONTROL PORT

;
;    _____C0______C1______C2______C3__
;B5 |	$20 D	$60 E	$A0 F	$E0 BO
;B4 |	$10 A	$50 B	$90 C	$D0 GO
;B3 |	$08 7	$48 8	$88 9	$C8 EX
;B2 |	$04 4	$44 5	$84 6	$C4 DE
;B1 |	$02 1	$42 2	$82 3	$C2 EN
;B0 |	$01 FW	$41 0	$81 BK	$C1 CL
;
KY_0	.EQU	000H
KY_1	.EQU	001H
KY_2	.EQU	002H
KY_3	.EQU	003H
KY_4	.EQU	004H
KY_5	.EQU	005H
KY_6	.EQU	006H
KY_7	.EQU	007H
KY_8	.EQU	008H
KY_9	.EQU	009H
KY_A	.EQU	00AH
KY_B	.EQU	00BH
KY_C	.EQU	00CH
KY_D	.EQU	00DH
KY_E	.EQU	00EH
KY_F	.EQU	00FH
KY_FW	.EQU	010H	; FORWARD
KY_BK	.EQU	011H	; BACKWARD
KY_CL	.EQU	012H	; CLEAR
KY_EN	.EQU	013H	; ENTER
KY_DE	.EQU	014H	; DEPOSIT
KY_EX	.EQU	015H	; EXAMINE
KY_GO	.EQU	016H	; GO
KY_BO	.EQU	017H	; BOOT
;
;__DSKY_INIT_________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
DSKY_INIT:
	LD	A,82H
	OUT 	(PPIX),A
	LD	A,30H			;disable /CS on PPISD card(s)
	OUT	(PPIC),A
	XOR	A
	LD	(KY_BUF),A
	RET
#IFDEF DSKY_KBD
;
;__KY_STAT___________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
KY_STAT:
	; IF WE ALREADY HAVE A KEY, RETURN WITH NZ
	LD	A,(KY_BUF)
	OR	A
	RET	NZ
	; SCAN FOR A KEYPRESS, A=0 NO DATA OR A=RAW BYTE
	CALL	KY_SCAN			; SCAN KB ONCE
	OR	A			; SET FLAGS
	RET	Z			; NOTHING FOUND, GET OUT
	LD	(KY_BUF),A		; SAVE RAW KEYCODE
	RET				; RETURN
;
;__KY_GET____________________________________________________________________________________________
;
;  GET A SINGLE KEY (WAIT FOR ONE IF NECESSARY)
;____________________________________________________________________________________________________
;
KY_GET:
	; SEE IF WE ALREADY HAVE A KEY SAVED, GO TO DECODE IF SO
	LD	A,(KY_BUF)
	OR	A
	JR	NZ,KY_DECODE
	; NO KEY SAVED, WAIT FOR ONE
KY_STATLOOP:
	CALL	KY_STAT
	OR	A
	JR	Z,KY_STATLOOP
	; DECODE THE RAW VALUE
KY_DECODE:
	LD	D,00H
	LD	HL,KY_KEYMAP		; POINT TO BEGINNING OF TABLE	
KY_GET_LOOP:
	CP	(HL)			; MATCH?
	JR	Z,KY_GET_DONE		; FOUND, DONE
	INC	HL
	INC	D			; D + 1
	JR	NZ,KY_GET_LOOP		; NOT FOUND, LOOP UNTIL EOT			
KY_GET_DONE:
	; CLEAR OUT KEY_BUF
	XOR	A
	LD	(KY_BUF),A
	; RETURN THE INDEX POSITION WHERE THE RAW VALUE WAS FOUND
	LD	A,D
	RET
;	
;__KY_SCAN____________________________________________________________________________________________
;
;  SCAN KEYBOARD MATRIX FOR AN INPUT
;____________________________________________________________________________________________________
;
KY_SCAN:
	LD	C,0000H
	LD	A,41H | 30H		;  SCAN COL ONE
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT 

	LD	C,0040H
	LD	A,42H | 30H		;  SCAN COL TWO
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT 

	LD	C,0080H
	LD	A,44H | 30H		;  SCAN COL THREE
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2		;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT 

	LD	C,00C0H			;
	LD	A,48H | 30H		;  SCAN COL FOUR
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT 

	LD	A,040H | 30H		;  TURN OFF ALL COLUMNS
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	LD	A,00H			;  RETURN NULL
	RET				;  EXIT

KY_SCAN_FOUND:
	AND	3FH			;  CLEAR TOP TWO BITS
	OR	C			;  ADD IN ROW BITS 
	LD	C,A			;  STORE VALUE

	; WAIT FOR KEY TO BE RELEASED
	LD	A,4FH | 30H		; SCAN ALL COL LINES
	OUT	(PPIC),A		; SEND TO COLUMN LINES
	CALL	DLY2			; DEBOUNCE
KY_CLEAR_LOOP:				; WAIT FOR KEY TO CLEAR
	IN	A,(PPIB)		; GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			; ANYTHING PRESSED?
	JR	NZ,KY_CLEAR_LOOP	; YES, LOOP UNTIL KEY RELEASED

	LD	A,040H | 30H		;  TURN OFF ALL COLUMNS
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES

	LD	A,C			;  RESTORE VALUE
	RET
;
;_KEYMAP_TABLE_____________________________________________________________________________________________________________
; 
KY_KEYMAP:
;               0    1    2    3    4    5    6    7
	.DB	041H,002H,042H,082H,004H,044H,084H,008H
;               8    9    A    B    C    D    E    F
	.DB	048H,088H,010H,050H,090H,020H,060H,0A0H
;               FW   BK   CL   EN   DE   EX   GO   BO
	.DB	001H,081H,0C1H,0C2H,0C4H,0C8H,0D0H,0E0H
;
#ENDIF	; DSKY_KBD
;
;==================================================================================================
; DSKY HEX DISPLAY
;==================================================================================================
;
DSKY_HEXOUT:
	LD	B,DSKY_HEXBUFLEN
	LD	HL,DSKY_BUF
	LD	DE,DSKY_HEXBUF
DSKY_HEXOUT1:
	LD	A,(DE)		; FIRST NIBBLE
	SRL	A
	SRL	A
	SRL	A
	SRL	A
	LD	(HL),A
	INC	HL
	LD	A,(DE)		; SECOND NIBBLE
	AND	0FH
	LD	(HL),A
	INC	HL
	INC	DE		; NEXT BYTE
	DJNZ	DSKY_HEXOUT1

	LD	A,82H			; SETUP PPI
	OUT	(PPIX),A
	CALL	DSKY_COFF
	LD	A,0D0H			; 7218 -> (DATA COMING, HEXA DECODE)
	OUT	(PPIA),A
	CALL	DSKY_STROBEC

	LD	HL,DSKY_BUF		; POINT TO START OF BUF
	LD	B,DSKY_BUFLEN		; NUMBER OF DIGITS
	LD	C,PPIA
DSKY_HEXOUT2:
	OUTI
	JP	Z,DSKY_STROBE		; DO FINAL STROBE AND RETURN
	CALL	DSKY_STROBE
	JR	DSKY_HEXOUT2
	
DSKY_STROBEC:
	LD	A,80H | 30H
	JP	DSKY_STROBE0

DSKY_STROBE:
	LD	A,00H | 30H		; SET WRITE STROBE

DSKY_STROBE0:
	OUT	(PPIC),A		; OUT TO PORTC
	CALL	DLY2			; DELAY
DSKY_COFF
	LD	A,40H | 30H		; SET CONTROL PORT OFF
	OUT	(PPIC),A		; OUT TO PORTC
;	CALL	DSKY_DELAY		; WAIT
	RET
;
;
;
KY_BUF		.DB	0
DSKY_BUF:	.FILL	8,0
DSKY_BUFLEN	.EQU	$ - DSKY_BUF
DSKY_HEXBUF	.FILL	4,0
DSKY_HEXBUFLEN	.EQU	$ - DSKY_HEXBUF
;
;
#ENDIF
