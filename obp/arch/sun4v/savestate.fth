\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: savestate.fth
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
id: @(#)savestate.fth 1.1 06/02/16
purpose: Saves CPU state for later retrieval
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
transient
also forth definitions
: offset-of  \ name  ( -- offset )
   parse-word ['] forth $vfind  if
      >body w@ 1
   else
      ." offset-of can't find " type  cr
      where
   then
   do-literal
; immediate
previous definitions
resident


\ input: %o7 return address 
\ output: %o0 ptr to cpu struct 
\ %o7, %asi and %g7 in GL2 are trashed and not saved
label save-reset-state

   %g0 2 wrgl

   \ Get cpu struct stashed in SCRATCH7
   %g0 h# 20 wrasi
   %g0 h# 38 %asi  %g7 ldxa

   %g0 memory-asi wrasi

   %g1 rdpil         %g1  %g7 offset-of %pil        %asi  stxa
   %g1 rdcwp         %g1  %g7 offset-of %cwp        %asi  stxa
   %g1 rdcansave     %g1  %g7 offset-of %cansave    %asi  stxa
   %g1 rdcanrestore  %g1  %g7 offset-of %canrestore %asi  stxa
   %g1 rdcleanwin    %g1  %g7 offset-of %cleanwin   %asi  stxa
   %g1 rdotherwin    %g1  %g7 offset-of %otherwin   %asi  stxa
   %g1 rdwstate      %g1  %g7 offset-of %wstate     %asi  stxa
   %g1 rdpstate      %g1  %g7 offset-of %pstate     %asi  stxa
   %g1 rdgl          %g1  %g7 offset-of %gl         %asi  stxa

   %g1 rdy           %g1  %g7 offset-of %y          %asi  stxa
   %g1 rdccr         %g1  %g7 offset-of %ccr        %asi  stxa
   %g1 rdasi         %g1  %g7 offset-of %asi        %asi  stxa
   %g1 rdfprs        %g1  %g7 offset-of %fprs       %asi  stxa

   %g1 rdtpc         %g1  %g7 offset-of %pc         %asi  stxa
   %g1 rdtnpc        %g1  %g7 offset-of %npc        %asi  stxa
   %g1 rdtba         %g1  %g7 offset-of %tba        %asi  stxa
   %g1 rdtl          %g1  %g7 offset-of %tl-c       %asi  stxa

   %g1 rdtt          %g1  %g7 offset-of %tt-c       %asi  stxa
   %g1 rdtpc         %g1  %g7 offset-of %tpc-c      %asi  stxa
   %g1 rdtnpc        %g1  %g7 offset-of %tnpc-c     %asi  stxa
   %g1 rdtstate      %g1  %g7 offset-of %tstate-c   %asi  stxa

   %g0  1  %g1  sub
   %g0  %g7 offset-of %restartable?    %asi stxa
   %o7  %g6 move	\ return address in %g6, GL=2

   \ Save all of the Trap State Registers

   %g3 rdtl

   %g0  2 wrtl
   %g1  rdtt         %g1  %g7  offset-of %tt-2      %asi  stxa
   %g1  rdtpc        %g1  %g7  offset-of %tpc-2     %asi  stxa
   %g1  rdtnpc       %g1  %g7  offset-of %tnpc-2    %asi  stxa
   %g1  rdtstate     %g1  %g7  offset-of %tstate-2  %asi  stxa

   %g0  1 wrtl
   %g1  rdtt         %g1  %g7  offset-of %tt-1      %asi  stxa
   %g1  rdtpc        %g1  %g7  offset-of %tpc-1     %asi  stxa
   %g1  rdtnpc       %g1  %g7  offset-of %tnpc-1    %asi  stxa
   %g1  rdtstate     %g1  %g7  offset-of %tstate-1  %asi  stxa

   %g3 0 wrtl

   %g0  window-registers  %g1    add
   %g1  %g7		  %g1	 add

   %o0   %g1   0 /n*  %asi   stxa	\ %o0
   %o1   %g1   1 /n*  %asi   stxa	\ %o1
   %o2   %g1   2 /n*  %asi   stxa	\ %o2
   %o3   %g1   3 /n*  %asi   stxa	\ %o3
   %o4   %g1   4 /n*  %asi   stxa	\ %o4
   %o5   %g1   5 /n*  %asi   stxa	\ %o5
   %o6   %g1   6 /n*  %asi   stxa	\ %o6
   %o7   %g1   7 /n*  %asi   stxa	\ %o7

   %g1   8 /n*  %g1    add

   %l0   %g1   0 /n*  %asi   stxa	\ %l0
   %l1   %g1   1 /n*  %asi   stxa	\ %l1
   %l2   %g1   2 /n*  %asi   stxa	\ %l2
   %l3   %g1   3 /n*  %asi   stxa	\ %l3
   %l4   %g1   4 /n*  %asi   stxa	\ %l4
   %l5   %g1   5 /n*  %asi   stxa	\ %l5
   %l6   %g1   6 /n*  %asi   stxa	\ %l6
   %l7   %g1   7 /n*  %asi   stxa	\ %l7

   %g1   8 /n*  %g1    add

   %i0   %g1   0 /n*  %asi   stxa	\ %i0
   %i1   %g1   1 /n*  %asi   stxa	\ %i1
   %i2   %g1   2 /n*  %asi   stxa	\ %i2
   %i3   %g1   3 /n*  %asi   stxa	\ %i3
   %i4   %g1   4 /n*  %asi   stxa	\ %i4
   %i5   %g1   5 /n*  %asi   stxa	\ %i5
   %i6   %g1   6 /n*  %asi   stxa	\ %i6
   %i7   %g1   7 /n*  %asi   stxa	\ %i7

   %g1   8 /n*  %g1    add

   %g4  rdcwp  %g4 1  %g3  sub  %g3 0 wrcwp

   begin

      %l0   %g1   0  /n*  %asi    stxa		\ %l0
      %l1   %g1   1  /n*  %asi    stxa		\ %l1
      %l2   %g1   2  /n*  %asi    stxa		\ %l2
      %l3   %g1   3  /n*  %asi    stxa		\ %l3
      %l4   %g1   4  /n*  %asi    stxa		\ %l4
      %l5   %g1   5  /n*  %asi    stxa		\ %l5
      %l6   %g1   6  /n*  %asi    stxa		\ %l6
      %l7   %g1   7  /n*  %asi    stxa		\ %l7

      %g1   8 /n*    %g1    add

      %i0   %g1   0  /n*  %asi    stxa		\ %i0
      %i1   %g1   1  /n*  %asi    stxa		\ %i1
      %i2   %g1   2  /n*  %asi    stxa		\ %i2
      %i3   %g1   3  /n*  %asi    stxa		\ %i3
      %i4   %g1   4  /n*  %asi    stxa		\ %i4
      %i5   %g1   5  /n*  %asi    stxa		\ %i5
      %i6   %g1   6  /n*  %asi    stxa		\ %i6
      %i7   %g1   7  /n*  %asi    stxa		\ %i7

      %g3  1   %g3  sub
      %g3  0        wrcwp
      %g3           rdcwp
      %g4  %g3 %g0  subcc

   =  until  %g1  8 /n*  %g1  add

   %g7	%l0	move
   %g6  %o7     move	\ restore return address

   \ Save GL=1 Globals
   %g0 1 wrgl

   %g0   %l0 offset-of %a0 %asi  stxa
   %g1   %l0 offset-of %a1 %asi  stxa
   %g2   %l0 offset-of %a2 %asi  stxa
   %g3   %l0 offset-of %a3 %asi  stxa
   %g4   %l0 offset-of %a4 %asi  stxa
   %g5   %l0 offset-of %a5 %asi  stxa
   %g6   %l0 offset-of %a6 %asi  stxa
   %g7   %l0 offset-of %a7 %asi  stxa

   \ Save GL=0 Globals

   %g0 0 wrgl

   %g0   %l0 offset-of %g0 %asi  stxa
   %g1   %l0 offset-of %g1 %asi  stxa
   %g2   %l0 offset-of %g2 %asi  stxa
   %g3   %l0 offset-of %g3 %asi  stxa
   %g4   %l0 offset-of %g4 %asi  stxa
   %g5   %l0 offset-of %g5 %asi  stxa
   %g6   %l0 offset-of %g6 %asi  stxa
   %g7   %l0 offset-of %g7 %asi  stxa

   %g0   1  %g1  sub 
   %g1  %l0 offset-of %state-valid     %asi  stxa

   %g0 7 wrcleanwin    %g0 0 wrotherwin
   %g0 0 wrwstate      %g0 0 wrcwp
   %g0 0 wrcanrestore  %g0 6 wrcansave

   %l0	%o0	move			\ %o0 contains cpu struct ptr
   %o7 8  %g0  jmpl  nop
end-code
