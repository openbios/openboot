\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mmuregs.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)mmuregs.fth 1.1 06/02/22
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headerless

1 d# 57 lshift 1- d# 26 >> d# 26 << constant afsr-mask

: mmureg!: ( adr asi -- ) \ name ( n -- )
   create c, c,  ;code
   \itc  sc1 /token  scr  add	\ >body
   scr 1       sc1  ldub	\ c@  ( adr )
   scr 0       sc2  ldub	\ c@  ( asi )
   %r3         sc3  rdasr	\ save %asi in sc3
   sc2 0       %r3  wrasr	\ set %asi
   #Sync  membar
   tos   sc1 0 %asi stxa
   #Sync  membar
   sc3 0       %r3  wrasr	\ restore %asi
   sp          tos  pop
c;

: mmureg@: ( adr asi -- ) \ name ( -- n )
   create c, c,
   ;code
   tos          sp   push
   \itc  sc1 /token  scr  add	\ >body
   scr 1       sc1  ldub	\ c@  ( adr )
   scr 0       sc2  ldub	\ c@  ( asi )
   %r3         sc3  rdasr	\ save %asi in sc3
   sc2 0       %r3  wrasr	\ set %asi
   #Sync  membar
   sc1 0 %asi  tos  ldxa
   #Sync  membar
   sc3 0       %r3  wrasr	\ restore %asi
c;


hex
headers

38 20 mmureg@: scratch7@ \ RA of cpu struct
38 20 mmureg!: scratch7!

alias lsucr@ 0
alias lsucr! drop 

alias cpu-error-enable@ 0 ( -- n )
alias cpu-error-enable! drop ( n -- )

alias cpu-afsr@ 0 ( -- n )
alias cpu-afsr! drop ( n -- )

also assembler definitions

: get-mid ( reg -- )
  >r %g0 h# 08 r@ add
  r@ %g0 h# 20 r@ ldxa
  r@ h# ff     r@ and
  r> drop
;

previous definitions

code mid@ ( -- upa-mid )
   tos           sp   push
   tos  get-mid
c;

code pcr@ ( -- n )
   tos  sp  push
   %r16 tos rdasr
c;

code pcr! ( n -- )
   tos 0 %r16 wrasr
   sp    tos  pop
c;

code pic@ ( -- n )
   tos  sp  push
   %r17 tos rdasr
c;

code pic! ( n -- )
   tos 0 %r17 wrasr
   sp    tos  pop
c;

code gsr@ ( -- n )
   tos  sp  push
   %r19 tos rdasr
c;

code gsr! ( n -- )
   tos 0 %r19 wrasr
   sp    tos  pop
c;

code set-softint! ( n -- )
   tos 0 %r20 wrasr
   sp    tos  pop
c;

code clear-softint! ( n -- )
   tos 0 %r21 wrasr
   sp    tos  pop
c;

code softint@ ( -- n )
   tos  sp  push
   %r22 tos rdasr
c;

code tick-compare@ ( -- n )
   tos  sp  push
   %r23 tos rdasr
c;

code stick@ ( -- n )
   tos  sp  push
   %r24 tos rdasr
c;

code stick! ( -- n )
   tos 0 %r24 wrasr
   sp    tos  pop
c;

code tick-compare! ( n -- )
   tos 0 %r23 wrasr
   sp    tos  pop
c;

code stick-compare@ ( -- n )
   tos  sp  push
   %r25 tos rdasr
c;

code stick-compare! ( n -- )
   tos 0 %r25 wrasr
   sp    tos  pop
c;

: init-cpu-errs ( -- )
exit
   afsr-mask cpu-afsr!		\ CPU AFSR
;

headerless

: clr-cpu-error-enable ( bit -- )
drop exit
   1 swap << invert cpu-error-enable@ and cpu-error-enable!
;

: set-cpu-error-enable ( bit -- )
drop exit
   1 swap << cpu-error-enable@ or cpu-error-enable!
;

headers
: ce-off  ( -- )	0 clr-cpu-error-enable ;
: ce-on   ( -- )	0 set-cpu-error-enable ;
: ecache-ecc-on ( -- )	3 set-cpu-error-enable ;
: ecache-ecc-off ( -- )	3 clr-cpu-error-enable ;
: ecc-off ( -- )	1 clr-cpu-error-enable ;
: ecc-on  ( -- )	init-cpu-errs 1 set-cpu-error-enable ;

\ berr cannot disable ECC, because doind so means we don't take the probe traps
\ we do need to disable bit 21 or the machine will take a fatal reset though
\
: berr-off ( -- )	d# 21 clr-cpu-error-enable ;
: berr-on ( -- )	ecc-on d# 21 set-cpu-error-enable ;

: disable-cpu-errors ( -- )
   ecache-ecc-off ce-off ecc-off berr-off
;

\ XXX
: enable-cpu-errors ( -- )
exit
   init-cpu-errs		\ start with a clean slate
   ecc-on  ce-on berr-on
   cpu-error-enable@
   h# 1.00d0.0014			\ Enable All errors!
   or cpu-error-enable!
;

headerless
: 1bits ( mask #bits -- mask' bits )  1 bits  ;
: 8bits ( mask #bits -- mask' bits )  8 bits  ;

\ XXXX THIS FILE IS NOT REALLY THE BEST PLACE FOR THIS  XXXX
\ XXXX BUT FORM NOW IT'LL HAVE TO DO I GUESS XXXX

\ Secondary Asi DUMP and DIS

\ The dump utility gives you a formatted hex dump with the ascii
\ text corresponding to the bytes on the right hand side of the
\ screen.

[ifexist] disassembler
only forth also hidden also  definitions

headerless
: (asi-secondary-c@)  ( padr -- byte ) h# 81 spacec@  ;
forth definitions
headers
: sdump (s addr len -- )    ['] (asi-secondary-c@) is dc@  (dump)  ;
: sdu   (s addr -- addr+64 )  dup d# 64 sdump   d# 64 +  ;
previous previous definitions

also disassembler also definitions
headerless
: (sinst@ ( adr -- opcode )  h# 81 spacel@  ;

forth definitions
headers
: sdis1  ( -- )
   ??cr  ['] (sinst@ is inst@
   pc@ +offset  udis.  4 spaces  #out @  start-column !
   pc@l@ disasm  cr
   /l pc@ + pc!
;
: +sdis  ( -- )
   base @ >r  hex
   end-found off
   begin   sdis1  end-found @  exit? or  until
   sdis1       \ Disassemble the delay instruction too
   r> base !
;
: sdis  ( adr -- )   pc!   +sdis  ;
previous previous also  definitions
[then]
