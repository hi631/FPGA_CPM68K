extern void OUTCH();
extern int INCH();
extern int KBHIT();
extern void EXEC();
extern void NEXT();
extern void BEXEC();

#define SDCDBUF 0xff0200L
#define SDCDCTL 0xff0100L
#define MONADR  0xff8000L
#define getch() INCH()
#define putch(ch) OUTCH(ch)

void exec(ldtp,adr) long *ldtp; long adr;{ if(adr!=-1) *(ldtp+1) = adr; EXEC(); }
void next(ldtp,adr) long *ldtp; long adr;{                              NEXT(); }
void bexec(ldtp,adr) long *ldtp; long adr;{                            BEXEC(); }
void puts(buf) char *buf;{ while(*buf!=0) putch(*buf++); }
void gets(buf) char buf[];{
  char ch = 0; int ct = 0;
  while(ch!=0x0d) { 
    ch = getch();
    if(ch==0x08) {if(ct!=0) {putch(0x08);putch(0x20);putch(0x08); ct--; } }
    else   { putch(ch); buf[ct++] = ch; }
  }
}
void puth(dt) int dt;{ if(dt<10) putch(0x30+dt); else putch(0x37+dt); }
void puth2(dt) int dt;{ puth((dt >> 4) & 0xf); puth(dt & 0xf); }
void puth4(dt) int dt;{ puth2((dt >> 8) & 0xff); puth2(dt & 0xff); }
void puth6(dt) long dt;{ int dh,dl; dh = dt >> 16; dl = dt & 0xffff; puth2(dh); puth4(dl); }
void puth8(dt) long dt;{ int dh,dl; dh = dt >> 16; dl = dt & 0xffff; puth4(dh); puth4(dl); }
void setsup(buf) char *buf;{
  while(*buf!=0x0d){
   if( *buf>='a' && *buf<='z') *buf = *buf - 0x20;
   buf++;
  }
}
int ishex(ch) char ch;{
  int hd;
  if(ch>='0' && ch<='9') hd = ch - 0x30;
  else if(ch>='A' && ch<='F') hd = ch - 0x37;
  else hd = -1;
  return hd;
}
long gets2h(buf) char **buf;{
  long num = 0; int hd;
  if(**buf==0x0d) return -1;
  while(**buf==' ') (*buf)++; /* spip sp*/
  while( (hd=ishex(**buf)) != -1){ num = num * 16 + hd; (*buf)++; }
  return num;
}
int geth1b(){ 
  int dt;
  dt = ishex(getch()) * 16 + ishex(getch());
  puth2(dt);
  return dt;
}
unsigned int geth2b(){ return geth1b() * 256 + geth1b(); }

unsigned char  *mbase= (unsigned char *)0x000000;
void putadrhd(adr) long adr;{putch('\n'); puth6(adr); putch(':');}
void getssu(cbuf) char *cbuf;{ gets(cbuf); setsup(cbuf);}

void loadhex(){
  char ch;
  int i,ll,dt;
  long adr;
  int eof = 0;
  while(eof==0){
    while(getch()!=':') ;
    ll = geth1b(); adr = geth2b(); dt = geth1b();
    adr = 0xff0000 + adr;
    if(ll==0) eof = 1;
    else
      for(i=0; i<ll; i++){ dt = geth1b(); mbase[adr++] = dt; }
    puts("\n");
  }
}

void dispr1(lab,dt) char *lab; long dt;{ puts(lab); puth8(dt); }
void dispregs(ldtp) long *ldtp;{
  long *rp; int srreg;
  int i,j; char lbf[5];
  puts("\nDisp.Regs(P="); puth8(ldtp); puts(")\n");
  rp = ldtp; srreg = (*rp++) & 0xffff;
  puts(" PC:"); puth8(*rp++);
  puts(" US:"); puth8(*rp++);
  puts(" SR:"); puth4(srreg);
  lbf[0] = ' '; lbf[3] = ':'; lbf[4] = 0;
  for(i=0; i<3; i++){
    if(i==0) lbf[1] = 'D'; 
    else if(i==1) lbf[1] = 'A';
    else { lbf[1] = 'W'; rp++; }
    putch(0x0d);
    for(j=0; j<8; j++){
       lbf[2] = 0x30+j; dispr1( lbf, *rp++);
    }
  }
    putch(0x0d);
}
void dispnext(ldtp) long *ldtp;{
  unsigned int *pc;
  pc = (unsigned int *)*(ldtp+1);
  puth6(pc); putch(' '); puth4(*pc); putch(' '); puth4(*(pc+1)); puts(" -");
  dispr1(" D0:",*(ldtp+3));  dispr1(" D1:",*(ldtp+4));
  dispr1(" A0:",*(ldtp+11)); dispr1(" A1:",*(ldtp+12)); dispr1(" A7:",*(ldtp+18));
  putch(0x0d);
}
int main(ldtp) long *ldtp; {	/* ldtp = svstop */
  long adr,ade,adro,dt,dtr,wk,sct,scr,sl;
  long i,j,mmd,rno;
  unsigned int * cmp, *wrp, *sbp;
  char cmd, cbuf[32], *cbp, **cbpp;
  
  cbpp = &cbp; adro = 0;
  puts("Mon68K\n");
  while(1){
    puts("\n>"); getssu(cbuf);
    cmd = cbuf[0]; cbp = &cbuf[1];
    switch(cmd){
      case 'B':
        sl = 0; cmd = *cbp; cmp = (unsigned int *)SDCDCTL;
        if(cmd=='O'){ sct = 0x0000; sl = 64; wrp = (unsigned int *)0x000400L; }
        if(cmd=='L'){ sct = 0x8000; sl = 64; wrp = (unsigned int *)0xFE0000L; }
        if(sl!=0){
          puts("Boot\n");  
          for(i=0; i<sl; i++){
            *(cmp+1) = sct >> 16; *(cmp+2) = sct & 0xffff;
            *cmp = 0x01; /* Read.Secter */
            while((*cmp & 1)==1) ; /* Busy.Wait */
            sbp = (unsigned int *)SDCDBUF;
            for(j=0; j<256; j++) { *wrp++ = *sbp++; }
            sct++;
            putch('.');
          }
          if(cmd=='O') exec(ldtp,0x000400L);
        } else {
          if(cmd=='S'){ sct = 0     ; scr = 0x9000; sl = 0x9000; puts("save.all\n");}
          if(cmd=='R'){ sct = 0x9000; scr = 0     ; sl = 0x9000; puts("recover.all\n");}
          if(sl!=0){
            for(i=0; i<sl;i++){
              if((i & 0x1ff)==0) putch('.');
              *(cmp+1) = (unsigned int)(sct >> 16); *(cmp+2) = (unsigned int)(sct & 0xffffL);
              *cmp = 0x01; /* Read.Secter */
              while((*cmp & 1)==1) ; /* Busy.Wait */
              *(cmp+1) = scr >> 16; *(cmp+2) = scr & 0xffff;
              *cmp = 0x02; /* Write.Secter */
              while((*cmp & 1)==1) ; /* Busy.Wait */
              sct++; scr++; 
            }
          }
        }
        
        break;
      case 'W':
        cmd = *cbp;
        if(cmd=='M'){
          wrp = (unsigned int *)0xff4000L;	/* Mon Adr */
          for(i=0; i<8192; i++) { *wrp = *wrp; wrp++; }  /* ROM -> RAM */
        }
        break;
      case 'S':
        if(*cbp=='W') mmd = 2;
        else          mmd = 1;
        cbp++;
        adr = gets2h(cbpp);
        cmp = (unsigned int *)SDCDCTL;
        *(cmp+1) = adr >> 16; *(cmp+2) = adr & 0xffff;
        *cmp = mmd;
        break;
      case 'F':
        adr = gets2h(cbpp); cbp++;
        ade = gets2h(cbpp); cbp++;
        dt  = gets2h(cbpp);
        for(wk=adr; wk<ade; wk++) mbase[wk] = dt;
        break;
      case 'H':
        puts("Load Intel Hex\n");
        loadhex();
        break;
      case 'G':
        adr = gets2h(cbpp); exec(ldtp,adr);
        break;
      case 'N':
        adr = gets2h(cbpp); next(ldtp,adr);
        dispnext(ldtp);
        break;
      case 'V':
        adr = gets2h(cbpp);
        bexec(ldtp,adr);
        dispnext(ldtp);
        break;
      case 'M':
        mmd = 1;
        if(*cbp=='W'){ mmd = 2; cbp++; }
        adr = gets2h(cbpp);
        while(cmd!='.'){
          putadrhd(adr); 
          putch(' '); puth2(mbase[adr]); if(mmd==2) puth2(mbase[adr+1]);
          putch(' '); 
          getssu(cbuf); cbp = &cbuf[0];
          dt = gets2h(cbpp); cmd = *cbp;
          if(cmd==0x0d && dt>=0){
            if(mmd==1){
              if(dt>=0) {
                mbase[adr] = dt; dtr = mbase[adr]; 
                if(dt!=dtr) adr--;
              } 
            } else {
              wrp = (unsigned int *)&mbase[adr];
              if(dt>=0) {
                *wrp = dt; dtr = *wrp; 
                if(dt!=dtr) wrp--;
              }
              adr = (long)wrp;
            }
          }
          if(cmd=='-') adr = adr - mmd;
          else         adr = adr + mmd;
        }
        break;
      case 'D': 
        adr = gets2h(cbpp);
        if(adr==-1) adr = adro;
        for(i=0; i<8; i++){
          putadrhd(adr);
          for(j=0; j<16; j++) { putch(' '); puth2(mbase[adr++]); }
        }
        adro = adr;
        break;
      case 'R': 
        cmd = *cbp++;
        if(cmd=='D') rno = 3;
        if(cmd=='A') rno = 3+8;
        if(cmd=='W') rno = 3+8+8+1;
        if(cmd=='P') rno = 1; 
        else rno = rno + (*cbp++ - 0x30);
        if(rno>0){
          adr = gets2h(cbpp); *(ldtp+rno) = adr;
        }
        dispregs(ldtp);
        break;
      default: puts("??\n");
    }
  }
  return 0;

}

