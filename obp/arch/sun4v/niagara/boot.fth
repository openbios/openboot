\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: boot.fth
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
id: @(#)boot.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
fload ${BP}/arch/sun/forthinit.fth

h# 1346780a constant reboot-magic

overload: stand-init-io  ( -- )
   \ fpu-enable
   stand-init-io
   install-uart-io
   diag-cr  " console initialized" diag-type  diag-cr
   control Q emit
   ['] noop         ['] bye    (is
;

headers

label prom-cold-code  ( -- )

   \ Turn OFF everything except for PRIV bit in %pstate

   %g0  h# f			wrpil
   %g0  4			wrpstate
   %i0			%g1	move
   %i1			%g2	move
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
   %g0  0		always	htrapif
   %g0  h# 20			wrasi
   %o1  %g0 h# 08	%asi	stxa	\ MID in scratchpad1

   ROMbase		%g1	set
   %g1  %o0		%o1	add
   %o1  %g0  %g0 h# 20		stxa		\ SCRATCH0!

   \ Set the base register
   ROMbase              base    set

   \ Set %tba register
   base			%g0	wrtba

   \ Base and size of at least one chunk of memory
   4meg			%o0	set
   %i1  %o0		%i7	sub	\ Size of unused memory
   %i0  %o0		%i6	add	\ Base of unused memory
   
   \ Set up register
   prom-main-task	up	set

   %i6		%o0	move	\ Base of memory
   %i7		%o1	move	\ Size of memory
   init-forth-environment	call
   %g0  1		%o2	sub	\ Use standard layout

   %i6	%i7		%i7	add	\ Memtop
   'user# physmax	%i6	set
   %i7  up		%i6	nput	\ Set the physmax (memory HWM)
   
   \ clear post-run magic in %i5
   %g0		%i5	move

   \ Enter Forth
   'body cold	ip	set
   ip  base		ip	add
   next
end-code

headers
: patchboot  ( -- )
   prom-main-task ['] main-task >body !
   \ Save the  text-size ( start of initial user area image ) @ origin + 4
   align  here origin - origin 4 +  l!
;

h# 001 begin-trap	\ Power-On/reset
( 01 )  nop \ dont use this instruction
( 02 )  nop \ or this one
( 03 )  nop \ or even this one
( 04 )  nop \ cleanup patches these with image information
( 05 )  prom-cold-code always brif
( 06 )  nop
( 07 )  nop
( 08 )  nop
h# 002 end-trap

h# 002 begin-trap       \ Watchdog
( 01 )  save-RED-state always   brif
( 02 )  nop
( 03 )  nop
( 04 )  nop
( 05 )  nop
( 06 )  nop
( 07 )  nop
( 08 )  nop
h# 003 end-trap

h# 003 begin-trap       \ XIR
( 01 )  save-RED-state always  brif
( 02 )  nop
( 03 )  nop
( 04 )  nop
( 05 )  nop
( 06 )  nop
( 07 )  nop
( 08 )  nop
h# 004 end-trap

h# 004 begin-trap       \ SIR entry point
( 01 )  save-RED-state always   brif
( 02 )  nop
( 03 )  nop
( 04 )  nop
( 05 )  nop
( 06 )  nop
( 07 )  nop
( 08 )  nop
h# 005 end-trap

h# 005 begin-trap       \ RED-mode entry point
( 01 )  save-RED-state always   brif
( 02 )  nop
( 03 )  nop
( 04 )  nop
( 05 )  nop
( 06 )  nop
( 07 )  nop
( 08 )  nop
h# 006 end-trap

