id: @(#)sysintf.fth 1.22 05/02/14
purpose: Interfaces to low-level system functions
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Interfaces to system-dependent routines

defer diag-key     ( -- char )  \ Used by dl

\ (Approximately) millisecond-granularity timing
\ Typically implemented by a driver for a counter/timer device

d# 10 value ms/tick
headers
defer get-msecs  ( -- n )  ' 0 is get-msecs
defer ms  ( n -- )   ' drop is ms
defer us  ( n -- )   ' drop is us


\ Enabling/disabling interrupts
\ Typically implemented by a driver for an interrupt controller

defer enable-interrupts   ( -- )  ' noop is enable-interrupts
defer disable-interrupts  ( -- )  ' noop is disable-interrupts

\ System-wide DMA memory allocation (used only by the deblocker)
\ Typically implemented by a MMU driver

headerless
: null-allocate-dma  ( #bytes -- 0 )  drop 0  ;
defer allocate-dma  ' null-allocate-dma is allocate-dma
: null-free-dma  ( virt #bytes -- )  2drop  ;
defer free-dma  ' null-free-dma is free-dma

: null-vtop ( virtual -- phys-lo phys-hi )  drop -1 -1 ;

headers
defer >physical  ' null-vtop  is >physical

\ Dropin-driver execution
\ Typically implemented by a driver for the system's ROM
defer do-drop-in  ( adr len -- )	' 2drop is do-drop-in
defer find-drop-in ( name$ -- buf,len,true | 0 )
defer free-drop-in ( buf,len -- )	' 2drop is free-drop-in

headerless
: null-find-drop-in ( name$ -- 0 )	2drop false  ;
' null-find-drop-in is find-drop-in

headers
\ Support for peeking and poking (memory access immune to bus errors)
\ Typically implemented by a driver for the system's trap-handing mechanism

: (guarded-execute)  ( ??? xt -- ??? flag )  execute  true  ;
defer guarded-execute  ( ??? xt -- ??? flag )
' (guarded-execute) is guarded-execute


\ Storage of reboot information across system resets
\ The reboot information is typically stored in some type of memory
\ that is not cleared by a system reset.  The information does not
\ necessary have to survive across power cycles.

false value reboot?	\ Usually set in machine-dependent startup code
			\ after testing a magic flag in physical memory

: null$  ( -- adr len )  " "  ;

: null-save-reboot-info  ( arg$ cmd$ forth? line# column# -- )
   3drop 2drop 2drop
;
defer save-reboot-info  ( arg$ cmd$ forth? line# column# -- )
' null-save-reboot-info is save-reboot-info

defer get-reboot-info   ( -- cmd+arg$ line# column# )
: null-get-reboot-info  ( -- cmd+arg$ line# column# )
   null$ 0 0
;
' null-get-reboot-info is get-reboot-info


\ Force a system reset
\ Typically implemented by a driver for system-level special registers.

headers
defer reset-all ( -- )  ' noop is reset-all


defer cleanup ' noop is cleanup	\ pkg/boot/go.fth

false value already-go?	\ sun4/reenter.fth

\ From reenter.fth
nuser aborted?      aborted? off
: (user-abort)  ( -- )  1 aborted? ! ;
headers
defer user-abort   ' (user-abort) is user-abort
headerless

\ System and version identification

defer idprom-valid?  ( -- flag )
' true  is idprom-valid?

\ You do not need to edit these strings, instead define them
\ in version.fth properly.
create (4.0-prom) ," 4.0.0"
create (sub-release) ," "
headers
defer obp-release		    ' (4.0-prom) is obp-release
defer sub-release  ( -- adr len )   ' (sub-release) is sub-release
headerless

defer serial#  ( -- n )   ' 0 is serial#

\ System-wide network address

\ system-mac-address is typically defined in some sort of ID PROM
defer system-mac-address  ( -- adr len )  ' null$ is system-mac-address


\ Device to use for console output if the preferred device is unavailable

defer fallback-device  ( -- adr len )  ' null$ is fallback-device


\ Compatibility FCode support

headers
defer sbus-intr>cpu   ( sbus-level -- cpu-level )  ' noop is sbus-intr>cpu
headerless

: no-memory  ( -- adr len )  0 0  ;


\ OS callbacks
defer callback-call  ( arg-array -- error? )  ' true is callback-call

\ Default font
headers
defer romfont  ( -- fontadr )  ' false is romfont
headerless

\ Security state
defer ?secure   ' noop is ?secure

\ Startup Hook. A chance to get in before the auto-boot starts
defer startup-hook ( -- )  ' noop is startup-hook

\ check-machine-state, check-machine-chain
\ these two are for a machine to verify itself prior to the auto-boot
\ starting.
\ You should not be changing check-machine-chain defer!!
\ use the chain to report various conditions you are unhappy with instead,
\ the check-machine-state chain runs before the interrupt-auto-boot? chain
\ so you can set complain, and use the state to prevent (perhaps) a subsequent
\ auto-boot?
\ the chain to attach yourself to is:
\ 
\     check-machine-state
\ 
alias check-machine-state noop
defer check-machine-chain	' noop to check-machine-chain

\ don't-boot?, interrupt-auto-boot?
\ The starting place for the reasons not to boot.
\ chain: yourself onto don't-boot? and OR in true to prevent an auto-boot,
\ however a routine closer to the head of the chain may over-rule your choice.
\ The chain name used to set interrupt-auto-boot? is
\ 
\   don't-boot?
\ 
\ this is the head of the don't-boot? chain.
\ You should not be changing this defer!!
\ 
alias don't-boot? false
defer interrupt-auto-boot?  ' false to interrupt-auto-boot?

\ client-starting
\ This is a notification chain to let drivers know that activities
\ such as alloc-mem, using DMA etc...
\ will no longer permitted after the chain executes
\ 
alias client-starting noop
defer client-starting-chain ' noop to client-starting-chain

\ Client-exited
\ This is a notification chain to let drivers know that a client program
\ has terminated.
\ 
alias client-exited noop
defer client-exited-chain ' noop to client-exited-chain

\ run-diags?
\ A simple defer; it returns true if the machine will run diags
defer run-diags? ' false is run-diags?

h# 4000 constant default-load-base

defer help-msg ( -- )  ' noop is help-msg

\ Flag to tell us whether we're "inside" the OS or not.
\ This lets Forth words (and possibly the environmental monitor) know whether
\ they're being run from within Stop-A, perhaps to restrict their behavior.
\ This is set when the client takes over the trap table and cleared when the
\ client returns (prom-exit).
false		value	obp-control-relinquished?

\ Active firmware verbosity level.
\ This controls the level of OpenBoot verbosity (console output text)
\ generated by probe/config/init code (basically, everything driven
\ by the stand-init chain).  This active value is not necessarily the
\ same as the "verbosity" NVRAM configuration variable...this is driven
\ by (e.g.,) the reset/config code, and passing the active verbosity
\ into (e.g.,) boot.fth stand-init-io early setup.

h#   2 constant VRBS-NONE		\ Error messages only
h#   4 constant VRBS-MIN		\ Minimum F/W verbosity
h#   8 constant VRBS-MED		\ Medium F/W verbosity
h#  10 constant VRBS-MAX		\ Maximum F/W verbosity
h#  20 constant VRBS-DEBUG		\ Debug F/W verbosity

VRBS-MAX value fw-verbosity		\ Default maximum 'till toned down

\ hook from selftest
also forth definitions
defer diag-hook ( status phandle -- ) ' 2drop to diag-hook
previous definitions
