\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: reenter.fth
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
id: @(#)reenter.fth 1.19 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Ways to enter the Forth interpreter, and their implications:
\ a) Power up - no autoboot
\	Entry mechanism: prom-cold-code, which is entered from the boot-state
\	  reset vector, distinguished this from a watchdog reset by looking
\	  at the watchdog bit in the system error register.  prom-cold-code
\	  then initializes the machine and executes the Forth startup
\	  sequence.
\	Action: perform the startup initialization sequence, then boot
\	  the operating system if autoboot is specified in the configuration.
\	  Otherwise enter the text interpreter.
\ b) Power up - abort key
\	Action: Finish initialization procedure, but enter interpreter
\	  instead of autoboot
\ c) Breakpoint (= single step)
\	Entry mechanism: the trap table entry reads the psr into %l0 and
\	  jumps to save-state .  save-state saves %l0 into the error-reset-trap
\	  field of the cpu-state save area.
\	Signature: The trap type field of the saved tbr indicates the
\	  breakpoint trap vector, the error-reset-trap field of the cpu-state save
\	  area contains a valid psr value (as opposed to -1; see the
\	  "Error reset" case), and no other special conditions are present
\	  (see "exittomon", "abortent")
\	Action: perform the action indicated by the "handle-breakpoint"
\	  routine; usually disassembles the breakpointed instruction and
\	  enters the text interpreter
\ d) Error trap (e.g. Data Access Exception)
\	Entry mechanism: the trap table entry reads the psr into %l0 and
\	  jumps to save-state .  save-state saves %l0 into the error-reset-trap
\	  field of the cpu-state save area.
\	Signature: The trap type field of the saved tbr indicates the
\	  breakpoint trap vector, the error-reset-trap field of the cpu-state save
\	  area contains a valid psr value (as opposed to -1; see the
\	  "Error reset" case), and no other special conditions are present
\	  (see "exittomon", "abortent")
\	Action: display exception name and enter text interpreter
\ e) Exittomon - Return from Unix - don't expect to re-enter
\	Entry mechanism: sun4m/machdep.c:halt() calls romp->v_exit_to_mon,
\	  which resolves to reenter.fth:reenter .  "reenter" executes the
\	  breakpoint trap instruction, which proceeds as in the "breakpoint"
\	  case.
\	Signature: This looks almost like the "Breakpoint" case, and is
\	  distinguised from that case by the fact that the saved %pc value
\	  indicates the address of the trap instruction within the "reenter"
\	  routine.
\	Action: Display "Type 'go' to resume", then enter text interpreter
\	Problem: kadb may have usurped the breakpoint trap table entry
\	Idea: Maybe instead of start_mon_clock(), stop_mon_clock(), we should
\	  provide romvecs for this, or maybe the monitor should just do it
\	  automatically whenever the interpreter is entered or one of the
\	  the monitor's I/O routines (maybe just mayget) is called. (No, just
\	  mayget() is insufficient, because we could lose characters when
\	  scrolling the screen.
\	Note: Unix displays a message through the PROM's printf routine
\	  before calling romp->v_exit_to_mon.  The message depends on
\	  the reason for the halt:
\		"Halted"	Executed from sun4m/machdep.c:boot(), from
\				reboot system call entry (in os/kern_xxx.c),
\				but only if RB_HALT flag from the user's
\				parameters to the system call is set.
\				spl6() is performed before calling halt()
\		"bootflags"	The RB_HALT flag was set when Unix parsed the
\				boot flags.  Restartable.  spl6() NOT called
\				(Is that the right thing?)
\		"system map tables too large"
\				Unix has an internal configuration problem
\		"no memory"	Unix was too big for the available phys. memory
\
\	Note: Unix starts the monitor clock before calling romp->v_exit_to_mon
\	Note: Unix does not intend to be restarted in most cases, but
\	  in the "bootflags" case above, restarting is reasonable.
\	  Halt() remembers to stop the monitor clock if exit_to_mon returns.
\
\ f) Abortent - keyboard abort from Unix (L1-A or Break)  (continuable)
\	Entry mechanism: either sundev/zs_async.c or sundev/kbd.c calls
\	  sun4m/locore.s:montrap(romp->v_abortent), which then calls that
\	  abortent routine.  Currently, the abortent romvec resolves to
\	  reenter.fth:reeenter, the same as for "Exittomon"
\	Signature: Currently, this is indistinguishable from the "Exittomon"
\	  case, unless Forth is willing to dig around in the window registers
\	  to identify the "montrap()" return address (a silly way to do it;
\	  it would be easier to provide a separate "abort-reenter" routine).
\	Action: Currently the same as for "Exittomon"
\	Suggestion: the action should be similar to "L1-A when Forth running"
\	Note: if kadb is installed (Unix saw "-d" flag), kadb is entered
\	  instead of the monitor.
\	Note: Execution of Unix is frequently resumed after this kind of abort
\	Note: Unix does NOT start the monitor clock before calling
\	  romp->v_abortent
\
\ g) Bootme - return from Unix with auto-reboot
\	Entry mechanism: sun4m/machdep.c:boot(), which is called from the
\	  reboot system call code in os/kern_xxx.c.  boot() calls
\	  romp->v_boot_me, which calls a Forth entry resolving to
\	  bootparams.fth:boot-me
\	Note: Never returns to Unix; instead reboots the system
\	Note: Monitor clock has been started at spl6() (pil 13).
\	Note: Argument is a C string which is either "", "-s", or the argument
\	  to the reboot user command
\	Note: Doesn't enter the Forth text interpreter
\
\ h) Callvec - call Unix subroutine which then returns back to Forth
\	Entry mechanism: Forth calls a subroutine whose address has been
\	  exported by Unix.  That subroutine returns, reentering the
\	  Forth word (callvec or sync) from which it was called.
\	Note: Unix doesn't do anything to restore it's state.  Maybe this is
\	  wrong.  Perhaps Unix should be in charge of setting up its own
\	  stack, context, trap table, and interrupts again?
\	Note: This is usually executed after a keyboard abort or a watchdog.
\
\ i) fwritestr - terminal emulator called from Unix
\	Entry mechanism: Unix calls either "putchar()", "mayput()", or
\	  "fwritestr()".  putchar() and mayput() are C subroutines which
\	  themselves call "fwritestr()".  fwritestr() is a C to Forth entry
\	  point, which establishes a temporary Forth environment on the
\	  C stack, then calls a Forth word.
\	Note: When executing fwritestr(), we can lose keyboard characters
\	  if Unix has disabled the Forth level 14 clock handler.  We need
\	  to make sure that Unix leaves that handler enabled during startup
\	  up until the point where Unix takes over the keyboard.
\
\ j) L1-A or break from keyboard when Forth is running
\	Entry mechanism: The level 14 clock interrupt handler checks for an
\	  abort (L1-A from the keyboard or break from a tty) and sets the
\	  "aborted?" variable if one is seen.  Just before the assembly
\	  language part of the interrupt handler returns, it checks
\	  "aborted?", and if it is set, the handler jumps to save-state
\	  instead of returning.  The CPU state at that point has been
\	  restored to the same state that existed just when the interrupt
\	  handler was entered, i.e. as if the trap had directly vectored
\	  to "save-state" instead of to the interrupt handler.  That way,
\	  the user does not see any artifacts of the interrupt handler itself.
\	Signature: The "aborted?" variable is set. Otherwise looks like a
\	  a breakpoint.
\	Action: Displays "Keyboard abort. Type 'go' to resume"
\
\ k) L1-A from keyboard with interrupts off and polling mayget()
\	Entry mechanism: an application is calling the PROM's mayget()
\	  routine in order to get a characters.  Level 14 interrupts are
\	  turned off.  The input device is the Sun keyboard.  mayget()
\	  call key_check() to poll the keyboard.  The key is determined
\	  to be the A of an L1-A sequence.  key_check() calls _enterforth
\	  == reenter , which sets the establishes Forth's trap table and
\	  executes a trap #7f instruction.
\	Signature: This looks like the "Abortent" case above.  If necessary
\	  it could be distinguished by looking on the C stack to see the
\	  interruption of the key_check routine.
\	Action: Displays "Type 'go' to resume"
\
\ l) From a watchdog reset
\	Entry mechanism: prom-cold-code, which is entered from the boot-state
\	  reset vector, destinguished this from a power-on reset by looking
\	  at the watchdog bit in the system error register.  prom-cold-code
\	  then puts a discernable value (-1) in %l0, jumps to save-state,
\	  and save-state saves %l0 in the cpu-state area.
\	Signature: the "error-reset-trap" field in the cpu-state area contains -1.
\	  Otherwise looks like a breakpoint.
\	Action: If watchdog-reboot? is set, execute the autoboot sequence,
\	  otherwise enter the text interpreter.


\ Enter the monitor with no complaints or error messages.

only forth also hidden also  forth definitions

headerless

code reclaim-machine ( -- )
   %g0  h# 14			wrpstate	\ IE=0, FPU=1, PRIV=1
[ifdef] SUN4V
   %g0			%o0	move
   %g0			%o1	move
   %g0  h# 20		%o5	add		\ MMU_TSB_CTX0
   %g0  h# 80		always	htrapif
   %g0			%o0	move
   %g0			%o1	move
   %g0  h# 21		%o5	add		\ MMU_TSB_CTXNON0
   %g0  h# 80		always	htrapif
[then]
   trap-table		%o0	set
   %o0  0			wrtba
   %g0  h# f			wrpil
   %g0  h# 16			wrpstate	\ IE=1, FPU=1, PRIV=1
c;

label exittomon

   flushw

   \ Undo the effects of "fentry" because
   \ of the Client Interface Service EXIT

   \ We don't want to depend on the data
   \ stack pointer being the same, because
   \ the routine may have left a return value
   \ on the stack.

   %o6 V9_SP_BIAS d# 16 na+  sp   nget
   %o6 V9_SP_BIAS d# 24 na+  rp   nget

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

   \ Back to the previous frame
   %g0 0     %g0  restore

   \ Save the client program's trap base register
   %o0  rdtba

   %o1  rdpstate
   %o1 2  %o2 andn
   %o2  0  wrpstate

   \ Set the trap base register to Forth's trap table
   trap-table  %o2  set
   %o2 0            wrtba
   nop nop nop

   begin
      %g0 h# 7f   always trapif
   again			\ Not restartable; keep exiting
   nop

end-code
create exittomon-end

label reenter  ( -- )

   flushw

   \ Undo the effects of "fentry" because
   \ of the Client Interface Service ENTER

   \ We don't want to depend on the data
   \ stack pointer being the same, because
   \ the routine may have left a return value
   \ on the stack.

   %o6 V9_SP_BIAS d# 16 na+  sp   nget
   %o6 V9_SP_BIAS d# 24 na+  rp   nget

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

   \ Back to the previous frame
   %g0 0     %g0  restore

   \ Save the client program's trap base register
   %o0  rdtba

   %o1  rdpstate
   %o1 2  %o2 andn
   %o2  0  wrpstate

   \ Set the trap base register to Forth's trap table
   trap-table  %o2  set
   %o2 0            wrtba
   nop nop nop


   \  %o0  : Original %tba
   \  %o1  : Original %pstate

   %g0 h# 7f   always trapif

   \  %o0  : %tba
   \  %o1  : %pstate

   \ Restore the client's trap base register
   %o0 0            wrtba
   nop nop nop

   %o1 0 wrpstate

   %o7 8  %g0  jmpl
   nop
end-code
create reenter-end

: .go-message  ( -- )
   \ Restarting is only possible if the state that was first saved
   \ is from a restartable exception.
   state-valid @  -1 =  already-go? and  if
      restartable? on
      ['] interpret behavior  ['] (interpret  =  if
         ." Type  'go' to resume" cr
      then
   then
;

headers
0 >debugger-hook per-cpu-defer: debugger-hook

\
\ KADB uses this *and* the per cpu version!
\
: init-debugger-hook ( xt -- )  ['] debugger-hook 3 perform-action  ;

stand-init: Init debugger-hook
   ['] noop init-debugger-hook
;

headerless
defer rearm-alarms  ' noop is rearm-alarms
: reset-debugger-hook ( -- )  ['] noop to debugger-hook  ;
: enter-debugger ( -- )
   addr debugger-hook  token@  reset-debugger-hook  execute
;

h# 3  constant xir-trap#
: is-xir-trap? ( -- flag ) last-trap# xir-trap# = ;
: is-breakpoint-trap?  ( -- flag )  last-trap# breakpoint-trap# =  ;
: inside?  ( label end -- flag )  %pc -rot  within  ;
: .trap  ( -- )
   talign		\ Hack; recover in case dp is misaligned

   aborted? @  if
      aborted? off  rearm-alarms
      enter-debugger  hex cr .go-message  exit
   then

   is-xir-trap? if reset-debugger-hook then
   is-breakpoint-trap?  0=  if
      enter-debugger (do-last-trap) exit
   then

   \ We want to stay at the 'ok' prompt
   \ so, uninstall the debugger-hook
   reset-debugger-hook

   exittomon exittomon-end  inside?   if
      obp-control-relinquished? if  client-exited-chain  then
      false to obp-control-relinquished?
      ." Program terminated" cr  exit
   then
   reenter reenter-end  inside?   if
      .go-message
      %o0 to %tba
      %o1 to %pstate
   then
;
: (restart  ( -- )
   \ If the PC is pointing to the trap instruction in "reenter",
   \ adjust %pc and %npc to skip that trap instruction.
   reenter reenter-end inside?  if
      0w

      0 to %o2

      %pc  la1+     to %pc
      %npc la1+     to %npc
   then
   (crestart
;
: mp-ok ( -- )
   mid@ <# ascii } hold u#s ascii { hold u#> type ."  ok "
;

: mp-system? ( -- n-1 )
   -1  max-mondo-target# 0 ?do
      i mid-ok? if
         i >cpu-struct >cpu-status @ if  1+  then
      then
   loop
;

: ?mp-prompt ( -- )
   ['] "ok" is (ok)
   mp-system?  if  ['] mp-ok is (ok)  then
;

stand-init: Install .exception
   ['] .trap is .exception
;
headers
only forth also definitions
