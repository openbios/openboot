\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: slavecpu.fth
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
id: @(#)slavecpu.fth 1.14 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


code slave-enterforth ( -- )
	up   rp              scr     get-cpu-struct  \ rp is temp reg here
	scr			rp	get-rp0

	scr sc1 sc2 sc3 mutex-enter prom-lock

\dtc	'acf enterforth	ip	set
\itc	'body enterforth  ip    set
	ip   base         ip    add
\itc	next
\dtc	ip  %g0		%g0	jmpl	nop
c;

code slave-idle-loop
	\ base = origin
	\ up   = User Area Pointer
	\ The User Area is now initialized
	scr		        rdpstate	\ We should not be spinning in 	
	#sync			membar		\ this loop with IE = 0
	scr  2		scr	or		\ set IE = 1
	scr  0			wrpstate
	#sync			membar
	up   sc1	scr     get-cpu-struct	\ scr has cpu-struct-ptr
	scr		rp	get-rp0

	0 >cpu-status	sc1	set
	CPU-IDLING	sc2	move
	sc2	scr	sc1	stx		\ Mark as Idle

	sc3  sc4  sc5		mutex-exit  prom-lock

	CPU-ENTERFORTH	sc2	move
	begin
	   scr	sc1	sc3	ldx
	   sc3	sc2	%g0	subcc
	0=  until	nop
	sc2	scr	sc1	stx		\ Mark as waiting to enter

	sc3 sc4 sc5 sc6		mutex-enter prom-lock

	CPU-OBP-COLD	sc2	move
	sc2	scr	sc1	stx		\ Mark as COLD

\dtc	'acf enterforth	ip	set
\itc	'body enterforth ip	set
	ip	base	ip	add
\itc	next
\dtc	ip  %g0		%g0	jmpl	nop
c;

headerless
defer slave-idle-loop-hook  ( -- )  ' noop is slave-idle-loop-hook
: (slave-idle-loop)
   flush-temporary-mappings
   slave-idle-loop-hook
   enable-cpu-errors
   mid@ enable-reentry
   slave-idle-loop
;

\
\ Setup the per cpu rp0, sp0 pointers just the once.
\ Don't make this a : definition because we don't
\ have stacks yet!!
\
label slave-init
	up  sc1 scr			get-cpu-struct
	CPU-INIT sc1 sc2 scr		mark-cpu-state
	scr  sc1 sc2			set-rp0
	scr  sc1 sc2			set-sp0

[ifndef] SUN4V
	0 >cpu-version-reg	sc3	set
	sc2				rdver
	sc2  scr		sc3	stx		\ save CPU version
[then]

	scr			sp	get-sp0
	scr			rp	get-rp0
	sp	/n		sp	add		\ account for TOS

	'body (slave-idle-loop) ip	set
	ip  base		ip	add
	next
end-code

code do-release-prom ( who? acf -- )
\dtc	tos	ip			move
\itc	tos	sc1			move
	sp	tos			pop
	tos	sc2			move
	sp	tos			pop
	sc2	sc3			mutex-set  prom-lock
\dtc	ip	%g0		%g0	jmpl	nop
\itc    sc1	%g0		scr	rtget
\itc	scr	base		%g0	jmpl	nop
	\ Not Reached
c;

: master-release-prom ( n -- )
   dup >cpu-struct >cpu-status dup @  if		( n adr )
      CPU-ENTERFORTH swap !				( n )
      cpu-state >cpu-status @				( n status )
      CPU-OBP-WARM =  if				( n )
         ['] slave-bp-loop				( n )
      else						( n )
         ['] slave-idle-loop				( n acf )
      then						( n acf )
      do-release-prom					( )
   else							( n adr )
      2drop ." CPU Not ready" cr
   then
;

headers

