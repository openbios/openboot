\ dfill.fth 2.5 94/05/30
\ Copyright 1985-1990 Bradley Forthware

\ Doubleword fill.  This is the fastest way of filling memory on a SPARC.
\ This is primarily used for clearing memory to initialize the parity.

headers
code cfill  (s start-addr count char -- )
			\ char in tos
   sp 0 /n*  scr  nget	\ count in scr
   sp 1 /n*  sc1  nget	\ start in sc1

   ahead	\ jump to the until  branch
   nop
   begin
      tos  sc1 scr  stb
   but then
      scr 1  scr  subcc
   0< until
      nop		\ Delay slot

   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
c;

code wfill  (s start-addr count shortword -- )
			\ char in tos
   sp 0 /n*  scr  nget	\ count in scr
   sp 1 /n*  sc1  nget	\ start in sc1

   ahead	\ jump to the until  branch
   nop
   begin
      tos  sc1 scr  sth
   but then
      scr 2  scr  subcc
   0< until
      nop		\ Delay slot

   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
c;

code lfill  (s start-addr count longword -- )
			\ char in tos
   sp 0 /n*  scr  nget	\ count in scr
   sp 1 /n*  sc1  nget	\ start in sc1

   ahead	\ jump to the until  branch
   nop
   begin
      tos  sc1 scr  st
   but then
      scr 4  scr  subcc
   0< until
      nop		\ Delay slot

   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
c;
headerless
here lastacf -  constant /lfill

\ For this implementation, count must be a multiple of 32 bytes, and
\ start-addr must be aligned on an 8-byte boundary.

headers
code dfill  (s start-addr count odd-word even-word -- )
   tos   sc2  move	\ even-word in sc2
   sp    sc3  pop	\ odd-word in sc3
   sp    scr  pop	\ count in scr
   sp    sc1  pop	\ start in sc1
   sp    tos  pop	\ fix stack

64\ \ XXXX merge sc2 and sc3 into sc2 XXXXX

   scr  0  cmp
   <> if
   nop
      begin
32\      sc2  sc1 0       std
64\      sc2  sc1 0       stx
         scr d# 32  scr   subcc	\ Try to fill pipeline interlocks
32\      sc2  sc1 8       std
64\      sc2  sc1 8       stx
	 sc1 d# 32  sc1   add
32\      sc2  sc1 d# -16  std
64\      sc2  sc1 d# -16  stx
      0<= until
32\      sc2  sc1 d# -08  std
64\      sc2  sc1 d# -08  stx
   then
c;
headerless
here lastacf -  constant /dfill

\ We can also scrub parity errors by reading and writing memory.
\ This is slower than just clearing it, but it preserves the previous
\ contents, which is nice after Unix has crashed

code ltouch  ( adr len -- )
    tos  sc1  move        \ count in sc1
    sp   sc2  pop       \ adr in sc2
    sp   tos  pop

    sc1  0    cmp
    <> if
    nop

       begin
          sc1 4     sc1       subcc
          sc2  sc1  sc4       ld
       0<= until
          sc4       sc2 sc1   st

    then
c;
here lastacf -  constant /ltouch

code dtouch  ( adr len -- )
    tos  sc1  move        \ count in sc1
    sp   sc2  pop  	\ adr in sc2
    sp   tos  pop

    sc1  0    cmp
    <> if
    nop

       begin
          sc1 8     sc1       subcc
32\       sc2  sc1  sc4       ldd
64\       sc2  sc1  sc4       ldx
       0<= until
32\       sc4       sc2 sc1   std
64\       sc4       sc2 sc1   stx

    then
c;
here lastacf -  constant /dtouch
headers
