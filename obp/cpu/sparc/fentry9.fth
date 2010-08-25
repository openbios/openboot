\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fentry9.fth
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
id: @(#)fentry9.fth 1.8 02/12/11
copyright: Copyright 1991-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Processor-dependent code to establish the proper machine state when
\ Forth is called from C.  This is used by the "make-c-entry" routine
\ in makecentry.fth.  These files are separate because the "make-c-entry"
\ routine is a compilation word which is somewhat different between the
\ metacompiler environment and the native compilation environment.

\ The implementation might be easier if Forth used the local registers for
\ its pointers, instead of the global registers.  The outs could be
\ used for scratch registers instead of the locals.

decimal

headerless
code return-to-c  ( -- )
   tos     %i0  move		\ Return value (if any)

   \ We don't want to depend on the data
   \ stack pointer being the same, because
   \ the routine may have left a return value
   \ on the stack.
   %o6 V9_SP_BIAS d# 16 na+  sp   nget

   \ Restore these in case of multiple levels of cross-language calls;
   \ if the Forth word that was just executed called a C subroutine,
   \ then saved-sp and saved-rp could have been changed.

   sp   'user saved-sp  nput
   rp   'user saved-rp  nput

   \ Restore the Globals

   %o6 V9_SP_BIAS d# 17 na+  %g1  nget
   %o6 V9_SP_BIAS d# 18 na+  %g2  nget
   %o6 V9_SP_BIAS d# 19 na+  %g3  nget
   %o6 V9_SP_BIAS d# 20 na+  %g4  nget
   %o6 V9_SP_BIAS d# 21 na+  %g5  nget
   %o6 V9_SP_BIAS d# 22 na+  %g6  nget
   %o6 V9_SP_BIAS d# 23 na+  %g7  nget

   %i7 8     %g0  jmpl
   %g0 0     %g0  restore
end-code

\ This is used in only one place -- the implementation of the op_release
\ ROMvec entry.  It pops a call frame and returns to the caller's caller.
\ This is a special-purpose hack used to implement "kill a process from
\ it's childs stack"

code double-return-to-c  ( -- )

   \ We don't want to depend on the data
   \ stack pointer being the same, because
   \ the routine may have left a return value
   \ on the stack.
   %o6 V9_SP_BIAS d# 16 na+  sp   nget

   \ Restore these in case of multiple levels of cross-language calls;
   \ if the Forth word that was just executed called a C subroutine,
   \ then saved-sp and saved-rp could have been changed.

   sp   'user saved-sp  nput
   rp   'user saved-rp  nput

   \ Restore the Globals

   %o6 V9_SP_BIAS d# 17 na+  %g1  nget
   %o6 V9_SP_BIAS d# 18 na+  %g2  nget
   %o6 V9_SP_BIAS d# 19 na+  %g3  nget
   %o6 V9_SP_BIAS d# 20 na+  %g4  nget
   %o6 V9_SP_BIAS d# 21 na+  %g5  nget
   %o6 V9_SP_BIAS d# 22 na+  %g6  nget
   %o6 V9_SP_BIAS d# 23 na+  %g7  nget

   %g0 0     %g0  restore       \ Remove the caller's stack frame

   %i7 8     %g0  jmpl          \ Return to the caller's caller
   %g0 0     %g0  restore
end-code

\ We get here from a Forth C-entry stub, which in turn was called from a
\ C subroutine call.  The entry stub did a "save", then called forth-entry.
\ The IP will be set to the location following the delay slot of the call.
\ The "save" allocated enough space for saving the window registers (16 x 8),
\ plus the globals (8 x 8), plus space for 2 Forth stacks (64+64).

\ We have a fresh set of local registers as a result of the save.

\ The arguments are in the caller's "out" registers, which are our "in"
\ registers after we do the "save", which also gets us a fresh set of locals.
\
\ %o0 = UP
\ %o1 = BASE
\ %o2 = SP
\ %o3 = RP
\ %o4 = IP
label forth-entry

   \ Save the globals on the stack
   %g1   %o6 V9_SP_BIAS d# 17 na+  nput
   %g2   %o6 V9_SP_BIAS d# 18 na+  nput
   %g3   %o6 V9_SP_BIAS d# 19 na+  nput
   %g4   %o6 V9_SP_BIAS d# 20 na+  nput
   %g5   %o6 V9_SP_BIAS d# 21 na+  nput
   %g6   %o6 V9_SP_BIAS d# 22 na+  nput
   %g7   %o6 V9_SP_BIAS d# 23 na+  nput

   \ Establish a Forth execution environment by setting the values of
   \ the Forth virtual machine registers base, up, ip, rp, and sp.

   \ Set the interpret pointer to the word this Forth entry is to execute

[ifexist] saved-sp
   spc 8  ip  add

   \ Set the base register

   dictionary-size ( offset )
   here 8 +             call    \ address of next instruction in spc
   ( offset )     base  set     \ relative address of current instruction
   spc base       base  sub     \ subtract them to find the base address

   \ Set the user pointer

   'body main-task  tos  set	\ Allow the exception handler to find the
   base   tos       %o0  add
   %o0  6           sp   lduh	\ main user area in the "constant" main-task
   %o0  4           up   lduh	\ main user area in the "constant" main-task
   up  h# 10        up   sllx
   up   sp          up   or

   \ Set the stack pointers

   'user saved-sp   sp   nget	\ Establish the Return Stack
   sp	  %o6 V9_SP_BIAS d# 16 na+  nput	\ For restoring saved-sp upon return
   'user saved-rp   rp   nget	\ Establish the Parameter Stack
   rp	  %o6 V9_SP_BIAS d# 24 na+  nput	\ For restoring saved-rp upon return

   \ To make Forth re-entrant, we allocate space on the stacks in case
   \ Forth gets called again by an interrupt handler.

   sp h# 40 /n*     %l0  sub	\ Allocate some space on the Parameter Stack
   %l0   'user saved-sp  nput

   rp h# 40 /n*     %l0  sub	\ Allocate some space on the Return Stack
   %l0   'user saved-rp  nput
[else]
   %o0			up	move
   %o1			base	move
   %o2			sp	move
   %o3			rp	move
   %o4			ip	move
[then]

   \ Pass up to 6 subroutine arguments to Forth
   sp  5 /n*  sp  sub

   %i0   tos        move
   %i1   sp 0 /n*   nput
   %i2   sp 1 /n*   nput
   %i3   sp 2 /n*   nput
   %i4   sp 3 /n*   nput
   %i5   sp 4 /n*   nput

c;

\ Align adr so that the data segment will start at the right place.
\ Depending on the machine architecture, the Sun loader aligns the
\ data segment on a particular boundary.  For the SPARC, the alignment
\ boundary is a doubleword (8 bytes).
: align-data  ( adr -- aligned-adr )  7 +  -8  and  ;

d# 16 /n* ( window registers )  8 /n* ( global registers ) + /n + ( rp ) 
h# 40 round-up
negate constant /entry-frame

headers
