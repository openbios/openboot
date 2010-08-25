\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fpu9.fth
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
id: @(#)fpu9.fth 1.6 04/04/15 19:10:00
purpose: 
copyright: Copyright 1999-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
code freg@  ( freg# -- value )	\ @ freg & store in tos.
   tos 2        tos   sll       \ freg# * 4 in tos
   tos          sp    push	\ Make room on the stack
   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      %f0    sp /l   stf   %f1    sp /l   stf
      %f2    sp /l   stf   %f3    sp /l   stf
      %f4    sp /l   stf   %f5    sp /l   stf
      %f6    sp /l   stf   %f7    sp /l   stf
      %f8    sp /l   stf   %f9    sp /l   stf
      %f10   sp /l   stf   %f11   sp /l   stf
      %f12   sp /l   stf   %f13   sp /l   stf
      %f14   sp /l   stf   %f15   sp /l   stf
      %f16   sp /l   stf   %f17   sp /l   stf
      %f18   sp /l   stf   %f19   sp /l   stf
      %f20   sp /l   stf   %f21   sp /l   stf
      %f22   sp /l   stf   %f23   sp /l   stf
      %f24   sp /l   stf   %f25   sp /l   stf
      %f26   sp /l   stf   %f27   sp /l   stf
      %f28   sp /l   stf   %f29   sp /l   stf
      %f30   sp /l   stf   %f31   sp /l   stf
   then
   sp         tos   pop
c;

code freg!  ( value freg# --  ) \ @ freg & store in tos.
   tos 2        tos   sll       \ freg# * 4 in tos

   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      sp /l    %f0   ldf   sp /l    %f1   ldf
      sp /l    %f2   ldf   sp /l    %f3   ldf
      sp /l    %f4   ldf   sp /l    %f5   ldf
      sp /l    %f6   ldf   sp /l    %f7   ldf
      sp /l    %f8   ldf   sp /l    %f9   ldf
      sp /l    %f10  ldf   sp /l    %f11  ldf
      sp /l    %f12  ldf   sp /l    %f13  ldf
      sp /l    %f14  ldf   sp /l    %f15  ldf
      sp /l    %f16  ldf   sp /l    %f17  ldf
      sp /l    %f18  ldf   sp /l    %f19  ldf
      sp /l    %f20  ldf   sp /l    %f21  ldf
      sp /l    %f22  ldf   sp /l    %f23  ldf
      sp /l    %f24  ldf   sp /l    %f25  ldf
      sp /l    %f26  ldf   sp /l    %f27  ldf
      sp /l    %f28  ldf   sp /l    %f29  ldf
      sp /l    %f30  ldf   sp /l    %f31  ldf
   then
   sp       tos   pop
   sp       tos   pop
c;

code dfreg@  ( freg# -- value )	\ @ freg & store in tos.
   tos  1      tos    sll

   tos          sp    push	\ Make room on the stack
   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      %f0    sp 0   stdf   %f2    sp 0   stdf
      %f4    sp 0   stdf   %f6    sp 0   stdf
      %f8    sp 0   stdf   %f10   sp 0   stdf
      %f12   sp 0   stdf   %f14   sp 0   stdf
      %f16   sp 0   stdf   %f18   sp 0   stdf
      %f20   sp 0   stdf   %f22   sp 0   stdf
      %f24   sp 0   stdf   %f26   sp 0   stdf
      %f28   sp 0   stdf   %f30   sp 0   stdf
      %f32   sp 0   stdf   %f34   sp 0   stdf
      %f36   sp 0   stdf   %f38   sp 0   stdf
      %f40   sp 0   stdf   %f42   sp 0   stdf
      %f44   sp 0   stdf   %f46   sp 0   stdf
      %f48   sp 0   stdf   %f50   sp 0   stdf
      %f52   sp 0   stdf   %f54   sp 0   stdf
      %f56   sp 0   stdf   %f58   sp 0   stdf
      %f60   sp 0   stdf   %f62   sp 0   stdf
   then
   sp       tos   pop
c;

code dfreg!  ( value freg# --  ) \ @ freg & store in tos.
   tos 1        tos   sll       \ freg# * 2 in tos

   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      sp 0    %f0   lddf   sp 0    %f2   lddf
      sp 0    %f4   lddf   sp 0    %f6   lddf
      sp 0    %f8   lddf   sp 0    %f10  lddf
      sp 0    %f12  lddf   sp 0    %f14  lddf
      sp 0    %f16  lddf   sp 0    %f18  lddf
      sp 0    %f20  lddf   sp 0    %f22  lddf
      sp 0    %f24  lddf   sp 0    %f26  lddf
      sp 0    %f28  lddf   sp 0    %f30  lddf
      sp 0    %f32  lddf   sp 0    %f34  lddf
      sp 0    %f36  lddf   sp 0    %f38  lddf
      sp 0    %f40  lddf   sp 0    %f42  lddf
      sp 0    %f44  lddf   sp 0    %f46  lddf
      sp 0    %f48  lddf   sp 0    %f50  lddf
      sp 0    %f52  lddf   sp 0    %f54  lddf
      sp 0    %f56  lddf   sp 0    %f58  lddf
      sp 0    %f60  lddf   sp 0    %f62  lddf
   then
   sp       tos   pop
   sp       tos   pop
c;

code qfreg@  ( freg# -- lo hi )	\ @ freg & store in tos.
   tos          sp    push	\ Make room on the stack
   tos          sp    push	\ Make room on the stack
   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      %f0    sp 0   stqf   %f4    sp 0   stqf
      %f8    sp 0   stqf   %f12   sp 0   stqf
      %f16   sp 0   stqf   %f20   sp 0   stqf
      %f24   sp 0   stqf   %f28   sp 0   stqf
      %f32   sp 0   stqf   %f36   sp 0   stqf
      %f40   sp 0   stqf   %f44   sp 0   stqf
      %f48   sp 0   stqf   %f52   sp 0   stqf
      %f56   sp 0   stqf   %f60   sp 0   stqf
   then
   sp       tos   pop
c;

code qfreg!  ( lo hi freg# --  ) \ @ freg & store in tos.

   here 4 +           call      \ Address of call instruction in spc
   5 /l*        sc1   move      \ Distance to jump table - 5 instructions
   spc sc1      sc1   add       \ Absolute address of jump table
   sc1 tos      %g0   jmpl      \ Jump to the instruction

   never  if                     \ Skip past table in delay slot
      sp 0    %f0   ldqf   sp 0    %f4   ldqf
      sp 0    %f8   ldqf   sp 0    %f12  ldqf
      sp 0    %f16  ldqf   sp 0    %f20  ldqf
      sp 0    %f24  ldqf   sp 0    %f28  ldqf
      sp 0    %f32  ldqf   sp 0    %f36  ldqf
      sp 0    %f40  ldqf   sp 0    %f44  ldqf
      sp 0    %f48  ldqf   sp 0    %f50  ldqf
      sp 0    %f54  ldqf   sp 0    %f60  ldqf
   then
   sp       tos   pop
   sp       tos   pop
   sp       tos   pop
c;

code fsr@  ( -- fsr_value )
   tos        sp      push
   tos        sp      push
   sp 0               stxfsr
   sp         tos     pop
c;

code fsr!  ( fsr-value -- )
   tos        sp      push
   sp 0               ldxfsr
   sp         tos     pop
   sp         tos     pop
c;

headerless
: .#fregs  ( freg# -- )     (.d) 2 over - spaces ." +" type ." :" ;
: .fregs   ( freg# n -- )   bounds  ?do  i  freg@ n->l  .lx     loop  cr  ;
: .dfregs  ( freg# n -- )   bounds  ?do  i dfreg@ space .nx  2 +loop  cr  ;

headers
: fpu-enable ( -- )
   pstate@ h# 10 or pstate!  4 fprs!
;

: fpu-disable ( -- )
   pstate@ h# 10 invert and pstate!
   fprs@ 4 invert and fprs!
;

: fpu-enabled? ( -- flag )
   pstate@ h# 10 and 0<> fprs@ 4 and 0<> and
;

: .fregisters	( -- )
   fpu-enabled? 0= if ." FP disabled" exit then
   4 spaces  8  0  do i .lx loop  cr
   d# 64  d# 32
   dup 0 do  i .#fregs i 8  .fregs  8 +loop
         do  i .#fregs i 8 .dfregs  8 +loop
;

stand-init: Enable FPU
   fpu-enable
;
