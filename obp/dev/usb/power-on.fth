\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: power-on.fth
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
id: @(#)power-on.fth 1.27 03/03/13
purpose: 
copyright: Copyright 1997-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: activate-chip  ( -- ok? )
   get-mem new-mem-table init-controller
;

\ the proper value here is dependent on the particular OBP implementation,
\ especially the depth of the return stack.  this value is used to set an
\ internal value used by the two external words in ...builtin-drivers.
\ 6 constant max-depth			\ full usb tree
3 constant max-depth

\ has dependency on main OBP.  puts the recursion depth for hubs back to the
\ maximum allowed for this onboard usb host adapter.  this word works with
\ go-deeper? in the hub fcode, and with onboard-usb-max-depth and onboard-usb-recurse?
\ in SUNW,builtin-drivers.
: max-recursion  ( -- )
   max-depth
   " onboard-usb-max-depth"
   " SUNW,builtin-drivers" find-package drop		\ must be present
   find-method  if
      execute
   else  drop
   then
;

\ XXX some devices take a long time to turn on after reset.  Do some
\ require two resets?
\ XXX the order of activation pieces may differ between regular speed and
\ low speed devices.

\ Hack -- up to 2 tries if error occurs on first try.
: probe-guts  ( port speed -- port speed )
   2 0 do
      2dup
      over clean-port
      probe-once
      if  leave  then
   loop
;

\ give a device two chances.  if not enumerated ok after two tries, make a
\ bad device node.  Leave open the option for other actions, depending on the
\ precise failure.
\ Hack-- up to 5 tries, ignoring fatal errors.  With probe-guts, up to 9
\ fatal errors will be ignored.
: probe-port  ( port speed -- )
   max-recursion
   5 0 do					\ Hack for taco bad usb mouse
      probe-guts
      ['] 2drop  ['] complete-probe behavior =
      if  leave  then
   loop
   complete-probe
;

\ loop works because RIO powers all ports on at power-on time.
\ otherwise may need to power port, then look to see if connected.
: power-on  ( -- )
   my-self to saved-self
   ['] take-done-q to bless-done-q	\ running polled during probe;
					\ could use quit-take-done-q
   publish-finder
   activate-chip  if
      #root-ports 1+  1  do		\ usb ports start at 1
         i port-connected?  if
            i power-port
            i  dup port-low-speed?
            dup to child-speed
            probe-port
         then
      loop
   then
   toss-controller give-mem
   0 to open-count
   0 to saved-self
   ['] quit-take-done-q to bless-done-q		\ setup for 10 ms tick
;

power-on
