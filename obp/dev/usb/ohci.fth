\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ohci.fth
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
id: @(#)ohci.fth 1.14 06/02/01
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ stuff bits, leaving the rest alone, in the control reg.
: controlbit-on  ( bit -- )
   chip-base hc-control rl@  or
   chip-base hc-control rl!
;

\ turn bit off, leaving the rest alone, in control reg.
: controlbit-off  ( bit -- )
   invert  chip-base hc-control rl@  and
   chip-base hc-control rl!
;

: periodic-on  ( -- )  4 controlbit-on  ;

: periodic-off  ( -- )  4 controlbit-off  ;

: isoc-on  ( -- )  8 controlbit-on  ;

: isoc-off  ( -- )  8 controlbit-off  ;

: control-on  ( -- )  h# 10 controlbit-on  ;

: control-off  ( -- )  h# 10 controlbit-off  ;

: bulk-on  ( -- )  h# 20 controlbit-on  ;

: bulk-off  ( -- )  h# 20 controlbit-off  ;

\ : q-on  ( q-id -- )
\   h# 3e -  0 max
\   4 swap lshift
\   controlbits-on
\ ;

\ : q-off  ( q-id -- )
\   h# 3e -  0 max
\   4 swap lshift
\   controlbits-off
\ ;

: >state  ( n -- )
   6 lshift
   chip-base hc-control rl@
   h# c0 invert and  or
   chip-base hc-control rl!
;

\ nominally 10 ms
\ usb1.1, 7.1.7.3 says at least 50 ms
: usb-reset  ( -- )  0 >state  d# 100 ms  ;		\ power-on state

\ nominally 20 ms; USB 7.1.4.5; also usb1.1 7.1.7.5
: usb-resume  ( -- )  1 >state  d# 40 ms  ;

\ usb1.1 7.1.7.3 says wait 10 ms before talking to devices after usb-reset
\ usb1.1 7.1.7.5 says 10 ms delay after usb-resume
\ embed the delay here, since operational is the end of usb-reset
: usb-operational  ( -- )  2 >state  d# 10 ms  ;

\ XXX enough time?  nominally 5 ms from where? how long does it take for
\ the controller to stop accessing memory?  the time before we resume
\ the bus doesn't seem to be an issue?
\ The delay is to allow suspend to propagate down the bus.  Devices need to
\ see no SOF for 3 ms to go to their own suspended state.
\ It is also to allow RIO to stop accessing memory.
: usb-suspend  ( -- )  3 >state  5 ms  ;

\ stuff bit, leaving the rest alone, in the command/stat reg.
: bit>command  ( bit -- )
   chip-base hc-cmd-status rl@  or
   chip-base hc-cmd-status rl!
;

: ohci-reset  ( -- failed? )			\ reset controller only
   1 bit>command
\ XXX can take up to 10 usecs before finishing reset
\ but if it takes longer than 1 ms to go to operational state, devices
\ on the bus can go into suspend state
\   1 ms						\ wait 10 usec
   chip-base hc-cmd-status rl@  1 and		\ 0 means done resetting
;

: control-filled  ( -- )  2 bit>command  ;

: bulk-filled  ( -- )  4 bit>command  ;

\ stuff bit, leaving the rest alone, in the interrupt status reg.
: bit>int-status  ( bit -- )
   chip-base hc-int-status rl!
;

: clear-overrun  ( -- )  1 bit>int-status  ;

: clear-done-head  ( -- )  2 bit>int-status  ;

: clear-sof  ( -- )  4 bit>int-status  ;

: clear-bad-error  ( -- )  h# 10 bit>int-status  ;

: clear-hub-change  ( -- )  h# 40 bit>int-status  ;

: clear-interrupts  ( -- )
   chip-base hc-int-status rl@
   chip-base hc-int-status rl!
;

: new-done?  ( -- new-done? )  2 chip-base hc-int-status rl@ and  ;

: new-sof?  ( -- new-sof? )  4 chip-base hc-int-status rl@ and  ;

\ XXX RIO reset-port disables the port.  not good.  or does it toggle enable?
\ is it only lo-speed ports?
\ enable-port anyway, even if it says it's enabled per OS init code.
: clean-port  ( port -- )
   dup reset-port
   dup enable-port
   dup clear-connect-change
   dup clear-port-reset
   dup clear-port-suspend
   clear-port-enable
   clear-hub-change
;

0 value end-time			\ used to sync wi. controller via next-frame

: timed-out?  ( -- timed-out? )
   get-msecs end-time u>		\ XXX problem when going thru 0
;

\ If wait-for-sof times out, the chip is not copasetic
\ XXX throw from here; should publish some kind of error!
: wait-for-sof  ( -- )
   get-msecs  d# 10 +  is end-time		\ really should be only 1 ms
   begin
      new-sof?
      timed-out? or
   until
;

: wait-for-first-sof  ( -- sof? )		\ used during power on
   clear-sof
   false					\ assumes failure
   d# 300 0  do					\ wait up to 3 seconds
      new-sof?  if
         drop true leave
      then
      10 ms
   loop
;

: next-frame  ( -- )  clear-sof wait-for-sof  ;

\ Stuff a new value into the fsmps field of fm-interval reg:
: fsmps!  ( n -- )
   d# 16 lshift
   chip-base hc-fm-interval rl@
   dup 8000 and 8000 xor >r			\ toggle bit needed later
   h# 3fff and  or
   r> or
   chip-base hc-fm-interval rl!
;

\ XXX need to bang control reg. cmd-status reg
: start-controller  ( -- ok? )
   usb-reset
\   make sure frameremaining field is not large (SOF tokens start on next
\      transition)
   usb-operational
\ want to see SOF within 3 seconds here or something is fatally wrong:
   wait-for-first-sof		( sof? )
   dup 0=  if
      ." no usb SOF" cr
   then
   get-root-info
   set-root-status
\ sequence triggers port status change in RIO.  it's magic and shouldn't
\ be necessary, but it seems to get the chip more fully operational:
   unpower-ports  2 ms			\ 1 ms necessary; 2 to make sure
   power-ports  4 ms			\ 3 necessary
\   set-root-port-status
   clear-interrupts
;

\ must keep resume disabled.
\ some control bits in the hub registers will keep specific ports from forcing
\ resume.
: stop-controller  ( -- )
   periodic-off isoc-off control-off bulk-off
   next-frame
   usb-suspend
;

\ set regs that have adjustable policy, that basically are touched only once
: set-policy  ( -- )
\   h# 3e67 chip-base hc-period-start rl!	\ XXX from manual; too long!
\   h# 2a30 chip-base hc-period-start rl!
\ give 20% to control/bulk, 80% to periodic:
   h# 2580 chip-base hc-period-start rl!
\   h# 628 chip-base hc-ls-threshold rl!	\ 628 is reset value
;

\ Sometimes the HcFmInterval register will not hold it's value 
\ after the first write.  This was seen primarily on the ULI 1575 
\ controller, but also reported on the 1535+. 
\ Loop on the write to ensure it has completed.
: hc-fm-interval!  ( data -- error? )
   chip-base hc-fm-interval
   d# 10 0 do
      2dup rl!
      2dup rl@ = if
         leave
      then
      d# 10 ms
   loop
   rl@ <> dup if
      cmn-error[ " Unable to write to HcFmInterval Register" ]cmn-end
   then
;

\ Leave controller off:
: set-regs  ( -- error? )
   0 chip-base hc-cmd-status rl!
   h# c000.007f chip-base hc-int-disable rl!		\ disable interrupts
   clear-interrupts		\ done later also; may not be needed here
   dev-hcca chip-base hc-hcca rl!
   dev-control-dummy dup				\ empty control q
   chip-base hc-control-head rl!
   chip-base hc-control-current rl!
   dev-bulk-dummy dup					\ empty bulk q
   chip-base hc-bulk-head rl!
   chip-base hc-bulk-current rl!
   0 chip-base hc-done-head rl!				\ empty done q
   h# a668.2edf hc-fm-interval!		( error? )	\ using 2668
\ OS uses 2668:
\   h# 2668  fsmps!			\ XXX not here -- should calculate
   set-root-hub
;

: toss-controller  ( -- )
   stop-controller dump-structs
   unmap-regs
;

: init-controller  ( -- ok? )
   map-regs  ohci-reset  if		\ reset failed error exit
      ." usb reset failed" cr
      false exit			\ XXX throw is better?
   then
   make-structs
   chip-base hc-control rl@ drop	\ read, then write, per OS driver.
   0 chip-base hc-control rl!		\ does usb-reset and clears reg.
   d# 100 ms		\ wait here; nominally 10 ms; see comment on usb-reset
   set-policy
   set-regs if  
      dump-structs unmap-regs
      false exit  
   then
\ should start within 1 msec of ohci-reset?
   start-controller
;
