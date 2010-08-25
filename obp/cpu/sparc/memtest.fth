\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: memtest.fth
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
id: @(#)memtest.fth 1.3 94/05/30
purpose: Fast memory test
copyright: Copyright 1992 Sun Microsystems, Inc.  All Rights Reserved

headerless
code test-memory  ( start-addr count -- obs-data exp-data fail-adr true | false )

   tos   scr  move	\ count in scr
   sp 0  sc1  nget	\ start in sc1

   \ Backwards fill with 0
   scr  sc2  move
   0 F:  bra	\ jump to the until  branch
   nop
   begin
      %g0  sc1 sc2  st
   0 L:
      sc2 4  sc2  subcc
   0< until
      nop		\ Delay slot

   \ Forward test for 0 and fill with -1
   -1  sc4  set
   %g0  sc2  move
   0 F:  bra	\ jump to the until  branch
   nop
   begin
      sc1 sc2  sc3  ld
      sc3 %g0  %g0  subcc
      0<> if nop
         -1  tos    move     \ fail
         sp 2 /n*   sp  sub  \ Make room on the stack
         sc1 sc2    sc1 add  \ failed address
         sc1  sp 0 /n*  nput \ failed adr
         %g0  sp 1 /n*  nput \ expected data
         sc3  sp 2 /n*  nput \ observed data
	 next                \ exit
      then
      sc4  sc1 sc2 st
      sc2 4 sc2 add
   0 L:
      scr sc2  %g0  subcc
   0<= until
      nop		\ Delay slot

   \ Backwards check for -1 and fill with 0
   -1  sc4  set
   scr  sc2  move
   0 F:  bra	\ jump to the until  branch
   nop
   begin
      sc1 sc2  sc3  ld
      sc3 sc4  %g0  subcc
      0<> if nop
         -1  tos    move     \ fail
         sc1 sc2  sc1 add    \ failed address
         sc1  sp 0 /n*  nput 
         sc4  sp 1 /n*  nput \ expected data
         sc3  sp 2 /n*  nput \ observed data
	 next                \ exit
      then
      %g0  sc1 sc2 st
   0 L:
      sc2 4  sc2  subcc
   0< until
      nop		\ Delay slot

      0 tos  move	        \ put false (=pass) on stack
      sp  /n   sp   add		\   "
c;
headers

