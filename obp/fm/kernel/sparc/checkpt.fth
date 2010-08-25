\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: checkpt.fth
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
id: @(#)checkpt.fth 1.4 05/04/08 22:16:13
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Checkpt
\ 
\ a checkpt is like a setjmp/longjmp in C. (man setjmp)
\ 
\ push-checkpt : Create an exception frame and push it onto the exception 
\                stack

\ pop-checkpt :  Dispose the current exception frame.
\
\ The catch and throw are special cases of checkpts.
\
\ One of the difference between a push-checkpt and a 'catch' is that 
\ the catch calls the thing it is trying to catch, a checkpoint does 
\ not have this restriction.  Looking at the tail end of 'catch' in 
\ the normal execution case it pops the handler, which is the exact 
\ equivalent of 'pop-checkpt'.
\
\ The primary difference is that you can mark a checkpoint at an arbitrary 
\ point and 'recover' much like a 'catch' does except that you are no 
\ longer on the same descending call frame (e.g., return stack).
\
\ So, consider
\ 	: xxx cmn-error[ ..-1 throw ... ]cmn-end ;
\       : yyy ['] xxx catch ;
\
\ The throw destroys the error frame by returning control to the 'catch'.
\
\ Now if cmn-error[ was implemented:
\
\ 	: (]cmn-end) ... ;
\ 	: cmn-error[
\ 	   push-checkpt ?dup if
\ 		" [truncated]" (]cmn-end)
\ 		throw
\          else
\		<start the message>
\          then
\  	;
\
\	: ]cmn-end (]cmn-end) pop-checkpt ;
\
\ What we have done is ensure that an error inside an error message 
\ frame is constrained in a recoverable manner and the original 'throw' 
\ is propogated to the catch in yyy.
\
\ The magic is that 'cmn-error[' returned to its caller normally and the 
\ caller xxx drove on, but on ERROR the code jumped back into the cmn-error[ 
\ routine which then had to throw. If it had not then the '-1 throw' would 
\ execute again (assuming no other disasterous stack effects).
\ 
\ To be a good citizen you should only 'recover' from an error and
\ not propogate a throw if you know that the throw code is yours (as
\ in the example).
\ 
\ In general it is bad practice to return from the routine that
\ established the check point (ie the routine that called 'push-checkpt'),
\ though a maximum unnest of /check-stack stack elements will permit this
\ to work.
\
\    IT IS BEST *NOT* TO RETURN FROM THE CHECKPOINT FRAME;
\    THOUGH IT WILL WORK IN MANY CASES
\
\ This is a similar restriction to setjmp/longjmp in C.
\
\ Frame Starts		Frame Ends
\    push-checkpt	pop-checkpt, throw
\    catch		throw
\

headers
[ifdef] KERNEL
nuser checkpt				\ most recent checkpoint
nuser checkbase				\ frames
nuser checktrack			\ tracker
nuser checkalloc			\ counter
nuser checkmax				\ max frames
nuser checknested
also meta also definitions		\ setup metacompiler magic
[else]
variable checkpt
variable checkbase
variable checktrack
variable checkalloc
variable checkmax
variable checknested
[then]

[ifdef] miniforth?
h# 18 constant /check-max		\ max outstanding catch frames
[else]
h# 80 constant /check-max		\ frames alloc'd after dynamic heap
[then]
h# 10 constant /check-crit		\ frames alloc'd from critical heap
headerless
8 constant /check-stack			\ How many elements to preserve
					\ sized for known catch stack usage
struct
   /n     field >check-prev		\ previous frame
   /n	  field >check-ip		\ checkpt IP
   /n	  field >check-sp		\ checkpt DS pointer
   /n	  field >check-rp		\ checkpt RS pointer
   /l	  field >check-myself		\ my-self
   /l	  field >check-age
   /check-stack /n * field >check-ds	\ a chunk of the DS
   /check-stack /n * field >check-rs	\ a chunk of the RS
constant /check-frame

[ifdef] KERNEL
previous previous definitions			\ back to kernel

\ create the kernel side of these routines, using the structure
\ created in the host metacompiler to form the offsets.

: >check-prev	[ 0 >check-prev ] literal + ;
: >check-myself	[ 0 >check-myself ] literal + ;
: >check-age	[ 0 >check-age ] literal + ;

headers
0 value my-self
headerless
[then]

\ initial 16 frames are allocated from the critical heap
: init-checkpt
   checkpt off
   checkalloc off
   checknested off
   /check-crit checkmax !
   /check-crit dup alloc-mem dup checktrack !		( va )
   swap erase						( len va )
   /check-crit /check-frame * /n +			( sz )
   alloc-mem /n 1- + /n 1- invert and checkbase !	( )
;

\ dynamic heap is installed before we call into this so that the frame alloc
\ requirements can be satisfied by the expanded heap made available.
\ the alloc-mem calls will cause checkpt frames to be alloc/free'd due to 
\ calls to 'catch', relying on a coherent state in the checkpt variables,
\ so the expanded allocations must not be swapped in until after they complete.
\
: alloc-checkpt
   \ alloc max checktrack and copy critical heap checktrack
   checktrack @ >r r@ 				( oldt ) ( r: t )
   /check-max dup alloc-mem 	 		( oldt len newt )
   dup rot erase swap				( newt oldt )
   /check-crit bounds do i c@ over c! 1+ loop	( newt' )
   /check-crit -				( newt )

   \ alloc max checkpt frames and copy critical heap frames
   checkbase @ >r r@ tuck			( oldb newt oldb ) ( r: t b )
   /check-max /check-frame * /n +		( oldb newt oldb len )
   alloc-mem /n 1- + /n 1- invert and		( oldb newt oldb newb )
   swap /check-crit /check-frame * bounds	( oldb newt newb hi lo )
   2dup /check-frame + 2>r			( oldb newt newb hi lo )
   do i @ over ! na1+ /n +loop			( oldb newt newb' )
   /check-crit /check-frame * -			( oldb newt newb )

   \ having copied the old frames to the new now patch the >check-prev ptrs
   \ start at second frame of old and new frames as first frame has null ptr
   2 pick over /check-frame + 2r> do		( oldb newt newb oldb newb' )
      over i @ swap - 3 pick + over !		( oldb newt newb oldb newb'' )
   /check-frame + /check-frame +loop		( oldb newt newb oldb newb'' )
   2drop					( oldb newt newb )

   \ now swap in expanded frame allocations after fully initialized
   \ update checkpt to current frame in newly allocate frames
   checkbase ! checktrack !			( oldb )
   checkpt @ ?dup if				( oldb cur )
      swap - checkbase @ + checkpt !		( )
   else						( oldb )
      drop					( )
   then						( )
   /check-max checkmax !			( ) ( r: t b )

   r> /check-crit /check-frame * free-mem	( ) ( r: t )
   r> /check-crit free-mem			( )
;

\
\ returns false the first time it is called (by push-checkpt)
\ returns the throw code when the saved state is restored by restore-checkpt
\ so that push-checkpt can distinguish between the initial save and a throw
\ the saved IP will be the symbol after save-checkpt in push-checkpt
\ the top /check-stack elements of both stacks are preserved
\
code save-checkpt ( frame -- 0 )
   ip  tos 0 >check-ip	nput
   \ copy the data stack
   /check-stack /n* scr	move
   sp		sc1	move		\ saved SP
   rp		sc2	move		\ saved RP
   tos 0 >check-ds  sc3	add
   tos 0 >check-rs  sc4	add
   begin
      scr  /n	scr	subcc
      sp	sc5	pop
      sc5  sc3  scr	nput
      rp	sc6	pop
   0= until
      sc6  sc4	scr	nput

   sp tos 0 >check-sp	nput
   rp tos 0 >check-rp	nput

   sc1		sp	move		\ Restore SP
   sc2		rp	move		\ Restore RP

   %g0		tos	move
c;

\ This works by restoring the return and data stack pointers and
\ /check-stack worth of data from the last checkpt frame,
\ restoring the IP and then setting tos to the throw code.
\
\ the effect is to restart the execution at the symbol following the
\ save-checkpt call in push-checkpt.
\ 
code restore-checkpt ( code frame -- code )
   sp		   sc7	pop
   tos 0 >check-ip ip	nget
   tos 0 >check-sp sp	nget
   tos 0 >check-rp rp	nget

   /check-stack /n* scr	move
   tos 0 >check-ds  sc1	add
   tos 0 >check-rs  sc2	add
   %g0		sc3	move
   begin
      scr  /n	scr	subcc
      sc1  sc3	sc5	nget
      sc5	sp	push
      sc2  sc3	sc6	nget
      sc6	rp	push
   0= until
      sc3  /n	sc3	add

   sc7		tos	move
c;

\ 
\ We free 16 frames - and hope this is enough to go interactive again
\ may be useful to increase for debugging
\ we only get here if we ran out of frames
\ 
: free-oldest-frames ( -- )
   h# 10 0 do
     checkalloc @ 0 checkmax @ 0 ?do		( age n )
       over					( age n age )
       checkbase @ i /check-frame * +		( age n age ptr )
       >check-age l@				( age n age age-2 )
       tuck >					( age n age-2 old? )
       checktrack @ i + c@ 0<>			( age n age-2 old? used? )
       and if					( age n age-2 )
          nip nip i leave			( age' i )
       else					( age n age-2 )
          drop					( age n )
       then					( age' i )
     loop					( age n )
     checktrack @ + 0 swap c! drop		( )
   loop
;

\ We track individual allocs so that on an error (no more frames)
\ we can find the 'oldest' and try to reuse them. This will (hopefully)
\ give some insight into what the latest sequence of failures was.
\ 
: alloc-frame ( -- n )
   1 checkalloc +!				( )
   -1 checktrack @ checkmax @ bounds ?do 	( -1 )
      i c@ 0= if				( -1 )
         i c!					( )
         i checktrack @ - leave			( n )
      then					( n )
   loop						( n )
   dup 0< if
      free-oldest-frames			( )
      ." FATAL: no exception frames available, "
      checknested @ checknested on if
         ." NESTED ERRORs, going interactive" cr
         begin interact again
      else
         ." forcing misaligned trap" cr
         -1 @
      then
   then
   /check-frame * checkbase @ +			( n )
   checkalloc @ over >check-age l!		( n )
;

: free-frame ( ptr -- )
   0 swap checkbase @ - /check-frame / checktrack @ + c!
;

: (free-checkpt) ( frame -- )
   dup >check-prev @ checkpt !			( frame )
   free-frame					( )
;

headers

\ free all allocated frames. used to wipe out frames when reentering
\ obp (l1-a, halt, exception, etc). the allocated frames are stale and 
\ we prefer to begin with a complete set. otherwise, frames will
\ slowly leak as we exit/reenter forth (go, breakpoint, etc).
: reset-checkpts ( -- )
   checktrack @ checkmax @ erase
   checkpt off
;

\ Dispose the current exception frame.
\
: pop-checkpt ( -- ) checkpt @ ?dup if  (free-checkpt)  then ;

\ If a non-zero throw is done, then we unwind the current checkpoint
\
: throw ( n -- ) ?dup if  checkpt @ ?dup if  restore-checkpt  then  then ;

\
\ Create an exception frame and push it onto the exception stack
\
: push-checkpt ( ??? -- ??? code )
   alloc-frame >r				( ??? )
   checkpt @ r@ >check-prev !			( ??? )
   my-self r@ >check-myself l!			( ??? )
   r@ save-checkpt dup if			( ??? code )
      r>					( ??? code frame )
      dup >check-myself l@ is my-self		( ??? code frame )
      (free-checkpt)				( ??? code )
   else						( ??? 0 )
      r> checkpt !				( ??? 0 ) 
   then						( ??? code )
;

: catch ( ??? acf -- code )
   push-checkpt ?dup if
      nip
   else
      execute pop-checkpt 0
   then
;

chain: init
   init-checkpt
; 
