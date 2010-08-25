\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hslave.fth
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
id: @(#)hslave.fth 1.1 06/02/22
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

label start-slave-cpus
   \ Turn OFF everything except for PRIV bit in %pstate

   %g0  h# f			wrpil
   %g0  4			wrpstate
   %i0		      %g1	move
   %i1		      %g2	move
   %g0  0			wrtba
   \ XXX %g0  0		%r22	wrasr	\ Clear SoftInt Reg.
   %g0  7			wrcleanwin
   %g0  0			wrotherwin
   %g0  0			wrwstate
   %g0  0			wrcanrestore
   %g0  6			wrcansave
   %g0  0			wrcwp
   %g1			%i0	move
   %g2			%i1	move
   %g0  0			wrtl	\ TL = 0
   %g0  0                       wrgl

   %g0  h# 16		%o5	add
   %g0  0 always		htrapif
   %g0  h# 20			wrasi
   %o1  %g0 h# 08  %asi		stxa	\ MID in scratchpad1

   %i1			%o1	move	\ Size of Memory
   setup-i/d-tlbs		call
   %i0			%o0	move	\ Base of Memory

   \ ick ick
   \ need a PA, so we reverse engineer one
   \ this needs to move to 'reset'..
   mmu-info >mmu-miss-pa rombase + 4meg 1- land %o0 set \ relative to start
   %i0  %o0 memory-asi	%o0	ldxa	\ PA
   %o1				get-mid
   %o1  /mmu-miss-area log2 %o1	sllx
   %o0  %o1		%o0	add
   %g0  h# 30		%o1	add
   %o0  %g0  %o1 h# 20		stxa	\ Scratch6, MISS AREA PA
   mmu-miss-area-func#	%o5	set
   %g0 fast-trap# always	htrapif	\ set it

   \ Set the base register
   ROMbase              base    set

   \ Set %tba register
   base			%g0	wrtba

   %g0 1                %o0  add	\ MMU On
   %g0 mmu-on-off-func# %o5  add
   here origin - 	%g4  set
   base  %g4		%g4  add
   %g4 h# 18            %o1  add	\ Return PC
   %g0 fast-trap#    always  htrapif
   nop

   \ Set up register
   prom-main-task	up	set

   release-slaves? origin- scr set
   scr  base		scr	add
   scr  %g0		sc2	ld
   begin
      sc2  %g0	%g0	subcc
   0<> until
      scr  %g0	sc2	ld

   scr			rdpstate
   scr  h# 16	scr	or
   scr  0			wrpstate

   \ can clear post-run magic in %i5
   %g0		%i5	move

   \ Enter the initial idle loop
   slave-init		always brif
   nop
end-code

1 4 h# 10 0 hypercall: hyper-startcpu
: idle-slaves ( -- )
   0 tba@ >physical drop		( 0 tba )
   start-slave-cpus origin- over +	( 0 tba pc )
   max-#cpus 0  do			( 0 tba pc )
      mid@ i <>  if			( 0 tba pc )
         0 i >cpu-struct >cpu-status !	( 0 tba pc )
         3dup i hyper-startcpu		( 0 tba pc status )
	 0= if				( 0 tba pc status )
	    get-msecs d# 100 + begin
	       get-msecs over <
	       i >cpu-struct >cpu-status @ 0= and
	       while 1 ms 
	    repeat drop
	 then				( 0 tba pc )
      then				( 0 tba pc )
   loop	 3drop				(  )
;

stand-init: Kicking slave CPU(s) into idle loop
   init-per-cpu-data
   ['] init-per-cpu-data is slave-idle-loop-hook
   idle-slaves
;

headers
