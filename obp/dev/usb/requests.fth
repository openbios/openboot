\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: requests.fth
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
id: @(#)requests.fth 1.13 02/12/19
purpose: 
copyright: Copyright 1997-2000 Sun Microsystems, Inc.  All Rights Reserved

: request-blank  ( -- addr )  /request get-chunk  ;

: descript-form  ( len -- addr )
   request-blank
   get-descript-req over request-type w!
   swap over req-len le-w!
;

: get-dev-descript-form  ( len -- addr )
   descript-form
   device-descript over req-value 1+ c!
;

: get-config-descript-form  ( len -- addr )
   descript-form
   config-descript over req-value 1+ c!		\ need index as well
;

: set-address-form  ( usb-addr -- addr )
   request-blank
   set-address-req over request-type w!
   swap over req-value le-w!
;


: add-setup-transfer  ( p-adr p-len endp-d -- )
   2 setup-bits rot  t>endq
;

\ XXX should have a toggle in the stack diagram; see execute-1-interrupt.
\ XXX the adding code can be better factored and cleaned up
\ dir is 0 for data from target to host, 1 for data from host to target
: (add-data-transfer)  ( buf-adr buf-len dir endp-d -- )
   3					\ toggle
   rot  if  out-bits  else  in-bits  then
   rot t>endq
;

: add-data-transfer  ( buf-adr buf-len dir endp-d -- )
   rot ?dup  if
      -rot  (add-data-transfer)
   else  2drop drop			\ 0 len transfer not needed here
   then
;

\ dir is 0 for out-ack, 1 for in-ack (opposite of add-data-transfer)
: add-ack-transfer  ( dir endp-d -- )
   >r >r
   0 0 3					\ status transfer
   r>  if  in-bits  else  out-bits  then
   r> t>endq
;

: add-isoc-transfer  ( frame# badr blen endp -- )
   over  if
      isoct>endq
   else  2drop 2drop			\ 0 len transfer not needed here
   then
;

: enque-control  ( endp-d -- )
   control-off next-frame
   control-id e>q
   control-on  control-filled
;

\ Need to clear hccontrol bit.  on next frame, hccontrolcurrent is adjusted
\ so it does not point to the one being removed (ohci 5.2.7.1.2 says use 0).
\ adjust pointers in nearby endpoint d's to point around the one being
\ removed.  then turn on the q in hccontrol again.
: deque-control  ( endp-d -- )
   chip-base hc-control rl@ >r
   control-off next-frame
   eq>
   0 chip-base hc-control-current rl!	\ make sure it's not looking at this 1
   control-filled			\ make it start over on control q
   r> chip-base hc-control rl!
;

: enque-interrupt  ( endp-d q# -- )
   periodic-off next-frame
   e>q
   periodic-on
;

: deque-interrupt  ( endp-d -- )
   chip-base hc-control rl@ >r
   periodic-off next-frame
   eq>
   r> chip-base hc-control rl!
;

: enque-bulk  ( endp-d -- )
   bulk-off next-frame
   bulk-id e>q
   bulk-on  bulk-filled
;

: deque-bulk  ( endp-d -- )
   chip-base hc-control rl@ >r
   bulk-off next-frame
   eq>
   r> chip-base hc-control rl!
;

: enque-isoc  ( endp-d -- )
   isoc-off next-frame
   isoc-id e>q
   isoc-on  periodic-on
;

: deque-isoc  ( -- )
   chip-base hc-control rl@ >r
   isoc-off next-frame
   eq>
   r> chip-base hc-control rl!
;

' take-done-q to bless-done-q		\ for polled at probe time;
					\ could use quit-take-done-q

\ ping-pongs once to check both done-q's if needed.  Leaves the code pointing
\ to the done q with the done transfer waiting that it found, if it found one.
\ XXX If other code guarantees this starts on a clean q, ping-pong should be
\ first.
\ The endpoint starts with the pointer for the distributor set to a clean
\ queue, and the regular code looking at a clean queue, so I think the ping-
\ pong can be done first.  Results in a slightly better response time.
\ there's a wrinkle in connection with the interrupt transfers and isoc
\ transfers.
: done-waiting?  ( endpoint -- done-waiting? )
   bless-done-q
   dup code-done-q @  ?dup  if
      nip
   else
      dup ping-pong
      code-done-q @
   then
;

d# 5000 value time-limit			\ 5 sec timeout, usb 7.1.4.3; global ok

: more-time?  ( limit -- limit-not-hit? )
   get-msecs - 0>
;

\ 0 if timed-out.
: wait-for-reply  ( endpoint -- done-q | 0 )
   get-msecs time-limit +
   begin
      over done-waiting?  dup  if
         dup
      else  over more-time?  0=  if  true  then
      then
   until
   nip nip
;

: wait-till-stopped  ( endpoint -- stopped | 0 )	\ 0 if timed-out
   get-msecs time-limit +
   begin
      over stopped?  dup  if
         dup
      else  over more-time?  0=  if  true  then
      then
   until
   nip nip
;

\ true if only one more reply outstanding.  partly a check that all the
\ transfer-d's are accounted for and none left in limbo (endpoint-d shows
\ empty, but no reply on the done-q yet).
: last-reply?  ( endpoint -- last? )
   transfer-count @ 1- 0=
;

\ Move the transfer-d's from done-q to the stack.
: take-transfer-d's  ( endpoint -- q-head )
   dup code-done-q @
   0 rot code-done-q !		\ this done-q can be reused now.
;

\ Assumes that the transfer-d's are put on the q in the same order
\ as on the controller done-q.
\ code is condition code of last reply or error code of recent reply
\ code is present only if bad-or-last? is non-false.
: bad-or-last-reply?  ( transfer-d endpoint -- [code] bad-or-last? )
   2dup dump-following-transfer-d's
   swap >r  last-reply?  if
      r@ condition-code true
   else
      r@ condition-code ?dup
   then
   r> dump-transfer
;

\ XXX if timeout, need to dump the transfer somehow
\ Look for a done transfer.  Keep looking until one shows up, or timeout.
\ Dump any earlier done transfers.
\ Check if it is the last one.  If it is, return its condition code.
\ If it is not the last one, check it for an error, and return that if
\ non-zero.  If it isn't the last one, and has no error, keep looking.

\ Not used for enable-int-transactions.  Should never time out.

\ 0 if we got the last reply, there was no timeout, and there was
\ no error.  Otherwise, there was a timeout, or there was an error.
\ The done transfer-d's are dumped.
: wait-for-last-reply  ( endpoint-d -- reply-code )
   begin  dup wait-for-reply  ?dup  if
         over bad-or-last-reply?
      else				\ timed-out
         time-out-error true
      then
   until
   nip
;

: 1-try-wait  ( endpoint-d -- reply-code )
   time-limit			( endpoint-d time-limit )
   2 is time-limit
   swap wait-for-last-reply	( time-limit reply-code )
   swap is time-limit		( reply-code )
;

\ Look at the packet status words; report the first error
: packet-statuses  ( transfer-d -- error-code )
   0 swap				\ assume good
   8 0 do
      i over packet-condition-code
      ?dup  if  -rot nip leave  then
   loop
   drop
;

: isoc-transfer-bad?  ( transfer-d -- error-code )
   dup condition-code ?dup  if
      nip
   else
      packet-statuses
   then
;

\ Reverse the q of transfer-d's onto the stack.
: get-transfer-d's  ( q-head -- q-head trans1 ... transn )
   begin
      dup next-transfer le-l@
      ?dup 0=
   until
;

\ Look at the transfer-d's on the done-q in reverse order (in order that
\ they went on the done-q).  Check each one for bad isoc status.  Dump
\ the transfer-d's.
: check-isoc-packets  ( done-q-head -- error-code )
   0 >r				\ assume good
   dup >r			( R: 0 done-head )
   get-transfer-d's		( done-head trans1 ... transn ) ( R: 0 q-head )
   begin
      dup  isoc-transfer-bad?  ?dup  if
         r> r>  ?dup  if
            >r >r drop
         else
            swap >r >r
         then
      then
      dup dump-isoc-transfer
      r@ =
   until
   r> drop
   r>
;

: wait-for-last-isoc-reply  ( endp-d -- reply-code )
   dup wait-till-stopped  if		\ endpoint done
      bless-done-q
			\ can't be any replies on current done q, so ping-pong:
      dup ping-pong  take-transfer-d's		( done-q-head )
      check-isoc-packets	\ look for error codes, dump transfer-d's
   else
      drop time-out-error
   then
;

: dump-done-q  ( endpoint-d -- )
   dup code-done-q @  if
      dup code-done-q @ tuck swap
      dump-following-transfer-d's dump-transfer
   else  drop
   then
;


\ XXX needs change to return a nak for execute-1-interrupt?
2 constant usb-ack
6 constant usb-nak
e constant usb-stall

\ hw-err? is anything other than usb ack, nak, or stall
: translate-code  ( reply-code -- hw-err? | stat 0 )
   ?dup  if
      dup stall-error =  if  drop usb-stall 0  then
   else  usb-ack 0
   then 
;


\ How do we process the transfers in order?  Does it matter?
\ Right now the done transfers are put on the chip done q in reverse order,
\ earlier done ones are pushed towards the tail of the q (it's a "stack").
\ They are moved to the endpoint done q's in the same order (they are
\ "stacks").  The distributor code is simpler and faster this way, which
\ is a good thing, since it executes on the 10 ms tick timer.

\ Could give each transfer descriptor a sequence number, and keep the last
\ number in the endpoint.  Then could look at each done transfer in order
\ of the sequence.

\ Doesn't look like we need sequence numbers:
\ Can we assume that if transfer 2 shows up on a done q, that transfer 1
\ went through ok?  And is on some q already (or already disposed of by the
\ code)?  At least can assume that 1 is somewhere.  Looks like can assume
\ that 1 went ok, except for isoc transfers.

\ For general transfers, any code other than no-error will cause endpoint to
\ halt.  isoc transfers will never halt.

\ isoc transfers have error codes in the transfer descriptor fields as well
\ as the completion code field.  The completion code may be no-error, while
\ some packet status words may have error codes.

\ So, when the code takes a done q, it can reverse the transfer d's to get
\ them in sequence of completion, or just dump all but the latest executed.

\ So for a non-isoc, non-repeated interrupt, interface method, wait until
\ either the last transfer is finished, or some transfer gets an error.
\ If last transfer is ok, report good back to caller.  Otherwise, report
\ error of some sort.
