\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: asmmacros.fth
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
id: @(#)asmmacros.fth 1.10 01/04/06
purpose: 
copyright: Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

headers
0 value tmp-dp
: begin-trap ( trap# -- )
   here to tmp-dp
   5 << origin+  dp !
   do-entercode
;
transient
also assembler definitions
hex

: clear-afsr ( scr sc1 -- )
   drop >r
   %g0  1		r@	sub
   r>   %g0  %g0  h# 4c		stxa
;

: align8 ( -- ) 8 .align  ;
: align80 ( -- ) h# 80 .align  ;

: getx ( rs1 imm rd scr -- )
   >r >r                          ( rs1 imm ) ( r: scr rd )
   2dup  r@  ld                   ( rs1 imm ) ( r: scr rd )
   r@ h# 20 r> r> tuck >r >r sllx ( rs1 imm ) ( r: scr rd )
   la1+  r@  ld                   ( r: scr rd )
   r> r>  over  or                (  )
;

: end-trap ( limit -- )
   here  tmp-dp dp !                  ( limit end )
   swap tuck 5 << origin+             ( end end  limit' )
   [ forth ] >  if [ assembler ]      ( end )
      origin- 5 >>
      ??cr .x  true  abort" Trap Table Entry too big "
   [ forth ] else [ assembler ]       ( end )
      drop                            (  )
   [ forth ] then [ assembler ]       (  )
   end-code                           (  )
;

: set-vector ( vector# vadr -- )
   origin- ROMbase +
   over  begin-trap
   xlsplit             ( vector# nlo nhi )
   dup                 %g2  sethi
   %g2 swap .3ff land  %g2  or
   dup                 %g1  sethi
   %g2      d# 32      %g2  sllx
   %g1      %g2        %g1  or
   %g1 swap .3ff land  %g1  or
   %g1 0               %g0  jmpl
   nop
   ( vector# )
   dup dup 1+ end-trap  2drop
;

resident
previous definitions

