;-------------------------------------------------------
;
;       Sega startup code for the Sozobon C compiler
;       Written by Paul W. Lee
;       Modified from Charles Coty's code
;
;-------------------------------------------------------
        .globl _OUTCH
        .globl _INCH
        .globl _KBHIT
        .globl _EXEC
        .globl _NEXT
        .globl _BEXEC

;prgbase .equ   $000000
prgbase .equ   $ff4000     ; Hi.Addr
mstack  .equ   $ffc000		; monitor stack
sstack	.equ   $fe0000
sysport .equ   $ff0f00
acias   .equ   $ff1000      ;$c000
aciad   .equ   $ff1002      ;$c002
wkbase  .equ   $ff2000

svtop   .equ   wkbase+0
svport	.equ   wkbase+0
svsr    .equ   svtop+2
svpc    .equ   svtop+4
svusp   .equ   svtop+8
svd0    .equ   svtop+12         ; D0-D7/A0-A6/
sva7    .equ   svd0+15*4        ; A7
svssp   .equ   sva7+4           ; ssp work
svw0	.equ   sva7+8
svw7	.equ   svw0+15*4		; D0-D7/A0-A6/
svmr0	.equ   svw7+4			; regsave(for mon)

    org    prgbase+$0

	dc.l mstack,coldent
	dc.l INT,INT,INT,INT,INT,INT,INT     ;
	dc.l INT,INT,INT,INT,INT,INT,INT,INT ; $24
	dc.l INT,INT,INT,INT,INT,INT,INT,INT ; $44
	dc.l INT,INT,INT,HBL,INT,VBL,NMI,INT ; $64
	dc.l INT,INT,INT,INT,INT,INT,INT,INT ; $84
	dc.l INT,INT,INT,INT,INT,INT,INT,INT ; $A4
	dc.l INT,INT,INT,INT,INT,INT,INT,INT ; $C4
	dc.l INT,INT,INT,INT,INT,INT,INT     ;

	    org    prgbase+$100
        nop				; for debug
        nop
        bsr		dm1
        nop
        rts
        nop
        dc.w	$4afa
        nop
dm1:    move.l	#$12345678,d1
		nop
        rts
        nop
coldent:
        move.l	#$fe0000,svpc  	; test
coldstart:
		move.l	#mstack,a7
        bsr     setsio
        bsr     setwsp
        move.l  #prgbase,d0
        cmp.l   #0,d0
        beq     cmain

        move.b  #$48,d0         ; H
        bsr     OUTCH
        move.b  #$69,d0         ; i
        bsr     OUTCH
        move.b  #$5f,d0         ; _
        bsr     OUTCH
        
        bsr		movemon
        move.w	#$00c0,d0
        move.w  d0,sysport      ; CutOff BaseROM
		move.w	d0,svport
        move.l	#sstack,$0
        move.l	#$00000400,$4
cmain:  move.l	#svtop,-(sp)
		bsr     _main
        addq.w	#4,sp
wtloop: bra wtloop              ; STOP

setsio: move.b  #$03,acias
        move.b  #$15,acias
        move.b  #$0d,d0
        bsr     OUTCH
        rts
setwsp: move.l	#sstack,d0
        move.l	d0,sva7
*        move.l	#sstack-$2000,d0
*        move.l	d0,svusp   
        move.w	ssrn,d0
        move.w	d0,svsr
        rts
movemon:
		move.l	#prgbase,a0
        move.l	#4096-1,d0
movemon2:
		move.l	(a0),(a0)+
        dbra	d0,movemon2
        rts

_BEXEC:
		move.l	4(a7),d0		; break.addr
        move.l	d0,sysport+2
        bra		_NEXT2

_NEXT:	move.l	svpc,sysport+2
_NEXT2:	;move.w	svport,d0
		;or.w	#$0040,d0
        ;move.w	d0,sysport
        ;move.w	d0,svport
        ;move.l	#NMI,d0
        or.w	#$0040,sysport
        move.l	#NMI,$1f*4
_EXEC:
		movem.l d0-d7/a0-a7,svmr0	; save monitor regs
        move.l	svpc,a0			; a0 = go  addr
        move.l	svssp,a7		; a7 = go  ssp
    	move.l	#execrtn,a1		; a1 = ret addr
        move.l	sva7,a7
    	move.l	a1,-(a7)
    	move.l	a0,-(a7)
        move.w	svsr,-(a7)
        move.l	a7,svw0
    	
        movem.l svd0,d0-d7/a0-a6	; load target regs
    	rte							; jump target
execrtn:
		movem.l d0-d7/a0-a6,svd0	; save go after
        move.l	a7,svssp
		movem.l svmr0,d0-d7/a0-a7	; load monitor regs
    	rts
exec2:
		link	a6,#0
		move.l	8(a6),a0
		unlk	a6
		jsr		(a0)
    	rts

ssri:   dc.w    $2000               ;supervisor SR
ssrn:   dc.w    $2700               ;same w/o interrupts
NMI:
INT:
		;move.w	svport,d0
		;and.w	#$ffbf,d0
        ;move.w	d0,sysport
        ;move.w	d0,svport
        and.w	#$ffbf,sysport		; clear break
        move.w  sr,svsr				; Save SR
        move.l  $2(a7),svpc         ; Save PC
        move.w  ssrn,sr             ;disable interrupts    
        
        move.l	a7,svw0+4
        move.l  $2(a7),svw0+8
        add.l	#10,a7
        
        movem.l d0-d7/a0-a7,svd0    ; save regs
        move.l  a7,svssp
        move.l  usp,a0
        move.l  a0,svusp

       	movem.l svmr0,d0-d7/a0-a7
        rts							; retrun to monitor

_OUTCH: 
	link	a6,#0
	move.b	9(a6),d0
	ext.w	d0
	move.w	d0,-(sp)
	jsr	    OUTCH
	unlk	a6
	rts

OUTCH:  move.w	d0,-(sp)
OUTCH2: move.b  acias,d0
        btst    #$1,d0
        beq     OUTCH2
        move.w	(sp)+,d0
        move.b  d0,aciad
        rts

_INCH:
INCH:   move.b  acias,d0
        btst    #$00,d0
        beq     INCH
        clr.l   d0
        move.b  aciad,d0
        rts

_KBHIT: clr.l   d0
        move.b  acias,d0
        and.b   #$01,d0
        rts

; --- Do nothing for this demo ---
HBL:
	rte

; --- Do nothing for this demo ---
VBL:
	rte
