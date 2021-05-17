	.text
	.globl	_exec
_exec:
	link	a6,#0
	cmp.l	#-1,12(a6)
	beq	L3
	move.l	8(a6),a0
	move.l	12(a6),4(a0)
L3:
	jsr	_EXEC
	unlk	a6
	rts
	.text
	.globl	_next
_next:
	link	a6,#0
	jsr	_NEXT
	unlk	a6
	rts
	.text
	.globl	_bexec
_bexec:
	link	a6,#0
	jsr	_BEXEC
	unlk	a6
	rts
	.text
	.globl	_puts
_puts:
	link	a6,#0
L13:
	move.l	8(a6),a0
	tst.b	(a0)
	beq	L12
	move.l	8(a6),a0
	addq.l	#1,8(a6)
	move.b	(a0),d0
	ext.w	d0
	move.w	d0,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	bra	L13
L12:
	unlk	a6
	rts
	.text
	.globl	_gets
_gets:
	link	a6,#-4
	movem.l	d3/d4,-(sp)
	clr.b	d3
	clr.w	d4
L18:
	cmp.b	#13,d3
	beq	L17
	jsr	_INCH
	move.b	d0,d3
	cmp.b	#8,d3
	bne	L20
	tst.w	d4
	beq	L18
	move.w	#8,-(sp)
	jsr	_OUTCH
	move.w	#32,(sp)
	jsr	_OUTCH
	move.w	#8,(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	subq.w	#1,d4
	bra	L18
L20:
	move.b	d3,d0
	ext.w	d0
	move.w	d0,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	move.w	d4,d0
	addq.w	#1,d4
	ext.l	d0
	add.l	8(a6),d0
	move.l	d0,a0
	move.b	d3,(a0)
	bra	L18
L17:
	movem.l	(sp)+,d3/d4
	unlk	a6
	rts
	.text
	.globl	_puth
_puth:
	link	a6,#0
	cmp.w	#10,8(a6)
	bge	L26
	move.w	8(a6),d0
	add.w	#48,d0
	move.w	d0,-(sp)
	jsr	_OUTCH
L25:
	unlk	a6
	rts
L26:
	move.w	8(a6),d0
	add.w	#55,d0
	move.w	d0,-(sp)
	jsr	_OUTCH
	bra	L25
	.text
	.globl	_puth2
_puth2:
	link	a6,#0
	move.w	8(a6),d0
	asr.w	#4,d0
	and.w	#15,d0
	move.w	d0,-(sp)
	jsr	_puth
	move.w	8(a6),d0
	and.w	#15,d0
	move.w	d0,(sp)
	jsr	_puth
	unlk	a6
	rts
	.text
	.globl	_puth4
_puth4:
	link	a6,#0
	move.w	8(a6),d0
	asr.w	#8,d0
	and.w	#255,d0
	move.w	d0,-(sp)
	jsr	_puth2
	move.w	8(a6),d0
	and.w	#255,d0
	move.w	d0,(sp)
	jsr	_puth2
	unlk	a6
	rts
	.text
	.globl	_puth6
_puth6:
	link	a6,#-4
	move.l	8(a6),d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.w	d0,-2(a6)
	move.l	8(a6),d0
	and.l	#65535,d0
	move.w	d0,-4(a6)
	move.w	-2(a6),-(sp)
	jsr	_puth2
	move.w	-4(a6),(sp)
	jsr	_puth4
	unlk	a6
	rts
	.text
	.globl	_puth8
_puth8:
	link	a6,#-4
	move.l	8(a6),d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.w	d0,-2(a6)
	move.l	8(a6),d0
	and.l	#65535,d0
	move.w	d0,-4(a6)
	move.w	-2(a6),-(sp)
	jsr	_puth4
	move.w	-4(a6),(sp)
	jsr	_puth4
	unlk	a6
	rts
	.text
	.globl	_setsup
_setsup:
	link	a6,#0
	move.l	d3,-(sp)
	move.l	8(a6),d3
L43:
	move.l	d3,a0
	cmp.b	#13,(a0)
	beq	L42
	move.l	d3,a0
	cmp.b	#97,(a0)
	blt	L45
	move.l	d3,a0
	cmp.b	#122,(a0)
	bgt	L45
	move.l	d3,a0
	move.b	(a0),d0
	ext.w	d0
	sub.w	#32,d0
	move.l	d3,a0
	move.b	d0,(a0)
L45:
	addq.l	#1,d3
	bra	L43
L42:
	move.l	(sp)+,d3
	unlk	a6
	rts
	.text
	.globl	_ishex
_ishex:
	link	a6,#-2
	movem.l	d3/d4,-(sp)
	move.b	9(a6),d3
	cmp.b	#48,d3
	blt	L49
	cmp.b	#57,d3
	bgt	L49
	move.b	d3,d0
	ext.w	d0
	sub.w	#48,d0
	move.w	d0,d4
L50:
	move.w	d4,d0
	movem.l	(sp)+,d3/d4
	unlk	a6
	rts
L49:
	cmp.b	#65,d3
	blt	L51
	cmp.b	#70,d3
	bgt	L51
	move.b	d3,d0
	ext.w	d0
	sub.w	#55,d0
	move.w	d0,d4
	bra	L50
L51:
	moveq.l	#-1,d4
	bra	L50
	.text
	.globl	_gets2h
_gets2h:
	link	a6,#-6
	movem.l	d3/d4,-(sp)
	moveq.l	#0,d3
	move.l	8(a6),a0
	move.l	(a0),a0
	cmp.b	#13,(a0)
	bne	L57
	moveq.l	#-1,d0
L55:
	movem.l	(sp)+,d3/d4
	unlk	a6
	rts
L57:
	move.l	8(a6),a0
	move.l	(a0),a0
	cmp.b	#32,(a0)
	bne	L59
	move.l	8(a6),a0
	addq.l	#1,(a0)
	bra	L57
L59:
	move.l	8(a6),a0
	move.l	(a0),a0
	move.b	(a0),d0
	ext.w	d0
	move.w	d0,-(sp)
	jsr	_ishex
	addq.w	#2,sp
	move.w	d0,d4
	cmp.w	#-1,d4
	beq	L60
	move.l	d3,d0
	asl.l	#4,d0
	move.w	d4,d1
	ext.l	d1
	add.l	d1,d0
	move.l	d0,d3
	move.l	8(a6),a0
	addq.l	#1,(a0)
	bra	L59
L60:
	move.l	d3,d0
	bra	L55
	.text
	.globl	_geth1b
_geth1b:
	link	a6,#-2
	jsr	_INCH
	move.w	d0,-(sp)
	jsr	_ishex
	asl.w	#4,d0
	move.w	d0,(sp)
	jsr	_INCH
	move.w	d0,-(sp)
	jsr	_ishex
	addq.w	#2,sp
	add.w	(sp)+,d0
	move.w	d0,-2(a6)
	move.w	d0,-(sp)
	jsr	_puth2
	move.w	-2(a6),d0
	unlk	a6
	rts
	.data
	.globl	_mbase
_mbase:
	.dc.l	0
	.text
	.globl	_geth2b
_geth2b:
	link	a6,#0
	jsr	_geth1b
	asl.w	#8,d0
	move.w	d0,-(sp)
	jsr	_geth1b
	add.w	(sp)+,d0
	unlk	a6
	rts
	.text
	.globl	_putadrhd
_putadrhd:
	link	a6,#0
	move.w	#10,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	move.l	8(a6),-(sp)
	jsr	_puth6
	addq.w	#4,sp
	move.w	#58,-(sp)
	jsr	_OUTCH
	unlk	a6
	rts
	.text
	.globl	_getssu
_getssu:
	link	a6,#0
	move.l	8(a6),-(sp)
	jsr	_gets
	move.l	8(a6),(sp)
	jsr	_setsup
	unlk	a6
	rts
	.text
	.globl	_loadhex
_loadhex:
	link	a6,#-14
	movem.l	d3/d4/d5/d6,-(sp)
	clr.w	d6
L76:
	tst.w	d6
	bne	L75
L78:
	jsr	_INCH
	cmp.w	#58,d0
	bne	L78
	jsr	_geth1b
	move.w	d0,d5
	jsr	_geth2b
	moveq.l	#0,d1
	move.w	d0,d1
	move.l	d1,d3
	jsr	_geth1b
	move.w	d0,-8(a6)
	move.l	d3,d0
	add.l	#16711680,d0
	move.l	d0,d3
	tst.w	d5
	bne	L80
	moveq.l	#1,d6
L81:
	move.l	#L85,-(sp)
	jsr	_puts
	addq.w	#4,sp
	bra	L76
L80:
	clr.w	d4
L82:
	move.w	d4,d0
	cmp.w	d5,d0
	bge	L81
	jsr	_geth1b
	move.w	d0,-8(a6)
	move.l	d3,d0
	addq.l	#1,d3
	add.l	_mbase,d0
	move.l	d0,a0
	move.b	-7(a6),(a0)
	addq.w	#1,d4
	bra	L82
L75:
	movem.l	(sp)+,d3/d4/d5/d6
	unlk	a6
	rts
	.text
	.globl	_dispr1
_dispr1:
	link	a6,#0
	move.l	8(a6),-(sp)
	jsr	_puts
	move.l	12(a6),(sp)
	jsr	_puth8
	unlk	a6
	rts
	.text
	.globl	_dispregs
_dispregs:
	link	a6,#-16
	movem.l	d3/d4/d5/d6/d7,-(sp)
	move.l	8(a6),d6
	move.l	#L92,-(sp)
	jsr	_puts
	move.l	d6,(sp)
	jsr	_puth8
	move.l	#L93,(sp)
	jsr	_puts
	move.l	d6,d3
	move.l	d6,d0
	addq.l	#4,d3
	move.l	d0,a0
	move.l	(a0),d0
	and.l	#65535,d0
	move.w	d0,d7
	move.l	#L94,(sp)
	jsr	_puts
	move.l	d3,d0
	addq.l	#4,d3
	move.l	d0,a0
	move.l	(a0),(sp)
	jsr	_puth8
	move.l	#L95,(sp)
	jsr	_puts
	move.l	d3,d0
	addq.l	#4,d3
	move.l	d0,a0
	move.l	(a0),(sp)
	jsr	_puth8
	move.l	#L96,(sp)
	jsr	_puts
	addq.w	#4,sp
	move.w	d7,-(sp)
	jsr	_puth4
	addq.w	#2,sp
	move.b	#32,-15(a6)
	move.b	#58,-12(a6)
	clr.b	-11(a6)
	clr.w	d4
L97:
	cmp.w	#3,d4
	bge	L99
	tst.w	d4
	bne	L100
	move.b	#68,-14(a6)
L101:
	move.w	#13,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	clr.w	d5
L104:
	cmp.w	#8,d5
	bge	L98
	move.w	d5,d0
	add.w	#48,d0
	move.b	d0,-13(a6)
	move.l	d3,d0
	addq.l	#4,d3
	move.l	d0,a0
	move.l	(a0),-(sp)
	pea	-15(a6)
	jsr	_dispr1
	addq.w	#8,sp
	addq.w	#1,d5
	bra	L104
L98:
	addq.w	#1,d4
	bra	L97
L100:
	cmp.w	#1,d4
	bne	L102
	move.b	#65,-14(a6)
	bra	L101
L102:
	move.b	#87,-14(a6)
	addq.l	#4,d3
	bra	L101
L99:
	move.w	#13,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	movem.l	(sp)+,d3/d4/d5/d6/d7
	unlk	a6
	rts
	.text
	.globl	_dispnext
_dispnext:
	link	a6,#-4
	movem.l	d3/d4,-(sp)
	move.l	8(a6),d3
	move.l	d3,a0
	move.l	4(a0),d4
	move.l	d4,-(sp)
	jsr	_puth6
	addq.w	#4,sp
	move.w	#32,-(sp)
	jsr	_OUTCH
	move.l	d4,a0
	move.w	(a0),(sp)
	jsr	_puth4
	move.w	#32,(sp)
	jsr	_OUTCH
	move.l	d4,a0
	move.w	2(a0),(sp)
	jsr	_puth4
	addq.w	#2,sp
	move.l	#L110,-(sp)
	jsr	_puts
	move.l	d3,a0
	move.l	12(a0),(sp)
	move.l	#L111,-(sp)
	jsr	_dispr1
	addq.w	#8,sp
	move.l	d3,a0
	move.l	16(a0),-(sp)
	move.l	#L112,-(sp)
	jsr	_dispr1
	addq.w	#8,sp
	move.l	d3,a0
	move.l	44(a0),-(sp)
	move.l	#L113,-(sp)
	jsr	_dispr1
	addq.w	#8,sp
	move.l	d3,a0
	move.l	48(a0),-(sp)
	move.l	#L114,-(sp)
	jsr	_dispr1
	addq.w	#8,sp
	move.l	d3,a0
	move.l	72(a0),-(sp)
	move.l	#L115,-(sp)
	jsr	_dispr1
	addq.w	#8,sp
	move.w	#13,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	movem.l	(sp)+,d3/d4
	unlk	a6
	rts
	.data
L200:	.dc.b	$3f,$3f,$a
	.dc.b	0
L166:	.dc.b	$4c,$6f,$61,$64,$20,$49,$6e,$74,$65,$6c,$20
	.dc.b	$48,$65,$78,$a
	.dc.b	0
L143:	.dc.b	$72,$65,$63,$6f,$76,$65,$72,$2e,$61,$6c,$6c
	.dc.b	$a
	.dc.b	0
L141:	.dc.b	$73,$61,$76,$65,$2e,$61,$6c,$6c,$a
	.dc.b	0
L129:	.dc.b	$42,$6f,$6f,$74,$a
	.dc.b	0
L122:	.dc.b	$a,$3e
	.dc.b	0
L119:	.dc.b	$4d,$6f,$6e,$36,$38,$4b,$a
	.dc.b	0
L115:	.dc.b	$20,$41,$37,$3a
	.dc.b	0
L114:	.dc.b	$20,$41,$31,$3a
	.dc.b	0
L113:	.dc.b	$20,$41,$30,$3a
	.dc.b	0
L112:	.dc.b	$20,$44,$31,$3a
	.dc.b	0
L111:	.dc.b	$20,$44,$30,$3a
	.dc.b	0
L110:	.dc.b	$20,$2d
	.dc.b	0
L96:	.dc.b	$20,$53,$52,$3a
	.dc.b	0
L95:	.dc.b	$20,$55,$53,$3a
	.dc.b	0
L94:	.dc.b	$20,$50,$43,$3a
	.dc.b	0
L93:	.dc.b	$29,$a
	.dc.b	0
L92:	.dc.b	$a,$44,$69,$73,$70,$2e,$52,$65,$67,$73,$28
	.dc.b	$50,$3d
	.dc.b	0
L85:	.dc.b	$a
	.dc.b	0
	.text
	.globl	_main
_main:
	link	a6,#-106
	movem.l	d3/d4/d5/d6/d7,-(sp)
	lea	-102(a6),a0
	move.l	a0,-106(a6)
	clr.l	-12(a6)
	move.l	#L119,-(sp)
	jsr	_puts
	addq.w	#4,sp
L120:
	move.l	#L122,-(sp)
	jsr	_puts
	addq.w	#4,sp
	pea	-97(a6)
	jsr	_getssu
	addq.w	#4,sp
	move.b	-97(a6),d4
	lea	-96(a6),a0
	move.l	a0,-102(a6)
	move.b	d4,d0
	ext.w	d0
	cmp.w	#66,d0
	blt	L199
	cmp.w	#87,d0
	bgt	L199
T61:
	sub.w	#66,d0
	ext.l	d0
	asl.l	#2,d0
	move.l	4(pc,d0.l),a0
	jmp	(a0)
	.dc.l	L125
	.dc.l	L199
	.dc.l	L184
	.dc.l	L199
	.dc.l	L161
	.dc.l	L167
	.dc.l	L165
	.dc.l	L199
	.dc.l	L199
	.dc.l	L199
	.dc.l	L199
	.dc.l	L170
	.dc.l	L168
	.dc.l	L199
	.dc.l	L199
	.dc.l	L199
	.dc.l	L192
	.dc.l	L158
	.dc.l	L199
	.dc.l	L199
	.dc.l	L169
	.dc.l	L153
	bra	L120
L199:
	move.l	#L200,-(sp)
	jsr	_puts
	addq.w	#4,sp
	bra	L120
L125:
	clr.l	-36(a6)
	move.l	-102(a6),a0
	move.b	(a0),d4
	move.l	#16711936,d5
	cmp.b	#79,d4
	bne	L126
	clr.l	-28(a6)
	move.l	#64,-36(a6)
	move.l	#1024,d7
L126:
	cmp.b	#76,d4
	bne	L127
	move.l	#32768,-28(a6)
	move.l	#64,-36(a6)
	move.l	#16646144,d7
L127:
	tst.l	-36(a6)
	beq	L128
	move.l	#L129,-(sp)
	jsr	_puts
	addq.w	#4,sp
	moveq.l	#0,d6
L130:
	move.l	d6,d0
	cmp.l	-36(a6),d0
	bge	L132
	move.l	-28(a6),d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.l	d5,a0
	move.w	d0,2(a0)
	move.l	-28(a6),d0
	and.l	#65535,d0
	move.l	d5,a0
	move.w	d0,4(a0)
	move.l	d5,a0
	move.w	#1,(a0)
L133:
	move.l	d5,a0
	move.w	(a0),d0
	and.w	#1,d0
	cmp.w	#1,d0
	beq	L133
	move.l	#16712192,-64(a6)
	clr.l	-44(a6)
L135:
	cmp.l	#256,-44(a6)
	bge	L137
	move.l	-64(a6),a0
	addq.l	#2,-64(a6)
	move.l	d7,a1
	addq.l	#2,d7
	move.w	(a0),(a1)
	addq.l	#1,-44(a6)
	bra	L135
L137:
	addq.l	#1,-28(a6)
	move.w	#46,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	addq.l	#1,d6
	bra	L130
L132:
	cmp.b	#79,d4
	bne	L120
	move.l	#1024,-(sp)
	move.l	8(a6),-(sp)
	jsr	_exec
	addq.w	#8,sp
	bra	L120
L128:
	cmp.b	#83,d4
	bne	L140
	clr.l	-28(a6)
	move.l	#36864,-32(a6)
	move.l	#36864,-36(a6)
	move.l	#L141,-(sp)
	jsr	_puts
	addq.w	#4,sp
L140:
	cmp.b	#82,d4
	bne	L142
	move.l	#36864,-28(a6)
	clr.l	-32(a6)
	move.l	#36864,-36(a6)
	move.l	#L143,-(sp)
	jsr	_puts
	addq.w	#4,sp
L142:
	tst.l	-36(a6)
	beq	L120
	moveq.l	#0,d6
L145:
	move.l	d6,d0
	cmp.l	-36(a6),d0
	bge	L120
	move.l	d6,d0
	and.l	#511,d0
	bne	L148
	move.w	#46,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
L148:
	move.l	-28(a6),d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.l	d5,a0
	move.w	d0,2(a0)
	move.l	-28(a6),d0
	and.l	#65535,d0
	move.l	d5,a0
	move.w	d0,4(a0)
	move.l	d5,a0
	move.w	#1,(a0)
L149:
	move.l	d5,a0
	move.w	(a0),d0
	and.w	#1,d0
	cmp.w	#1,d0
	beq	L149
	move.l	-32(a6),d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.l	d5,a0
	move.w	d0,2(a0)
	move.l	-32(a6),d0
	and.l	#65535,d0
	move.l	d5,a0
	move.w	d0,4(a0)
	move.l	d5,a0
	move.w	#2,(a0)
L151:
	move.l	d5,a0
	move.w	(a0),d0
	and.w	#1,d0
	cmp.w	#1,d0
	beq	L151
	addq.l	#1,-28(a6)
	addq.l	#1,-32(a6)
	addq.l	#1,d6
	bra	L145
L153:
	move.l	-102(a6),a0
	move.b	(a0),d4
	cmp.b	#77,d4
	bne	L120
	move.l	#16728064,d7
	moveq.l	#0,d6
L155:
	cmp.l	#8192,d6
	bge	L120
	move.l	d7,a0
	move.l	d7,a1
	move.w	(a0),(a1)
	addq.l	#2,d7
	addq.l	#1,d6
	bra	L155
L158:
	move.l	-102(a6),a0
	cmp.b	#87,(a0)
	bne	L159
	move.l	#2,-48(a6)
L160:
	addq.l	#1,-102(a6)
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,d3
	move.l	#16711936,d5
	move.l	d3,d0
	moveq.l	#16,d1
	asr.l	d1,d0
	move.l	d5,a0
	move.w	d0,2(a0)
	move.l	d3,d0
	and.l	#65535,d0
	move.l	d5,a0
	move.w	d0,4(a0)
	move.l	d5,a0
	move.w	-46(a6),(a0)
	bra	L120
L159:
	move.l	#1,-48(a6)
	bra	L160
L161:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	move.l	d0,d3
	addq.l	#1,-102(a6)
	move.l	-106(a6),(sp)
	jsr	_gets2h
	move.l	d0,-8(a6)
	addq.l	#1,-102(a6)
	move.l	-106(a6),(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,-16(a6)
	move.l	d3,-24(a6)
L162:
	move.l	-24(a6),d0
	cmp.l	-8(a6),d0
	bge	L120
	move.l	_mbase,d0
	add.l	-24(a6),d0
	move.l	d0,a0
	move.b	-13(a6),(a0)
	addq.l	#1,-24(a6)
	bra	L162
L165:
	move.l	#L166,-(sp)
	jsr	_puts
	addq.w	#4,sp
	jsr	_loadhex
	bra	L120
L167:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	move.l	d0,(sp)
	move.l	8(a6),-(sp)
	jsr	_exec
	addq.w	#8,sp
	bra	L120
L168:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	move.l	d0,(sp)
	move.l	8(a6),-(sp)
	jsr	_next
	addq.w	#8,sp
	move.l	8(a6),-(sp)
	jsr	_dispnext
	addq.w	#4,sp
	bra	L120
L169:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	move.l	d0,(sp)
	move.l	8(a6),-(sp)
	jsr	_bexec
	addq.w	#8,sp
	move.l	8(a6),-(sp)
	jsr	_dispnext
	addq.w	#4,sp
	bra	L120
L170:
	move.l	#1,-48(a6)
	move.l	-102(a6),a0
	cmp.b	#87,(a0)
	bne	L171
	move.l	#2,-48(a6)
	addq.l	#1,-102(a6)
L171:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,d3
L172:
	cmp.b	#46,d4
	beq	L120
	move.l	d3,-(sp)
	jsr	_putadrhd
	addq.w	#4,sp
	move.w	#32,-(sp)
	jsr	_OUTCH
	move.l	_mbase,d0
	add.l	d3,d0
	move.l	d0,a0
	clr.w	d0
	move.b	(a0),d0
	move.w	d0,(sp)
	jsr	_puth2
	addq.w	#2,sp
	cmp.l	#2,-48(a6)
	bne	L174
	move.l	d3,d0
	addq.l	#1,d0
	add.l	_mbase,d0
	move.l	d0,a0
	clr.w	d0
	move.b	(a0),d0
	move.w	d0,-(sp)
	jsr	_puth2
	addq.w	#2,sp
L174:
	move.w	#32,-(sp)
	jsr	_OUTCH
	addq.w	#2,sp
	pea	-97(a6)
	jsr	_getssu
	lea	-97(a6),a0
	move.l	a0,-102(a6)
	move.l	-106(a6),(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,-16(a6)
	move.l	-102(a6),a0
	move.b	(a0),d4
	cmp.b	#13,d4
	bne	L175
	tst.l	-16(a6)
	blt	L175
	cmp.l	#1,-48(a6)
	bne	L176
	tst.l	-16(a6)
	blt	L175
	move.l	_mbase,d0
	add.l	d3,d0
	move.l	d0,a0
	move.b	-13(a6),(a0)
	move.l	_mbase,d0
	add.l	d3,d0
	move.l	d0,a0
	moveq.l	#0,d0
	move.b	(a0),d0
	move.l	d0,-20(a6)
	move.l	-16(a6),d0
	cmp.l	-20(a6),d0
	beq	L175
	subq.l	#1,d3
L175:
	cmp.b	#45,d4
	bne	L182
	move.l	d3,d0
	sub.l	-48(a6),d0
	move.l	d0,d3
	bra	L172
L182:
	move.l	d3,d0
	add.l	-48(a6),d0
	move.l	d0,d3
	bra	L172
L176:
	move.l	_mbase,d0
	add.l	d3,d0
	move.l	d0,d7
	tst.l	-16(a6)
	blt	L180
	move.l	d7,a0
	move.w	-14(a6),(a0)
	move.l	d7,a0
	moveq.l	#0,d0
	move.w	(a0),d0
	move.l	d0,-20(a6)
	move.l	-16(a6),d0
	cmp.l	-20(a6),d0
	beq	L180
	subq.l	#2,d7
L180:
	move.l	d7,d3
	bra	L175
L184:
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,d3
	cmp.l	#-1,d3
	bne	L185
	move.l	-12(a6),d3
L185:
	moveq.l	#0,d6
L186:
	cmp.l	#8,d6
	bge	L188
	move.l	d3,-(sp)
	jsr	_putadrhd
	addq.w	#4,sp
	clr.l	-44(a6)
L189:
	cmp.l	#16,-44(a6)
	bge	L187
	move.w	#32,-(sp)
	jsr	_OUTCH
	move.l	d3,d0
	addq.l	#1,d3
	add.l	_mbase,d0
	move.l	d0,a0
	clr.w	d0
	move.b	(a0),d0
	move.w	d0,(sp)
	jsr	_puth2
	addq.w	#2,sp
	addq.l	#1,-44(a6)
	bra	L189
L187:
	addq.l	#1,d6
	bra	L186
L188:
	move.l	d3,-12(a6)
	bra	L120
L192:
	move.l	-102(a6),a0
	addq.l	#1,-102(a6)
	move.b	(a0),d4
	cmp.b	#68,d4
	bne	L193
	move.l	#3,-52(a6)
L193:
	cmp.b	#65,d4
	bne	L194
	move.l	#11,-52(a6)
L194:
	cmp.b	#87,d4
	bne	L195
	move.l	#20,-52(a6)
L195:
	cmp.b	#80,d4
	bne	L196
	move.l	#1,-52(a6)
L197:
	tst.l	-52(a6)
	ble	L198
	move.l	-106(a6),-(sp)
	jsr	_gets2h
	addq.w	#4,sp
	move.l	d0,d3
	move.l	-52(a6),d0
	asl.l	#2,d0
	add.l	8(a6),d0
	move.l	d0,a0
	move.l	d3,(a0)
L198:
	move.l	8(a6),-(sp)
	jsr	_dispregs
	addq.w	#4,sp
	bra	L120
L196:
	move.l	-102(a6),a0
	addq.l	#1,-102(a6)
	move.b	(a0),d0
	ext.w	d0
	sub.w	#48,d0
	ext.l	d0
	add.l	-52(a6),d0
	move.l	d0,-52(a6)
	bra	L197
