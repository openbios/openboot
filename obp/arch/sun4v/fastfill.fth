\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fastfill.fth
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
id: @(#)fastfill.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

code touch-memory ( pa.lo pa.hi size -- )
   sp				sc1	pop		\ pa.hi in sc1
   sp				scr	pop		\ pa.lo in scr
   begin
      tos  /x			tos	subcc
      scr  tos memory-asi	sc2	ldxa
   0= until
      sc2  scr tos memory-asi		stxa
   sp  tos				pop
   #Sync				membar
c;

headerless

code (clear-memory ( pa.lo pa.hi size -- )
   sp				sc1	pop
   sp				scr	pop
   tos  h# 40			tos	subcc
   %g0  memory-asi			wrasi
   begin
      scr  tos			sc1	add
      %g0  sc1 h#  0 %asi		stxa
      %g0  sc1 h#  8 %asi		stxa
      %g0  sc1 h# 10 %asi		stxa
      %g0  sc1 h# 18 %asi		stxa
      %g0  sc1 h# 20 %asi		stxa
      %g0  sc1 h# 28 %asi		stxa
      %g0  sc1 h# 30 %asi		stxa
      %g0  sc1 h# 38 %asi		stxa
   0<= until
      tos  h# 40		tos	subcc
  sp				tos	pop
c;

code hv-mem-scrub ( pa 0 len -- )
   %o0			%l0	move
   %o1			%l1	move
   %o5			%l2	move
   sp			%l3	pop
   sp			%l3	pop
   %g0  h# 31		%o5	add		\ mem_scrub
   begin
      tos		%o1	move		\ Len
      %l3		%o0	move		\ RA
      %g0  0		always	htrapif
      %l3  %o1		%l3	add
      tos  %o1		tos	subcc
   0<= until
     %g0  h# 31		%o5	add		\ (mem scrub) delay
   %l2			%o5	move
   %l1			%o1	move
   %l0			%o0	move
   sp			tos	pop
c;

headers

defer clear-memory
alias bclear-memory-4MB clear-memory

' hv-mem-scrub  to clear-memory
' hv-mem-scrub  to clear-mem

headerless
