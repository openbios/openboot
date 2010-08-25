\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usbutils.fth
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
\ id: @(#)usbutils.fth 1.33 04/09/22
\ purpose: 
\ copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

external

\ XXX Must use set-report(output) request.
\ : set-leds ( which-leds? -- )
\ ;

\ Nothing here yet because we're not sure if bell will be supported in
\ USB keyboards.
\ XXX called from ring-bell in keyboard.fth
: ring-keyboard-bell  ( -- ?? )
;

\ Do a set-protocol to get to boot mode.
\ Interface Protocol == 0 (Keyboard).

: set-kbd-bootmode  ( -- hw-err? | stat 0 )
   h# 21	set-prtcl-buff^v >ctrl-pkt-breqtype c!	\ class request
   h# b	set-prtcl-buff^v >ctrl-pkt-brequest c!	\ 0xb=set protocol
   0	set-prtcl-buff^v >ctrl-pkt-wvalue   le-w!	\ 0=boot protocol
   my-interface	set-prtcl-buff^v >ctrl-pkt-windex le-w!
   0	set-prtcl-buff^v >ctrl-pkt-wlength  le-w!	\ 0=no data

   my-speed
   1			\ dir; no, don't xfer data from device to mem
   0max-packet		\ max-pkt
   0			\ buf-adr; no data coming back
   0			\ buf-len; no data coming back
   set-prtcl-buff^v	\ pkt-adr
   /ctrl-pkt		\ pkt-len
   my-endpt		\ endpt
   my-addr		\ usb-adr
   ( low-speed? dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

   execute-control	( hw-err? | stat 0 )
;

: get-kbd-protocol  ( -- hw-err? | stat 0 )
   h# a1	set-prtcl-buff^v >ctrl-pkt-breqtype c!	\ class request
   h# 3	set-prtcl-buff^v >ctrl-pkt-brequest c!	\ 0x3=get protocol
   0	set-prtcl-buff^v >ctrl-pkt-wvalue   le-w!
   my-interface	set-prtcl-buff^v >ctrl-pkt-windex le-w!
   1	set-prtcl-buff^v >ctrl-pkt-wlength  le-w!	\ 1=#bytes data

   my-speed
   0			\ dir; yes, do xfer data from device to mem
   0max-packet		\ max-pkt
   1-byte^v		\ buf-adr for data coming back
   0 over c!		\ clear 1 data byte
   1			\ len of data coming back
   set-prtcl-buff^v	\ pkt-adr
   /ctrl-pkt		\ pkt-len
   my-endpt		\ endpt
   my-addr		\ usb-adr
   ( low-speed? dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

   execute-control	( hw-err? | stat 0 )
;

: set-kbd-idle  ( -- hw-err? | stat 0 )
   h# 21	set-prtcl-buff^v >ctrl-pkt-breqtype c!	\ class request
   h# a	set-prtcl-buff^v >ctrl-pkt-brequest c!	\ 0xa=set idle
   h# 7d00 set-prtcl-buff^v >ctrl-pkt-wvalue le-w!	\ idle=125x4 ms.
   my-interface	set-prtcl-buff^v >ctrl-pkt-windex le-w!
   0	set-prtcl-buff^v >ctrl-pkt-wlength  le-w!	\ 0=no data

   my-speed
   1			\ dir; no, don't xfer data from device to mem
   0max-packet		\ max-pkt
   0			\ buf-adr; no data coming back
   0			\ buf-len; no data coming back
   set-prtcl-buff^v	\ pkt-adr
   /ctrl-pkt		\ pkt-len
   my-endpt		\ endpt
   my-addr		\ usb-adr
   ( low-speed? dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

   execute-control	( hw-err? | stat 0 )
;

: get-kbd-idle  ( -- hw-err? | stat 0 )
   h# a1	set-prtcl-buff^v >ctrl-pkt-breqtype c!	\ class request
   2	set-prtcl-buff^v >ctrl-pkt-brequest c!	\ 2=get idle
   0	set-prtcl-buff^v >ctrl-pkt-wvalue   le-w!
   my-interface	set-prtcl-buff^v >ctrl-pkt-windex le-w!
   1	set-prtcl-buff^v >ctrl-pkt-wlength  le-w!	\ 1=#bytes data

   my-speed
   0			\ dir; yes, do xfer data from device to mem
   0max-packet		\ max-pkt
   1-byte^v		\ buf-adr for data coming back
   0 over c!		\ clear 1 byte of data
   1			\ len of data coming back
   set-prtcl-buff^v	\ pkt-adr
   /ctrl-pkt		\ pkt-len
   my-endpt		\ endpt
   my-addr		\ usb-adr
   ( low-speed? dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

   execute-control	( hw-err? | stat 0 )
;


\ We've received a stall status when checking the interrupt status with
\ the HA.  Make a certain number of attempts to unstall, and then throw
\ when the last attempt is unsuccessful.

: issue-unstall  ( -- hw-err? | stat 0 )
   unstall-cnt 9 > if
     \ poop maybe we should attempt to reset the device, then reconfigure
     \ it for boot mode and set the ticker again, and keep track of *that*
     \ process for x number of times...
      ." USB console device could not be unstalled..." cr
      true throw
   else
     \ issue the unstall via execute-control
      1        std-pkt-buff^v >ctrl-pkt-breqtype c!	\ 0x1= clear feature
      1        std-pkt-buff^v >ctrl-pkt-brequest c!	\ 0x1=CLEAR_FEATURE
      0        std-pkt-buff^v >ctrl-pkt-wvalue   le-w!	\ 0=ENDPOINT_STALL
      my-int-endpt std-pkt-buff^v >ctrl-pkt-windex   le-w!
      0        std-pkt-buff^v >ctrl-pkt-wlength  le-w!	\ 0=no data

      my-speed
      1			\ dir=no xfer data usb->mem
      /ctrl-pkt		\ max-pkt = len of outgoing request
      0      0		\ buf-adr, buf-len
      get-descr-buff^v	\ request-adr
      /ctrl-pkt		\ request-len
      my-endpt		\ endpoint
      my-addr		\ usb-adr
      ( speed dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

      execute-control			( hw-err? | stat 0 )

      unstall-cnt 1+ to unstall-cnt
   then
;


: attempt-unstall  ( -- ack|nak|stall )
   issue-unstall		( hw-err?|stat 0 )
   0<> if
      true throw		\ hw-err during unstall attempt
   then
;


\ headers		\ XXX for debugging

5 constant no-response-error

0 value no-response-cnt

: possible-no-response  ( hw-err -- hw-err )
   dup no-response-error =  if
      no-response-cnt 1+  to no-response-cnt
   then
;

defer maybe-message

: .no-response  ( -- )
   ['] noop to maybe-message		\ publish once only
   ." USB keyboard not responding, please power cycle." cr
;

' .no-response to maybe-message

: not-responding?  ( -- not-there? )
   no-response-cnt d# 10 >=
;

: dummy-keys  ( -- Stop-a? )
   keybuff-curr^v /key-info-buff erase
   eval-key-data
;

\ Send off to the HA/parent to see if a keyboard packet is present,
\ and if so then send the data off to the key evaluation routine.
\ Check for hardware status errors, and also check for usb NAK (no
\ packets waiting) and STALL (indicating a usb function problem).

: poll-usb  ( -- stopA? )
   not-responding?  if			\ essentially no recovery
      maybe-message
      dummy-keys exit			\ dummy to clear other code
   then
   keybuff-curr^v our-ha-token @ int-transaction-status	( hw-err?|stat 0)
   ?dup if			( hw-err )
      possible-no-response drop
      dummy-keys exit			\ dummy to clear other code
   then				( stat )

   0 to no-response-cnt			\ still responding

   case
      h# 6 of	\ nak
         false
      endof			( no-Stop-a )

      h# e of	\ stall
        \ poop turn-off tick timer?
        \ poop turn-off host timer?
         begin
            attempt-unstall	( ack|nack|stall )
				\ unstall attempt has built-in "max count"
				\ loop check; does throw when at max count
            2 = if		( )	\ ack rcvd from unstall
               true		( loop-exit-flag )
            else			\ nack or stall from unstall attempt
               false		( loop-noexit-flag )
            then
         until			( )
        \ poop turn-on tick timer?
        \ poop turn-on host timer?
         false			( no-Stop-A )
      endof

      2 of	\ ack
         eval-key-data		( Stop-A? )
      endof			( Stop-A? )
   endcase
;


\ If keyboard "interrupts" were already running then turn them off.

: makesure-kbdints-off  ( -- )
   our-ha-token @ dup -1 <> if			( token )
      disable-int-transactions to ha-toggle	( )
      -1 our-ha-token !				( )
   else
      drop					( )
   then
;


\ For "reset", turn off repeat-interrupt-request if it's already on and
\ set the token to -1 to indicate interrupts are off.  Set up the device
\ to be a "boot" device, and initialize software variables.  Then send 1
\ interrupt request and look at its status to see if the keyboard is
\ (still) there.  If there and everything is ok then turn on the repeated
\ interrupts, and link our tick timer to check the the status
\ periodically.
\ [ For the Sun keyboards, reset was in the probe.fth file. ]

: init-kbd  ( -- )
   makesure-kbdints-off				( )
   ['] set-kbd-bootmode do-ctrl/err-loop	( )
   ['] set-kbd-idle do-ctrl/err-loop
   clear-keyboard				( )
;

\ from parent device node if an interface, from my node if combined device
: set-my-0max-packet  ( -- )
   " 0max-packet" get-inherited-property  ( true | adr len false )
   if
      ." Unable to get 0max-packet for usb keyboard." cr
      true throw
   else
      decode-int to 0max-packet
      2drop
   then
;

\ low-speed property from my node only, else is regular speed
: set-my-speed  ( -- )
   " low-speed" get-my-property		( true | adr len false )
   if					\ regular speed
      false
   else					\ low speed
      2drop true
   then
   to my-speed
;

: set-my-addr  ( -- )
   " assigned-address" get-inherited-property	( true | addr len false )
   if
      ." Unable to get assigned address for usb keyboard." cr
      true throw
   else
      decode-int to my-addr   2drop
   then
;

: $>endpt  ( addr len -- n )		\ this better work, no throw
   base @ >r  hex
   dup if
      $number  if			\ XXX dreadfully wrong, no enpt #
         cr ." missing endpoint#"
         1				\ XXX probably wrong here
      then
   else  2drop 1			\ default to endpt 1
   then
   r> base !
;

: $>packet  ( addr len -- n )
   base @ >r  hex
   dup if
      $number  if			\ XXX dreadfully wrong, no max-pkt#
         cr ." missing max-packet#"
         8				\ Sun default
      then
   else  2drop 8			\ Sun default; seriously wrong
   then
   r> base !
;

\ read endpoints and max-packets
: set-my-endpts  ( -- )
   " endpoints" get-inherited-property		( true | addr len false )
   if
      ." Unable to get endpoints for usb keyboard." cr
      true throw
   else
      decode-string 2swap 2drop
      ascii ,  left-parse-string  2drop	\ always 0, for my-endpt ( control )
      ascii ,  left-parse-string  2drop \ could use for 0max-packet
      ascii ,  left-parse-string	\ assume this is the interrupt endpt
      $>endpt  h# f and			\ XXX dumping direction for now
      to my-int-endpt
      ascii ,  left-parse-string	\ its max-packet
      $>packet to my-int-max-packet
      2drop				( ) \ dump any other endpts for now
   then
;

: set-my-interface  ( -- )
   " interface#" get-my-property	\ must be in my node
   if					\ seriously wrong
      0					\ Sun default
   else
      decode-int
      nip nip
   then
   to my-interface
;

\ The country layout is determined in the open routine, and the
\ keymap presence/correctness is determined at that time also.
\ True is returned if everything is OK, otherwise false is returned.

\ 0 instance value kbd-driver
: install-device  ( -- everything-ok? )
   -1 our-ha-token !   1 to ha-toggle

   set-my-0max-packet  set-my-speed
   set-my-addr set-my-endpts
   set-my-interface

   init-kbd

\  forced-keyboard-mode? or			( ok? )

   8		\ ms
   our-toggle	\ toggle
   my-speed
   0		\ dir = xfer from USB to host (us)
   my-int-max-packet
   8		\ buf-len; max length for data being returned
   my-int-endpt	\ endpoint
   my-addr	\ usb-adr
   ( ms toggle low-speed? dir max-pkt buf-len endpoint usb-adr )

   enable-int-transactions			( HAtoken )

   dup if					( HAtoken )
      our-ha-token !   true			( yes-ok )
   else						( not-ok )
     \ A returned token of 0 indicates that the HA wouldn't honor our
     \ request, meaning that one of the parameters is probably bogus.
      ." HostAdapter didn't honor keyboard enable-int-transactions." cr
      drop true throw
   then
;

: alloc-vaddr-buffs  ( -- )
   /ctrl-pkt dma-alloc to set-prtcl-buff^v
   /ctrl-pkt dma-alloc to get-descr-buff^v
   /hid-descriptor dma-alloc to hid-descr-buff^v
   /key-info-buff dma-alloc to keybuff-curr^v
   /ctrl-pkt dma-alloc to std-pkt-buff^v
   1 dma-alloc to 1-byte^v
;


: dealloc-vaddr-buffs  ( -- )
   set-prtcl-buff^v /ctrl-pkt dma-free
   get-descr-buff^v /ctrl-pkt dma-free
   hid-descr-buff^v /hid-descriptor dma-free
   keybuff-curr^v /key-info-buff dma-free
   std-pkt-buff^v /ctrl-pkt dma-free
   1-byte^v 1 dma-free
;
