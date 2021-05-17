.SUFFIXES : .x .o .c .s

CC=..\..\bin\hcc
TOP=..\..\bin\top
AS=..\..\bin\jas
LD=..\..\bin\ld
MF=..\..\bin\srec_cat
RM=del
INC= -I..\..\\include\\

all     :       mon68k


mon68k:  startup.o mon68k.o
	$(LD) -o mon68k.bin startup.o mon68k.o
    $(MF) mon68k.bin -binary -o mon68k.mif -mif 16
#    $(MF) mon68k.bin -binary -o mon68k.hex -Intel
	..\..\bin\bin2bin mon68k.bin mon68kH.bin FF4000
	..\..\bin\srec_cat mon68kH.bin -binary -o mon68kh.mif -mif 16
#	copy mon68kh.mif C:\hard\EP2C5_MINI\cpm68k\rtl\mon68kh.mif
	..\..\bin\bin2hexw mon68kH.bin mon68kh.hex w
#	copy mon68kh.hex C:\hard\EP2C5_MINI\cpm68k\rtl\mon68kh.hex
    del mon68k.bin,mon68k.mif,startup.o,mon68k.o

clean:
	$(RM) *.o
	$(RM) mon68k.s
	$(RM) mon68k.bin

.c.o: 
	@-echo "Making component -> $*.o"
	$(CC) $(INC) $< 
	$(TOP) $*.s
	$(AS) $*.s

.c.s:;

.s.o:
	@-echo "Making component -> $*.o"
	$(AS) $(CDIR)$*.s


# dependencies -- DO NOT DELETE BELOW THIS LINE -- make depends on it.

mon68k.o   : mon68k.c
startup.o  : startup.s
