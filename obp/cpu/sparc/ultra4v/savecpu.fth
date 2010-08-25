\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: savecpu.fth
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
id: @(#)savecpu.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

transient
also assembler definitions
: save-reg ( reg offset -- ) \ where?
   postpone offset-of %asi    stxa
;
: load-reg ( area reg -- ) \ where?
   >r postpone offset-of %asi r> ldxa
;
: write-reg ( reg area offset -- )	%asi stxa  ;
: read-reg ( area offset reg -- )	>r %asi r> ldxa  ;
previous definitions
resident

headers
\ %g5 = save area
\ %g4 = <exit type>
\     = 0, restore, retry
\     = 1, restore, done
\     else, restore, jmpl %g7
\
label restore-cpu-state ( -- )
   %g0 memory-asi			wrasi
   %g5 %g1 load-reg %cwp	%g1  0	wrcwp		\ EARLY!!!
   %g5				%l5	move
   %g4				%l4	move
   %g7				%l7	move

   %g0 2				wrtl
   %l5 %g1 load-reg %tpc-2	%g1 0	wrtpc
   %l5 %g1 load-reg %tnpc-2	%g1 0	wrtnpc
   %l5 %g1 load-reg %tstate-2	%g1 0	wrtstate
   %l5 %g1 load-reg %tt-2	%g1 0	wrtt

   %g0 1				wrtl
   %l5 %g1 load-reg %tpc-1	%g1 0	wrtpc
   %l5 %g1 load-reg %tnpc-1	%g1 0	wrtnpc
   %l5 %g1 load-reg %tstate-1	%g1 0	wrtstate
   %l5 %g1 load-reg %tt-1	%g1 0	wrtt

   \ Now restore original state..
   %l5 %g1 load-reg %tl-c	%g1 0	cmp		\ TL=0??
   0=					if
      %g1  0				wrtl		\ Restore
      %g0  1				wrtl		\ Force to 1.
   then
   %l5 %g1 load-reg %pc		%g1  0	wrtpc
   %l5 %g1 load-reg %npc	%g1  0	wrtnpc
   %l5 %g1 load-reg %tstate-c	%g1  0	wrtstate
   %l5 %g1 load-reg %y		%g1  0	wry
   %l5 %g1 load-reg %pil	%g1  0	wrpil
   %l5 %g1 load-reg %cansave	%g1  0	wrcansave
   %l5 %g1 load-reg %canrestore	%g1  0	wrcanrestore
   %l5 %g1 load-reg %cleanwin	%g1  0	wrcleanwin
   %l5 %g1 load-reg %otherwin	%g1  0	wrotherwin
   %l5 %g1 load-reg %wstate	%g1  0	wrwstate
   %l5 %g1 load-reg %fprs	%g1  0	wrfprs

[ifdef] SUN4V
   %g0  0  wrgl	    8 0 do  %l5  offset-of %g0 i /x* + %g0 i +  read-reg  loop
   %g0  1  wrgl	    8 0 do  %l5  offset-of %a0 i /x* + %g0 i +  read-reg  loop
   %g0  2				wrgl
[then]

   %l5				%g5	move
   %l4				%g4	move
   %l7				%g7	move

   \ Restore locals, Ins Outs
   \ Address of window regs.
   %l5  window-registers	%g6	add
   8 0 do  %g6	i /x*	%o0 i +		read-reg	loop	\ %o0-%o7
   %g6  8 /n*			%g6	add

   %g5  %g1				load-reg full-save?
   %g1				%g0	cmp
   0<> if
      nop
      %g5  %g1				load-reg %pcontext
      %g0  h# 08		%g2	add
      %g1  %g0  %g2  h# 21		stxa
      %g5  %g1				load-reg %scontext
      %g0  h# 10		%g2	add
      %g1  %g0  %g2 h# 21 		stxa
      #sync				membar
      %g5  %g1				load-reg %tba
      %g1  0				wrtba

      \ recover how many we saved
      %g5  %g1				load-reg %nwins
      %g2				rdcwp
      begin
	 %g2  0				wrcwp
         8 0 do  %g6  i  /x* %l0 i +	read-reg	loop \ %l0-%l7
	 %g6  8 /n*		%g6	add
	 8 0 do  %g6  i  /x* %i0 i +	read-reg	loop \ %i0-%i7
	 %g6  8 /n*		%g6	add
         %g2  1			%g2	sub
         %g2  0				wrcwp
	 %g1  1			%g1	subcc
      0= until
         %g2				rdcwp
      %g5  %g1				load-reg %cwp
      %g1  0				wrcwp
   else
      nop
      8 0 do  %g6  i /x* %l0 i +	read-reg	loop	\ %l0-%l7
      %g6  8 /n*		%g6	add
      8 0 do  %g6  i /x* %i0  i +	read-reg	loop	\ %i0-%i7
      %g6  8 /n*		%g6	add
   then

   %g4				%g0	cmp
   0<>					if
      %g4  1				cmp
      0=				if
         nop
	 done
      then
      \ copy the state we destroy into TL=2 equivs.
      %g0  1				wrtl
      %g7  4			%g7	add
      %g7  0				wrtpc
      %g7  4			%g7	add
      %g7  0				wrtnpc
   then
   retry
end-code

\ In: any GL
\   %g4 = <preserved>
\   %g5 = save area
\   %g6	= full_save?
\   %g7 = pc to jump to after save, cwp=0, gl=0, tl=0, ie=1
\
\   %g1 trashed
\   %g2 trashed
\   %g3 trashed
\   %g6 trashed once used
\
\ Out: GL=0, run (%g7)
\
label save-cpu-state ( -- )
   %g0  memory-asi			wrasi
   %g1  rdtl		%g1  %g5	save-reg %tl-c
   %g1  rdtpc		%g1  %g5	save-reg %tpc-c
			%g1  %g5	save-reg %pc
   %g1  rdtnpc		%g1  %g5	save-reg %tnpc-c
			%g1  %g5	save-reg %npc
   %g1  rdtstate	%g1  %g5	save-reg %tstate-c
   %g1  rdy		%g1  %g5	save-reg %y
   %g1  rdpil		%g1  %g5	save-reg %pil
   %g1	rdcwp		%g1  %g5	save-reg %cwp
   %g1	rdcansave	%g1  %g5	save-reg %cansave
   %g1	rdcanrestore	%g1  %g5	save-reg %canrestore
   %g1	rdcleanwin	%g1  %g5	save-reg %cleanwin
   %g1	rdotherwin	%g1  %g5	save-reg %otherwin
   %g1	rdwstate	%g1  %g5	save-reg %wstate
   %g1	rdfprs		%g1  %g5	save-reg %fprs
			%g6  %g5	save-reg full-save?
[ifdef] SUN4V
   %g1  rdgl		%g1  %g5	save-reg %gl
[then]
   %g1  rdtt		%g1  %g5	save-reg %tt-c

   %g0  2				wrtl
   %g1  rdtpc		%g1  %g5	save-reg %tpc-2
   %g1  rdtnpc		%g1  %g5	save-reg %tnpc-2
   %g1  rdtstate	%g1  %g5	save-reg %tstate-2
   %g1  rdtt		%g1  %g5	save-reg %tt-2

   %g0  1				wrtl
   %g1  rdtpc		%g1  %g5	save-reg %tpc-1
   %g1  rdtnpc		%g1  %g5	save-reg %tnpc-1
   %g1  rdtstate	%g1  %g5	save-reg %tstate-1
   %g1  rdtt		%g1  %g5	save-reg %tt-1

   \ Address of window regs.
   %g5  window-registers	%g6	add
   8 0 do  %o0 i +	%g6	i /x*	write-reg	loop	\ %o0-%o7
   %g6  8 /n*			%g6	add

   \ Full save or partial?
   %g5	%g1				load-reg full-save?
   %g1  %g0				cmp
   0<>					if
      %g1				rdtba
      %g1  %g5				save-reg %tba
      %g0  h# 08		%g2	add
      %g0  %g2 h# 21		%g1	ldxa
      %g1  %g5				save-reg %pcontext
      %g0  h# 10		%g1	add
      %g0  %g1  h# 21		%g1	ldxa
      %g1  %g5				save-reg %scontext
      %g0  %g0 %g2 h# 21 		stxa	\ Set Primary context to 0
      #sync				membar

      \ Rebuild %PSTATE, %CCR, %ASI from %TSTATE and save them
      %g1  rdtstate
      %g1  d# 08		%g2	sll
      %g2  d# 16		%g2	srl
      %g2  %g5				save-reg %pstate
      %g1  d# 63 d# 39 -	%g2	sllx
      %g2  d# 32		%g2	srlx
      %g2  %g5				save-reg %ccr
      %g1  d# 24		%g2	srl
      %g2  %g5				save-reg %asi

      %g2				rdcwp
      %g2			%g3	move
      %g0			%g1	move
      begin
         %g3  0				wrcwp
         8 0  do  %l0 i +	%g6 i /x* write-reg	loop	\ %l0-%l7
	 %g6  8 /n*		%g6	add
	 8 0  do  %i0 i +	%g6 i /x* write-reg	loop	\ %i0-%i7

	 %g3  1			%g3	sub
	 %g3  0				wrcwp
	 %g3				rdcwp
	 %g2  %g3		%g0	subcc
	 %g1  1			%g1	add
      =  until
         %g6  8 /n*		%g6	add
      %g1  %g5				save-reg %nwins		\ How many?
   else
      nop
      8 0 do  %l0 i +	%g6	i /x*	write-reg	loop	\ %l0-%l7
      %g6  8 /n*		%g6	add
      8 0 do  %i0  i +	%g6	i /x*	write-reg	loop	\ %i0-%i7
      %g6  8 /n*		%g6	add
   then

   %g5 %g1 load-reg %cwp	%g1  0	wrcwp
   %g4				%l4	move
   %g5				%l5	move
   %g7				%l7	move

[ifdef] SUN4V
   \ Save current GLs
   %g0	1  wrgl	 8 0 do	%g0 i + %l5  offset-of %a0 i /x* + write-reg  loop
   %g0	0  wrgl	 8 0 do	%g0 i + %l5  offset-of %g0 i /x* + write-reg  loop
[then]

   %g1					rdpstate
   %g1  2			%g1	andn
   %g1  0				wrpstate
   %l7	4			%g0	jmpl
   %g0				0	wrtl
end-code

\ %l0 = stack base
\ %l4 = TOS (VA)
\ %l7 = IP to run
label setup-small-forth-engine
   prom-main-task	%g5	up	setx		\ Set User Pointer
   up  sp	     		%g1	get-cpu-struct
   %g1  %l0			%g1	add		\ CPU Save Area VA
   %g1 /min-cpu-save		%g1	add
   %g1 /fth-exception-stack	sp	add		\ Data Stack set
   %g1 /fth-exception-stack 2/	rp	add
   rombase			base	set		\ set base
   %l7	base			ip	add
   %l4				tos	move		\ VA
   next
end-code

[ifdef] WOULD-BE-NICE-TO-HAVE-HERE
\ 
\ We cant put this here because it has a fwd ref to save state
\ we also depends upon this code. So its [ifdef]d out and left for
\ reference.
\

\ %gl = 2
\ %g1 is the structure offset
label small-forth-save-state
   \ OK, we have to switch to the original fault-tl and tpc, tnpc
   \ we got here from the restore which does a retry at tl=1 having
   \ setup the tpc, tnpc to 'return', everything else should be restored
   %g0  2				wrtl
   %g0  h# 38			%g2	add
   %g2  %g0  h# 20		%g5	ldxa	\ CPU struct PA
   %g5  %g1			%g5	add	\ CPU save area
   %g7					rdasi
   %g0  memory-asi			wrasi
   %g5  %g1				load-reg %tpc-1
   %g5  %g2				load-reg %tnpc-1
   %g5	%g3				load-reg %tl-c
   %g0  1				wrtl
   %g0  %g1				wrtpc
   %g0	%g2				wrtnpc
   %g0	%g7				wrasi
   save-state			always	brif
   %g0  %g3				wrtl   
end-code
[then]
