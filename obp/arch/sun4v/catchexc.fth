\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: catchexc.fth
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
id: @(#)catchexc.fth 1.3 06/04/19
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

headers

\ TODO
\ The allocation of the cpu structs really should be on a page boundary
\

transient
0 value save-fstate
resident

chain: enterforth-chain
   \ put stuff to do on entry in this chain.
;
defer enterforth-hook ' enterforth-chain is enterforth-hook

: enterforth  ( -- )

   enterforth-hook

   init-cpu-state

   \ Clear any pending L15 Interrupts
   last-trap# h# 4f =  if  1 h# 0f lshift clear-softint!  then

   ?secure  handle-breakpoint
;

code slave-bp-loop ( -- )
   scr				rdpstate	\ We should not be spinning in
   #sync			membar		\ this loop with IE = 0
   scr  2		scr	or		\ set IE = 1
   scr  0			wrpstate
   #sync			membar
   up	sc1		sc2	get-cpu-struct
   0 >cpu-status	sc1	set
   CPU-PARKED		scr	move
   scr		sc2	sc1	stx		\ Mark as Parked

   \ Wait here until we are restarted OR the master CPU advances us
   \ into the wait for lockfree phase
   CPU-ENTERFORTH	scr	move
   begin
      sc2	sc1	sc3	ldx
      sc3	scr	%g0	subcc
   0=  until	nop
   scr	sc2		sc1	stx		\ Mark as waiting to enter

   sc3	sc4 sc5		sc6	mutex-enter  prom-lock

   CPU-OBP-WARM		scr	move
   scr	sc2		sc1	stx		\ Mark as waiting to enter

   'body enterforth	ip	set
   ip  base		ip	add
c;

\itc : slave-bp-loop slave-bp-loop ;

label save-state
   %g0  h# 38			%g4	add
   %g4  %g0  h# 20		%g5	ldxa		\ CPU struct PA
   %g0  memory-asi			wrasi

   %g7	rdtt  %g7  %g5			save-reg last-trap#
   %g5  %g1				load-reg error-reset-trap
   %g1  0				cmp
   <>					if
     nop
     \ Last trap is one of reset
     \ non-zero Indicates Error Reset
     %g1 %g5				save-reg last-trap#
     %g0 1			%g1	sub
     %g1 %g5				save-reg error-reset-trap
   then

   %g5  %g1				load-reg %state-valid
   %g1				%g0	cmp
   %g1  1			%g1	sub
   0=  if
      %g1  %g5				save-reg %state-valid

      %g0  1			%g6	add		\ Full state save
      %g5			%g4	move		\ CPU struct in %g4
      save-cpu-state		always	brif
      %g7				rdpc

      \ Cannot rely upon %g's across save-cpu-state!!
      %g0  h# 38		%g4	add
      %g4  %g0  h# 20		%g4	ldxa		\ CPU struct PA
      %g0  memory-asi			wrasi

      0 >stack-fence?		%g1	set
      %g0  %g4  %g1  memory-asi		stxa		\ Stack Fence Off

      \ %o's are saved, it is now safe to make hcalls
      \ if the size is 0 we skip the tsb save 
      \ Preserve the TSB Areas, and disable TSBs
      0 >cpu-tsb-ctrl-area	%g7	set
      %g4  %g7			%g7	add		\ TSB ctrl base
      %g7  0 >tsb-allocation	%o0	read-reg	\ sizeof tsb ctx0 area
      %o0  %g0			%g0	subcc
      0<>  if
         %g7  0 >tsb-buffer-addr %o1	read-reg	\ TSB CTX0 - RA
         %g0  h# 29		%o5	add		\ MMU_TSB_CTX0INFO
         %g0  h# 80		always	htrapif
         %o0  %g0		%g0	subcc
	 0= if
	    %g0  %g7 0 >tsb-saved-size	write-reg	\ 0 as size (delay)
	    %o1  %g7 0 >tsb-saved-size	write-reg	\ Save actual size
            %g0			%o1	move		\ %o0 is already 0...
            %g0  h# 20		%o5	add		\ MMU_TSB_CTX0
	    %g0  h# 80		always	htrapif
         then
      then
      %g7  /tsb-data >tsb-allocation %o0 read-reg	\ sizeof tsb ctxX area
      %o0  %g0			%g0	subcc
      0<> if
	 %g7  /tsb-data >tsb-buffer-addr %o1 read-reg	\ TSB CTXNON0 - RA
	 %g0  h# 2a		%o5	add		\ MMU_TSB_CTXNON0INFO
	 %g0  h# 80		always	htrapif
         %o0  %g0		%g0	subcc
	 0= if
	    %g0  %g7 /tsb-data >tsb-saved-size	write-reg \ 0 as size (delay)
	    %o1  %g7 /tsb-data >tsb-saved-size	write-reg \ Save actual size
	    %g0			%o1	move		\ %o0 is already 0...
	    %g0  h# 21		%o5	add		\ MMU_TSB_CTXNON0
	    %g0  h# 80		always	htrapif
         then
      then
   else  nop
      %g0  0		wrtl
      %g0  0		wrgl
   then

   trap-table			%g4	set
   %g4  0				wrtba

   \ OK we go virtual from here on

   prom-main-task		up	set
   rombase			base	set
   up  %g4			%g1	get-cpu-struct

   %g1  offset-of last-trap#	scr	ldx
   scr	h# 17f			%g0	subcc	\ Breakpoint!
   0= if nop
      \ turn off watchdog
      %g0  0		%o0	add		\ timeout value
      %g0  h# 5		%o5	add		\ func # (WD)
      %g0  h# 80		always	htrapif
   then

   \ %g1 = cpu-state
   \ up = User area pointer
   \ base = Origin
   \ Save address of this location for later
   here  to  save-fstate

   \ Setup the SP and RP here
   \ we install a fence on the existing sp, rp IF:
   \  1. The PC is inside the PROM
   \  2. Primary Context is 0
   \  3. We have not hit a breakpoint.
   \  4. This is the first time we have done this.
   \
   %g1  offset-of %state-valid	sc5	ldx	\ Per CPU state-valid Lock
   %g1  offset-of %pcontext	scr	ldx	\ get primary context
   scr  %g0			%g0	subcc
   0=  if
      %g1  offset-of last-trap#	scr	ldx
      scr	h# 17f		%g0	subcc	\ Breakpoint!
      0<> if nop
         %g1	offset-of %pc	scr	ldx	\ get PC
         scr	d# 28		scr	srax
         scr	h# f		%g0	subcc	\ inside OBP space?
         0= if
            sc5			-1	cmp	\ State Valid = -1?
            0=  if  nop
               0 >stack-fence?	scr	set
               %g0	1	sc3	sub
               sc3	%g1	scr	stx	\ mark fence as active
            then
         then
      then
   then

   0 >stack-fence?		scr	set
   %g1	scr			scr	ldx
   scr				-1	cmp
   0= if  nop
      0 >return-stack h# 40 /n* + scr	set
      %g1  scr			rp	add	\ END of RS
      0 >cpu-rp0-fence		scr	set
      rp	%g1		scr	stx	\ Mark rs stackbase
      0 >data-stack h# 40 /n* +	scr	set
      %g1 scr			sp	add	\ END of SP
      0 >cpu-sp0-fence		scr	set
      sp	%g1		scr	stx	\ Mark ds stackbase
   else  nop
      %g1			rp	get-rp0
      %g1			sp	get-sp0
   then

   \ Check State Valid again
   sc5				-1	cmp
   0=  if
      nop

      'user my-self             scr	nget
      scr  %g1 offset-of %saved-my-self  stx

      \ User Area	(we only need to save the first few locations)
      0 >user-save		scr	set
      %g1	scr		scr	add	\ Address of save area
      up			sc1	move	\ Bottom of user area
      ua-size			sc2	move	\ Size of user area
      begin
	 sc2	/n		sc2	subcc
	 sc1	sc2		sc3	ldx
      0= until
         sc3	scr		sc2	stx	\ Delay slot

   then

   \ Account for the presence of the top of stack register
   sp /n   sp   add

\dtc 'acf enterforth	scr	set
\itc 'body enterforth	scr	set
   sc4				get-mid
   sc1		sc2	sc3	mutex-try-enter prom-lock
   sc1			-1	cmp
   0<> if
      sc4		sc1	cmp
      0<> if			nop

         \ Initialize the Interpreter Pointer
\dtc     'acf slave-bp-loop	scr   set
\itc     'body slave-bp-loop	scr   set
      then
   then
   scr  base  ip  add

   %g0  h# 0f  wrpil	\ PIL=15

   \ We don't want to enable interrupts on CPUs that are in the middle
   \ of taking an error reset until later when we have idled all the
   \ other CPUs via cross calls.
   %g1 offset-of error-reset-trap   scr   ldx
   scr -1 cmp
   = if nop
      %g0  h# 14  wrpstate	\ PEF=1, PRIV=1
   else nop
      %g0  h# 16  wrpstate	\ PEF=1, PRIV=1, IE=1
   then

   \ Initialize the Window Registers & Stack Pointer

   %g0 7 wrcleanwin
   %g0 0 wrotherwin
   %g0 0 wrwstate
   %g0 0 wrcanrestore
   %g0 6 wrcansave
   %g0 0 wrcwp

   %g1  window-registers  %g4  add
   %g4  6 /n*             %o6  ldx
   %o6  1   %g0  andcc
   0=  if  nop
      %o6 /entry-frame %o6  save
      %o6  V9_SP_BIAS  %o6  sub
   then

\itc next
\dtc ip	%g0		%g0	jmpl  nop
end-code

\
\ XXX this really belongs in savecpu.fth, to match the small startup
\ FWD refs prevent that working though.
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

label slave-save-state
   \ Set the base register
   base                    rdpc
   here 4 - origin - %g4   set
   base  %g4         base  sub

   save-state origin-  %g1  set
   %g2 %g1   %g0 jmpl  nop
end-code


label save-RED-state
   %g0  0		wrtl
   %g0  0		wrgl
   prom-main-task  %g4  up    setx	\ Set User Area Pointer

   \ Set the base register
   base                    rdpc
   here 4 - origin - %g4   set
   base  %g4         base  sub

   up  %g4  %g1  get-cpu-struct

   \ %g1 = Base of cpu-state array
   \ %g2 = origin       (base)
   \ %g3 = User Pointer (up)
   \ AG=0, MG=0, VG=0
   \ TL=0

   %g4  1  %g4  sub
   %g4  %g1 offset-of %state-valid  stx
   %g0  2			%g4	add
   %g4  %g1 offset-of error-reset-trap	stx

   'user my-self                  %g4  nget
   %g4  %g1  offset-of %saved-my-self  stx

   \ Continue with save-state
   save-fstate always brif nop
end-code

label (crestart)
   up  %g2			%g7	get-cpu-struct
   CPU-STARTED  %g1 %g6		%g7	mark-cpu-state

   \ After this point we are PHYSICAL access
   \ PSTATE.IE = 0, Tl=2, GL=2
   %g0	2				wrtl
   %g0  2				wrgl
   %g0  memory-asi			wrasi
   %g4					rdpstate
   %g4  2			%g4	andn
   %g4  0				wrpstate

   %g0  h# 38			%g4	add
   %g4  %g0  h# 20		%g5	ldxa		\ CPU struct PA

   %g0  1			%g1	sub
   %g0  %g5				save-reg last-trap#
   %g0  %g5				save-reg %state-valid
   %g1  %g5				save-reg %restartable?

   \ restore the TSB areas
   0 >cpu-tsb-ctrl-area		%g1	set
   %g5  %g1			%g1	add		\ control block
   %g1  0 >tsb-saved-size	%o0	read-reg	\ sizeof tsb ctx0 area
   %o0  %g0			%g0	subcc
   0<>  if
      %g1  0 >tsb-buffer-addr	%o1	read-reg	\ TSB CTX0 - RA
      %g0  h# 20		%o5	add		\ MMU_TSB_CTX0
      %g0  h# 80		always	htrapif
   then
   %g1  /tsb-data >tsb-saved-size %o0	read-reg
   %o0  %g0			%g0	subcc
   0<>  if
      %g1  /tsb-data >tsb-buffer-addr %o1 read-reg	\ TSB CTXNON0 - RA
      %g0  h# 21		%o5	add		\ MMU_TSB_CTXNON0
      %g0  h# 80		always	htrapif
   then

   \ restore dev mondo queue
   0 >cpu-devmondo-ptr		%g1	set
   %g5  %g1			%g1	add		\ target PA
   %g1  0			%g4	read-reg	\ get saved value
   %g4  %g0			%g0	subcc
   0<					if
      %g4  1			%g4	sllx		\ (delay)
      %g4  1			%g4	srlx		\ restore
      %g0  h# 25			wrasi
      %g4  %g0 h# 3d0 %asi		stxa		\ restore original idx
      %g0  %g1  0			write-reg	\ mark as done
   then

   restore-cpu-state		always	brif
   %g0	0			%g4	add		\ retry!
end-code

code (crestart ( -- )
   up  sc2  sc1  get-cpu-struct
   scr sc1 sc2  mutex-exit  prom-lock
   (crestart)  call  nop
c;

code  wait-for-lock-free ( -- )
   up	sc1		sc4	get-cpu-struct
   CPU-WAIT-RESTART scr sc1 sc4	mark-cpu-state
   scr	sc1 sc2		sc3	mutex-enter  prom-lock
   CPU-OBP-WARM scr sc1	sc4	mark-cpu-state
c;

: restart-slave ( -- )  wait-for-lock-free  restart ;

code (restart-step ( -- )
  nop nop
  (crestart)  call
  nop nop
c;

' (restart-step is restart-step

headers
also hidden definitions
vocabulary trap-types
: .tt ( n -- ) base @ >r hex <# u# u# u# u#> r> base ! type space  ;
: trap" ( trap# n -- ) \ name  description"
   create  swap w, 1- w, ,"
   does>
      ??cr dup w@ over wa1+ w@  ( apf tt n )
      bounds  2dup -  if
	 .tt ." ... " .tt
      else
	 drop .tt
      then  la1+  ". space
;
hex
also trap-types definitions
100 80 trap" tt-100 Trap Instruction (Ticc)"
 e0 20 trap" tt-0e0 Fill Other   0 - 7"
 c0 20 trap" tt-0c0 Fill Normal  0 - 7"
 a0 20 trap" tt-0a0 Spill Other  0 - 7"
 80 20 trap" tt-080 Spill Normal 0 - 7"
 70  1 trap" tt-070 Fast ECC Error"
 6c  4 trap" tt-06c Fast Data Access Protection"
 68  4 trap" tt-068 Fast Data Access MMU Miss"
 64  4 trap" tt-064 Fast Instruction Access MMU Miss"
 63  1 trap" tt-063 Corrected ECC Error"
 62  1 trap" tt-062 VA Watchpoint"
 61  1 trap" tt-061 PA Watchpoint"
 60  1 trap" tt-060 Interrupt Vector"
 41  f trap" tt-041 Interrupt Level 1 - 15"
 37  1 trap" tt-037 Privileged Action"
 36  1 trap" tt-036 STDF Memory Address not Aligned"
 35  1 trap" tt-035 LDDF Memory Address not Aligned"
 34  1 trap" tt-034 Memory Address not Aligned"
 32  1 trap" tt-032 Data Access Error"
 31  1 trap" tt-031 TSB Data Miss"
 30  1 trap" tt-030 Data Access Exception"
 28  1 trap" tt-028 Division by Zero"
 24  4 trap" tt-024 Clean Window"
 23  1 trap" tt-023 TAG Overflow"
 22  1 trap" tt-022 FP Exception Other"
 21  1 trap" tt-021 FP Exception IEEE 754"
 20  1 trap" tt-020 FP Disabled"
 11  1 trap" tt-011 Privileged Opcode"
 10  1 trap" tt-010 Illegal Instruction"
  a  1 trap" tt-00a Instruction Access Error"
  9  1 trap" tt-009 TSB Instruction MISS"
  8  1 trap" tt-008 Instruction Access Exception"
  5  1 trap" tt-005 RED State Exception"
  4  1 trap" tt-004 Software Initiated Reset"
  3  1 trap" tt-003 Externally Initiated Reset"
  2  1 trap" tt-002 Watchdog Reset"
  1  1 trap" tt-001 Power On Reset"

previous previous definitions

: .traps ( -- )
   [ also hidden ] 0 ['] trap-types [ previous ]
   begin  another-word?  while  ( alf' voc-acf anf )
      name> execute  exit?  if  2drop  exit  then
   repeat
;

: (last-trap) ( -- ?? fmt$ )
   last-trap#  dup h# 100 <  if                    ( tt )
      dup h# 41 h# 4f between  if                  ( tt )
	 h# 40 - " Level %d Interrupt"		   ( n fmt$ )
	 exit                                      (  )
      then                                         ( tt )
      dup h# 80 >=  if                             ( tt )
	 dup  h# 9f <=  if                         ( tt )
	    h# 80 - 2 >> " Spill %d Normal"	   ( n fmt$ )
	    exit                                   (  )
	 then                                      ( tt )
	 dup h# bf <=  if                          ( tt )
	    h# a0 - 2 >> " Spill %d Other"	   ( n fmt$ )
	    exit                                   (  )
	 then                                      ( tt )
	 dup  h# 0df <=  if                        ( tt )
	    h# c0 - 2 >> " Fill %d Normal"	   ( n fmt$ )
	    exit
	 then                                      ( tt )
	 dup h# ff <=  if                          ( tt )
	    h# e0 - 2 >> " Fill %d Other"	   ( n fmt$ )
	    exit                                   (  )
	 then                                      ( tt )
      then                                         ( tt )
      >r 0                                         ( alf ) ( r: tt )
      [ also hidden ] ['] trap-types [ previous ]  ( alf vacf ) ( r: tt )
      begin another-word?  while                   ( alf' vacf anf ) ( r: tt )
	 name> >body  dup w@  r@  =  if            ( alf' vacf apf ) ( r: tt )
            nip nip				   ( apf )
	    la1+ count  " %s" r> drop exit	   ( str$ fmt$ )
	 else                                      ( alf' vacf apf ) ( r: tt )
	    drop                                   ( alf' vacf ) ( r: tt )
	 then                                      ( alf' vacf ) ( r: tt )
      repeat r> drop                               (  )
      " "					   ( null$ )
   else                                            ( tt )
      h# 100 -  " Trap %x"			   ( n fmt$ )
   then                                            (  )
;

: .last-trap ( -- )
   (last-trap) ?dup if
      cmn-error[ " Last Trap: " cmn-append ]cmn-end
   else
      drop
   then
;

headerless

: (do-last-trap)
   last-trap# 0= last-trap# h# 60 = or if exit then

  obp-control-relinquished? if
      [ also cmn-messaging ]
      current-frame$ @ >r 0 current-frame$ !
      .last-trap
      r> current-frame$ !
      [ previous ]
   else
      .last-trap
      state-valid off

\      -256 throw	\ Do not un-comment this throw.
\
\ (Comment derived from sun4u/catchexc.fth)
\ The above throw is meant to be caught by some outer intelligent catch
\ that knows how to handle the -256 error code.  There is no such catch,
\ and even if there were, this throw would first be intercepted by one of
\ the MANY badly behaving catches in the source tree, who then drive
\ on without first examining the error code.
\
\ Instead, fall through to caller (breakpoint-message), which falls into
\ quit and takes us back to the ok prompt.
\
\ The below code flushes the common messaging buffer, so we don't lose any
\ pending error messages before we get to the ok prompt.

      [ also cmn-messaging ]
      begin  current-frame$ @  while  " " ]cmn-end  repeat
      [ previous ]

   then
;

' false is breakpoint-trap?
' (do-last-trap) is .exception

stand-init: Install .exception and enable errors
   ['] (do-last-trap) is .exception
   enable-cpu-errors
;
headers

