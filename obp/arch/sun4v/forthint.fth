\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: forthint.fth
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
id: @(#)forthint.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 value tick-ival

code interrupt-return  ( abort? -- )
   tos				%l1	move
   h# 4000			%g1	set
   %g1  0			%r21	wrasr		\ Clear SOFT INT. Reg
   #Sync				membar

   h# 10001			%g4	set		\ STICK | TICK
   %r22				%g1	rdasr
   %g1  %g4			%g0	andcc
   0<>  if
      nop
      h# 10001			%g4	set		\ STICK | TICK
      %g4  0			%r21	wrasr		\ Clear
      #Sync				membar

      \ Only re-arm alarms if we arent aborted.
      %l1			%g0	cmp
      0=				if
         'user# tick-ival	%g4	set
         %g4  up		%g4	nget		\ Get interval incr
         %r24			%g7	rdasr		\ get Stick
         %g7  1			%g7	sllx
         %g7  1			%g7	srlx
         %g7  %g4		%g7	add
         %g7  %g0		%r25	wrasr		\ Set StickCompare
         #Sync				membar
      then
   then

   %g0  h# 38			%l5	add
   %l5  %g0  h# 20		%l5	ldxa		\ CPU struct PA
   0 >intr-state		%l0	set
   %l0  %l5			%g5	add		\ CPU save area
   %l1	%g0				cmp
   restore-cpu-state		0=	brif		\ Not aborted resume
   %g0				%g4	move

   %g0  2			%g4	add		\ restore and cont.
   restore-cpu-state		always	brif
   %g7					rdpc

   %g0  2				wrgl		\ ok goto savestate
   0 >intr-state		%g1	set
   small-forth-save-state	always	brif
					nop
c;

: interrupt-handler
   my-self >r				\ XXX Need this??
   check-alarm
   r> is my-self			\ XXX Need this??
   aborted? @ interrupt-return
;

label interrupt-preamble
   %g0  h# 38			%g1	add
   %g1  %g0  h# 20		%g1	ldxa		\ CPU struct PA
   0 >intr-state		%g5	set
   %g5  %g1			%g5	add		\ DMMU stacks
   %g0				%g6	move		\ Small Save
   save-cpu-state		always	brif
   %g7					rdpc

   \ We are now in a normal TL=0, IE=1, CWP=0 environment
   \ Set up Forth Machine
   0 >intr-state		%l0	set
   'body interrupt-handler	%l7	set
   setup-small-forth-engine	always	brif	nop
c;

: set-next-tick ( -- )
   system-tick-speed d# 100 /  dup  to  tick-ival
   stick@ -1 1 >> and + stick-compare!
;
' set-next-tick is rearm-alarms

: install-nmi  ( -- )
   d# 15 pil!
   lock[
      set-next-tick
      interrupt-preamble h# 4e vector!
   ]unlock
   d# 13 pil!
;

stand-init: Installing Simple Ticker
   init-alarm-list
   install-nmi
;

: memory-warning ( request-size -- adr actual-size false | error true )
   ." Rejecting alloc-mem!"
   drop 0 true
;

headers

cif: SUNW,heartbeat ( msecs -- abort? )
   check-alarm  aborted? @ 0<>
;

headerless

: set-trap-table ( [mmu-area-ra] virt -- )
   lock[

   swap set-cpu-miss-area

   \ Save current %pstate and %pil
   pstate@ >r  pil@  >r

   \ Stop the L14 Timer
   1 d# 63 << stick-compare!	( virt )

   \ Clear Soft Interrupts
   -1 clear-softint!		( virt )

   \ Set New %TBA
   tba!  ]unlock

   \ we don't permit more dynamic allocation.
   [']  memory-warning  is more-memory

   \ Client has now officially "taken over"
   true to obp-control-relinquished?

   \ Restore previous %pil and %pstate
   r> pil! r> pstate!
;

headers

cif: SUNW,sun4v-set-trap-table ( [mmu-area-ra] virt -- ) set-trap-table ;
cif: SUNW,set-trap-table ( [mmu-area-ra] virt -- ) set-trap-table ;
