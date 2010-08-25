\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fieldberr.fth
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
id: @(#)fieldberr.fth 1.14 03/08/20
purpose: 
copyright: Copyright 1999-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ This code is actually two pieces, the guarded execute landing pad is one of
\ them, the os/stand/probe.fth is the other. probe.fth puts sync membars around
\ the load and store operators to ensure that the error happens exactly where
\ we expect it.
\ 
\ This means it is possible to break the guarded-execute protection by simply
\ 
\	['] x! guarded-execute
\ 
\ However there is little we can do about that. Instead do not re-invent
\ the wheel - use the peek and poke routines which will do the correct thing
\ and will not sacrifice performance.
\ 
\ Landing-pad can be considered the FORTH equivalent of setjmp/longjmp.
\ 
\ The first time that landing-pad executes is does the setjmp and returns 0,
\ code that takes an exception will restart at landing pad with a non-zero
\ value on the stack (longjmp) and this time the throw will prevent the acf
\ from being re-executed.
\ 

headerless

h# 30 constant trap30 \ Data Access Exception
h# 1f constant trap1f \ Level 15 interrupt
h# 32 constant trap32 \ Data Access Error
h# 34 constant trap34 \ Memory Address not Aligned

label simple-handler 

   prom-main-task  %g4  up	setx		\ Set User Area Pointer
   base				rdpc		\ this is a trap so we're
   here 4 - origin - %g4	set		\ using alternate globals
   base  %g4         base	sub

   %g6				rdpstate	\ save the tstate & pstate
   %g7				rdtstate	\ then set trap-level to 0
   %g0	0			wrtl		\ so that we can field an mmu
						\ miss on the cpu-struct
   up	%g4		%g5	get-cpu-struct	
   0	>guarded-pc	%g4	set		\ retrieve the "landing-pad" pc
   %g5	%g4		%g5	add		\ value previously stored
   %g0	%g5		%g4	nget		\ in the >guarded-pc member

   %g0	%g4		%g0	subcc		\ is the guarded-pc nonzero?
   0<>	if
				nop		\ delay
      %g0	1		wrtl		\ set trap-level = 1
      %g6	0		wrpstate	\ restore pstate
      #sync			membar
      %g7	0		wrtstate	\ restore tstate
      #sync			membar
      %g0	%g4		wrtpc
      %g0	%g4		wrtnpc		\ set trap pcs to "landing pad"
      %g0	%g0	%g5	nput		\ clear saved pc
				retry		\ retry (to landing pad) will
   else						\ set trap level to 0
				nop
      %g0	h# 16		wrpstate	\ another (unrecoverable) trap
      save-state always		brif		\ set pstate to known state
				nop		\ and jump into save-state
   then
end-code

code landing-pad  ( -- executed? )
   h# 20			.align
   up	sc2		sc1	get-cpu-struct	\ sc1 = cpu-struct adr
   0	>guarded-pc	sc2	set		\ "landing-pad" pc container
   0	>guarded-ip	sc3	set		\ "landing-pad" ip container
   sc1	sc2		sc2	add		\ sc2 = guarded-pc adr
   sc1	sc3		sc3	add		\ sc3 = guarded-ip adr
   %g0	sc2		sc1	nget		\ sc1 = guarded-pc value
   ip	%g0		sc3	nput		\ store current ip
   sc4				rdpc		
   sc4	h# 10		sc4	add		\ sc4 = after never1
   never if					\ never1 (LANDING PAD)
      sc4	%g0	sc2	nput		\ (delay) store guarded pc
      up	sc1	sc2	get-cpu-struct	\ This code path is only taken
      0	>guarded-ip	sc1	set		\ on a retry from simple-handl
      sc2	sc1	sc2	add		\ 
      %g0	sc2	sc1	nget		\ sc1 = "guarded-ip"

      %g0	sc1	ip	add		\ restore the previously
      #sync			membar		\ stored ip so the code
      scr	sc1		clear-afsr	\ continues from landing-pad
      #sync			membar		\ rather than where the trap
      tos	sp		push		\ was encountered.
      %g0	h# bed	tos	add		\ mark error (this will then 
   else						\ be "thrown" back to 
				nop		\ guarded-execute
      tos	sp		push
      %g0	0	tos	add		\ first time through mark as 0
   then						\ so it won't be thrown
c;

: safe-guard  ( acf -- ?? )
    landing-pad throw execute
;

: newguarded-execute  ( ?? acf -- succeeded?-flag )
   trap30  vector@ >r		   ( acf )	( R: t30 )	
   trap1f  vector@ >r		   ( acf )	( R: t30 t1f )
   trap32  vector@ >r		   ( acf )	( R: t30 t1f t32 )
   trap34  vector@ >r		   ( acf )	( R: t30 t1f t32 )

				   \ replace with "safe" trap handler

   simple-handler trap30  vector!  ( acf )	( R: t30 t1f t32 t34 )
   simple-handler trap1f  vector!  ( acf )	( R: t30 t1f t32 t34 )
   simple-handler trap32  vector!  ( acf )	( R: t30 t1f t32 t34 )
   simple-handler trap34  vector!  ( acf )	( R: t30 t1f t32 t34 )

				   \ if %lsucr is changed upon fielding one of 
				   \ these traps flush the caches and restore 
				   \ the lsucr

   cpu-error-enable@ >r
   berr-on
   lsucr@ >r			   ( acf )	  ( R: t30 t1f t32 t34 lsucr )
   ['] safe-guard catch dup if	   ( 0 | acf -1 ) ( R: t30 t1f t32 t34 lsucr )
      nip			   ( -1 )	  ( R: t30 t1f t32 t34 lsucr )
   then 0=			   ( flag )	  ( R: t30 t1f t32 t34 lsucr )
   r> dup lsucr@ <> if		   ( flag lsucr ) ( R: t30 t1f t32 t34 )
      cache-off clear-cache lsucr! ( flag )	  ( R: t30 t1f t32 t34 )
   else				   ( flag lsucr ) ( R: t30 t1f t32 t34 )
      drop			   ( flag )	  ( R: t30 t1f t32 t34 )
   then
   r> cpu-error-enable!		   \ restore the original trap handlers

   r> trap34  vector!		   ( flag )	  ( R: t30 t1f t32 )
   r> trap32  vector!		   ( flag )	  ( R: t30 t1f )
   r> trap1f  vector!		   ( flag )	  ( R: t30 )
   r> trap30  vector!		   ( flag )	  ( R: )
;


 ' newguarded-execute is guarded-execute

headers
overload: scan-subtree ( dev-addr,len action-acf -- )
   ['] scan-subtree guarded-execute drop
;
