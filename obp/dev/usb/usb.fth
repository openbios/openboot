\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb.fth
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
id: @(#)usb.fth 1.16 03/05/12
purpose: 
copyright: Copyright 1997-2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

external


\ Code for the request looks at the done-q for the endpoint.  When no more
\ transfers to go out, and both done-q's dealt with, endpoint gets torn
\ down.  Or if error recovery dumps the remaining transfers and deals with
\ done-q's.  But how does the code know whether all the replies have been
\ received, and that there aren't more on the controller done-q waiting to
\ be distributed?  Can there be any in a transition -- processed by the
\ controller, but not yet put on the done-q because the controller already
\ turned the done-q over to the code, but the code has not yet acknowledged
\ it?  What do such transfer-d's look like?

\ OS folks avoid the problem by running a second list structure through
\ the transfer d's in addition to the one the chip uses, together with a
\ re-claim mark on the transfer d's.  When code decides to dump an endpoint,
\ it marks each of the transfer d's to be re-claimed, using the non-controller
\ list links.  Then it dumps the endpoint.  When transfer d's show up on the
\ controller done q with the reclaim mark, the done-q code dumps them
\ immediately, before attempting to assign them to an endpoint.

\ Instead of double threading, try putting a count of outstanding transfer
\ d's in the endpoint.  When one is added, increment the count.  When one
\ is taken from one of the ping-pong done q's, decrement the count.  Don't
\ include the dummy transfer d in the count.  If the total of the number left
\ to do plus those on the done q's is less than the transfer d count, there
\ are some in process (or on the controller done q).


\ OHCI control transfers always start with setup stage and always end with
\ a 0 len transfer status stage.  There may be a data transfer stage in
\ between.

\ req-adr req-len is the control request to be sent.  endpoint usb-addr is
\ the target address.  buf-adr buf-len is where accompanying data is to be
\ sent from, or return data to be put.  buf-adr = 0 and/or buf-len = 0 imply
\ no data to be transferred.  max-pkt is maximum packet to be transferred in
\ one transfer.
\ dir is the direction that data will flow: 0 is from target to host, 1 is
\ from host to target.  If no data transfer, dir is 1.  low-speed? is true for
\ low-speed target, false for normal speed.

: execute-control  ( low-speed? dir max-pkt buf-adr buf-len req-adr req-len
					endpoint usb-addr -- hw-err? | stat 0 )
   2swap >r >r  2swap >r >r
   2swap swap >r -rot
   make-endpoint	( endpoint-d ) ( R: r-len r-adr b-len b-adr dir )
   r> r> r> r> r>	( endpoint-d dir b-adr b-len r-adr r-len )
   2swap >r >r
   2swap >r >r r@	( r-adr r-len endp-d ) ( R: blen badr dir endp-d )
   add-setup-transfer			( R: b-len b-adr dir endp-d )
   r> r> swap r> r>
   2swap 2dup >r >r		( b-adr b-len dir endp-d ) ( R: endp-d dir )
   add-data-transfer				( R: endp-d dir )
   r> r@  add-ack-transfer			( R: endp-d )
   r> dup enque-control			( endp-d )
   dup wait-for-last-reply		( endp-d code )
   dup  if  over wipe-endpoint  then
   swap deque-control			( code )
   translate-code
   ?.error
;

headers

\ Must set skip if dir is out, as there is no data to transfer yet.
: set-endp-dir  ( dir endp-adr -- )
   over  if  dup skip-endp  then
   endpoint-control tuck le-l@
   h# ffff.e7ff and
   swap  if  out-bits  else  in-bits  then
   d# 11 lshift  or
   swap le-l!
;

\ XXX hack1 to set the toggle for the starting transfer-d in the endp-d
: set-endp-toggle  ( toggle endp-adr -- )
   td-head tuck le-l@
   swap 1+ 2 and  or  swap
   le-l!
;

: set-trans-toggle  ( toggle transfer-d -- )
   transfer-control tuck  le-l@
   h# fcff.ffff and  swap d# 24 lshift  or
   swap le-l!
;

: (use-endp-toggle)  ( endp-d -- )
   dup td-tail@
   swap td-head@ dev>virt
   begin				( tail-adr next-adr )
      0 over set-trans-toggle
      2dup next-transfer le-l@ <>
   while
      next-transfer le-l@ dev>virt
   repeat
   2drop
;

\ XXX hack2 to set the transfer-d's to use the toggle in the endpoint-d
: use-endp-toggle  ( endp-d -- )
   dup td-head@ if  (use-endp-toggle)
   else  drop
   then
;

external

\ Data toggles are synchronized via a separate control endpoint transaction.
\ OHCI setup clearing an endpoint stall sets data toggle to 0.
\ Use set-feature to set an endpoint stall.  Use clear-feature to clear an
\ endpoint stall.

\ Want to execute this one as quickly as possible, so attach it to the
\ every-ms interrupt q.
\ toggle1 (0 or 1) is to be used first.  toggle2 is last-used.
\ mark the toggle in the endpoint-d.
\ XXX not good enough -- nak doesn't cause the transfer-d to be
\ retired.  need to wait only for 1 frame (nominally) rather than until reply.
: execute-1-interrupt
	( toggle1 low-speed? dir max-pkt buf-addr buf-len endpoint usb-adr
					-- toggle2  hw-err? | toggle2 stat 0 )
   2swap >r >r  2swap swap >r -rot
		( toggle1 low-spd? max-pkt endp u-adr) ( R: blen badr dir )
   make-endpoint		( toggle1 endp-adr )  ( R: blen badr dir )
   tuck set-endp-toggle
   r> r> r>  rot  3 pick  add-data-transfer
   dup use-endp-toggle				( endp-adr )
   dup d# 62 enque-interrupt
   dup 1-try-wait
   over end-toggle -rot
   dup  if  over wipe-endpoint  then
   swap deque-interrupt			( toggle2 code )
   translate-code
   ?.error
;


\ for now, token will be the endpoint descriptor address
\ token = 0 means it can't be scheduled -- possibly the interval is
\ too great or too small.
\ ms is the maximum gap between successive polls.
\ use the toggle in the endpoint-d.  use the dir in the endpoint-d.
\ This uses a local buffer for data transfer.  Then the report is copied into
\ the caller's buffer by int-transaction-status, and the buffer can be re-used.
\ disable-int-transactions throws away the local buffer.
\ XXX buf-adr moved to int-transaction-status implies that if dir is out,
\ there is no data to move when enable-int-transactions is executed.  So the
\ transaction should be skipped until int-transaction-status is called.
\ So if dir is out, the endpoint descriptor must be marked SKIP, and
\ int-transaction-status must unmark it.
\ set dir in endpoint descriptor, mark transfer to use endpoint dir.
: enable-int-transactions  ( ms toggle low-speed? dir max-pkt buf-len 
						endpoint usb-adr -- token )
   rot >r  2swap swap >r  -rot
		( ms toggle speed max-pkt endp usb-addr )  ( R: blen dir )
   make-endpoint	( ms toggle endp-adr ) ( R: blen dir )

   tuck set-endp-toggle		( ms endp-adr ) ( R: blen dir )
   r> over set-endp-dir		\ may need to skip endpoint
   r> over caller-len !
   dup caller-len @ get-chunk  over interrupt-buf !
   dup dup interrupt-buf @  over caller-len @
   rot 0 swap add-data-transfer	\ use target to host -- really use endp for dir
   dup use-endp-toggle		( ms endp-adr )
   tuck swap pick-q if		( endp endp q# )
      enque-interrupt
   else				( endp endp )	\ couldn't pick a q
\      dump data-transfer interrupt-buf if caller-len <>0
\      dump ack-transfer, data-transfer
\      clear-endpoint
\      ( endp ) toss-endpoint
\ XXX just to get going, since there is always a q:
      cr ." no q found -- error " cr
      2drop					\ XXX wrong
      0
   then
;

\ token is the address of the endpoint for the interrupt.  The endpoint is
\ placed in one spot on the interrupt tree.
\ toggle is the last one used.

: disable-int-transactions  ( token -- toggle )
   dup skip-endp
   d# 10 ms		\ XXX crude; wait for the distributor to have a chance
			\ to catch up with any transfers.  Could check if
			\ any are outstanding via transfer-count.
			\ XXX needed if stuff happens on 10 ms tick timer level.
   dup dump-done-q
   dup ping-pong
   dup dump-done-q
   dup end-toggle swap
   dup wipe-endpoint
   dup interrupt-buf @  over caller-len @  give-chunk
   deque-interrupt
;

headers

\ Possible optimization: Re-use the transfer descriptor, since it is
\ already allocated and partially ready for re-use.
\ For now, brute force: dump transfer-d and get a new one.

: re-arm-receive  ( endp-d -- )
   dup skip-endp next-frame		\ make sure endpoint is not active
\   >r r@ take-transfer-d's		\ re-use transfer-d's
   dup dump-done-q
   dup ping-pong
   dup dump-done-q			( endp-d )
   dup dup interrupt-buf @  over caller-len @
\ XXX use (add-data-transfer) to force a 0 len transfer??
   rot 0 swap add-data-transfer		\ dir is fake; take from endpoint
   dup use-endp-toggle
   unskip-endp
;

: forward-data  ( buf-addr endp-d -- )
   sync-mem
   >r r@ interrupt-buf @  swap  r> caller-len @  move
;

\ Copy data from internal buffer to buf-addr
: receive-int  ( buf-addr token -- hw-err? | stat 0 )
   dup done-waiting?  if
      dup code-done-q @ dup condition-code  if		\ reply had error
         nip nip
         condition-code translate-code
      else						\ reply ok
         drop
         dup re-arm-receive forward-data
         usb-ack 0
      then
   else  2drop  usb-nak 0
   then
;

\ XXX wrong;  but we have no devices needing out interrupt transactions yet
\ from memory to device.
\ Copy data from buf-addr to internal buffer.  UnSKIP the endpoint.
: send-int  ( buf-addr token -- hw-err? | stat 0 )
   2drop  2 0
;

: receive-int?  ( token -- in? )
   endpoint-control le-l@
   h# 0000.1800 and
   h# 0000.1000 =
;

external

\ token is the address of the endpoint for the interrupt.  The endpoint is
\ placed in one spot on the interrupt tree.
\ stat is ACK if interrupt fired, NACK if not, STALL if stalled.
\ Re-arms the endpoint.  Use its own buffers.  Copy to/from the provided buffer
\ when int-transaction-status is called.  The client can copy out/in the
\ provided buffer in between calls to int-transaction-status.
\ Must be cognizant of dir in enable-int-transactions, in order to know
\ which way to copy the data -- to or from the provided buffer.  Must also
\ unSKIP the endpoint if dir is out.

: int-transaction-status  ( buf-addr token -- hw-err? | stat 0 )
   dup receive-int?  if  receive-int  else  send-int  then
   ?.error
;


\ OHCI bulk transfers use IN or OUT token stages.  Sometimes can be followed
\ directly by a status stage with no data.  Otherwise data transfer stage.
\ IN finishes with 0 len transfer (or no transfer if problem with data).
\ OUT finishes with no extra transfer from host to target.  The data toggles
\ are synchronized via a separate control endpoint transaction.
: execute-bulk  ( toggle1 dir max-pkt buf-adr buf-len endpoint usb-addr
					-- toggle2 hw-err? | toggle2 stat 0 )
   2swap >r >r  >r 0 -rot r>		\ always full speed
   make-endpoint		( toggle dir endp-adr )  ( R: blen badr )
   rot over set-endp-toggle
   tuck r> r>			( endp-adr dir endp-adr badr blen )
   2swap add-data-transfer
   dup use-endp-toggle		( endp-adr )
   dup enque-bulk
   dup wait-for-last-reply
   over end-toggle -rot
   dup  if  over wipe-endpoint  then
   swap deque-bulk			( toggle2 code )
   translate-code
   ?.error
;


: set-isoc-endpoint  ( endp-d -- )
   endpoint-control dup le-l@
   h# 8000 or
   swap le-l!
;

: set-isoc-direction  ( dir endp-d -- )
   endpoint-control tuck
   le-l@ h# 1800 not and
   swap  if  h# 800  else  h# 1000  then  or
   swap le-l!
;

\ OHCI isoc transfers have IN or OUT token stages.  Then data stage.
\ No extra status stage.  No data toggles.
\ XXX not really correct, as the various packets can have their own error
\ codes.
\ XXX must be able to do 0 len transfers.  Really need to be given a transfer
\ schedule. probably should have both absolute and relative schedules.
\ XXX new stack -- schedule added
\ : execute-isochronous  ( buf-adrn cntn ... buf-adr1 cnt1 n absolute? frame#
\			    dir max-pkt endpoint usb-addr -- hw-err? )
: execute-isochronous  ( frame# dir max-pkt buf-adr buf-len endpoint usb-addr
				-- hw-err? )
\ XXX static allocation implies
\ XXX need to copy the buffer to our buffer in order to get dev-addr
   2swap >r >r  >r 0 -rot r>		\ always full speed
   make-endpoint			( frame# dir endp-d ) ( R: blen badr )
   dup set-isoc-endpoint
   tuck set-isoc-direction	( f# endp-d ) ( R: blen badr )
   r> r>			( f# endp-d badr blen )
   rot dup >r			( f# badr blen endp-d ) ( R: endp-d )
   add-isoc-transfer		( R: badr endp )
   r@ enque-isoc
   r> dup wait-for-last-isoc-reply	( endp-d code )
   swap deque-isoc			( code )
   translate-code
   ?.error
;

headers

2 value usb-address-counter

external

\ hub code needs to call up to get the next usb address to assign it
\ to a device it finds when it executes its own probe stuff at power on.
\ " next-usb-address" $call-parent.

\ Only addresses 2 thru 127 are valid to be assigned.  1 is reserved for the
\ root hub node.

: next-usb-address  ( -- n )
   usb-address-counter  d# 127 >  if
      0
   else
      usb-address-counter
      dup 1+ is usb-address-counter
   then
;

: current-frame  ( -- n )
   hcca frame# le-w@
;

headers

\ Clear stall from endpoint via endpoint 0:
: clear-stall  ( speed endpoint usb-adr -- hw-err? | stat 0 )
   >r
   request-blank >r			( R: usb-adr buf-adr )
   clear-feature-req h# 200 or  r@ request-type w!
   endpoint-stall r@ req-value le-w!
   r@ req-index le-w!			( speed ) ( R: usb-adr buf-adr )
   1 max-packet 0 0
   r> /request
   0 r> 2over >r >r			\ goes to endpoint 0
   execute-control
   r> r> give-chunk
;

\ clean up errors:  endpoint should be halted.  all transfer-d's should
\ be accounted for, either on the endpoint q or on one of its done-q's;
\ the controller shouldn't be fiddling with any.  they should really be
\ on the endpoint q.  dump all remaining transfer-d's.  halt the control
\ q, dump the endpoint, restart the control q.


\ XXX Need to instancify the code.

\ XXX Need to check the size of transfers to make sure it fits in one
\ transfer-d, or else make more of them.
