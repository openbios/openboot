\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hub-requests.fth
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
id: @(#)hub-requests.fth 1.9 02/04/10
purpose: 
copyright: Copyright 1998-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

-1 instance value request-blank  ( -- addr )	\ XXX assumes can be allocated at open
-1 instance value common-buffer  ( -- addr )	\ XXX ditto; also assumes it will be
						\ large enough
1000 constant /common-buffer		\ XXX is it large enough?  too large?

d# 64 instance value child-max  ( -- n )	\ use to talk to child device endpt 0

\ XXX The following is for 2.0 hubs; benign for 1.0 hubs
d# 64 value 0max-packet  ( -- n )	\ for my endpoint 0; from descriptor;
					\ global ok

d# 64 instance value max-packet  ( -- n )	\ must be set before usb transactions

: clean-request-blank  ( -- addr )
   request-blank /request erase
   request-blank
;

: clean-common-buffer  ( -- addr )
   common-buffer /common-buffer erase
   common-buffer
;

: descript-form  ( len -- addr )
   clean-request-blank
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
   clean-request-blank
   set-address-req over request-type w!
   swap over req-value le-w!
;

: speed  ( -- low-speed? )			\ could do once and save
   " low-speed" get-my-property  if
      false
   else  2drop  true
   then
;

: my-usb-addr  ( -- usb-addr )			\ could do once and save
   " assigned-address" get-inherited-property  if
      " No assigned-address property" diag-crtype	\ XXX for debugging;
						\ totally bad situation
   else  decode-int  nip nip
   then
;

\ No data transfer, hub only, endpoint 0:
: simple-control  ( req-addr -- hw-err? | stat 0 )
   max-packet >r
   0max-packet to max-packet
   >r
   speed 1
   max-packet 0 0
   r> /request
   0 my-usb-addr
   execute-control
   r> to max-packet
;

\ Always uses common-buffer, hub only, endpoint 0:
: data-in-control  ( req-addr len -- addr hw-err? | addr stat 0 )
   max-packet >r
   0max-packet to max-packet
   swap  >r >r
   clean-common-buffer
   speed 0				\ data in transfer
   max-packet
   common-buffer r>
   r> /request
   0 my-usb-addr
   execute-control
   r> to max-packet
;

\ Submit requests over USB, so these all turn into USB transactions,
\ all to endpoint 0 via control transfers:

: clear-hub-feature  ( feature# -- hw-err? | stat 0 )
   clean-request-blank
   clear-hub-feature-req over request-type w!
   swap over req-value le-w!		( req-addr )
   simple-control
;

: clear-port-feature  ( feature# port# -- hw-err? | stat 0 )
   clean-request-blank
   clear-port-feature-req over request-type w!
   swap over req-index le-w!
   swap over req-value le-w!		( req-addr )
   simple-control
;

: get-hub-descript  ( len -- addr hw-err? | addr stat 0 )
   dup >r
   clean-request-blank				\ fill request blank
   get-hub-descript-req over request-type w!
   swap over req-len le-w!
   hub-descript over req-value 1+ c!	( req-addr ) ( R: len )
   r> data-in-control
;

: get-hub-status  ( -- addr hw-err? | addr stat 0 )
   clean-request-blank
   get-hub-status-req over request-type w!
   4 over req-len le-w!			( req-addr )
   4 data-in-control
;

: get-port-status  ( port# -- addr hw-err? | addr stat 0 )
   clean-request-blank
   get-port-status-req over request-type w!
   4 over req-len le-w!
   swap over req-index le-w!		( req-addr )
   4 data-in-control
;

\ : set-hub-feature  ( XXX -- XXX )
\ ;

: set-port-feature  ( feature# port# -- hw-err? | stat 0 )
   clean-request-blank
   set-port-feature-req over request-type w!
   swap over req-index le-w!
   swap over req-value le-w!
   simple-control
;

\ status change endpoint 1 is interrupt.  It reports the hub and port
\ status change bitmap, 11.8.3, at max polling interval ff.

\ For error recovery -- stalls
\ endp* is endpoint number with direction bit in high order bit.
\  In = 1;
\ Out = 0
\ status bytes left at addr.  uses common-buffer
: endpoint-status  ( endp* -- addr hw-err? | addr stat 0 )
   >r
   clean-common-buffer
   get-status-req h# 200 or  clean-request-blank request-type w!
   r@ request-blank req-index le-w!
   2 request-blank req-len le-w!	( buf-adr ) ( R: endp* )
   speed 0 max-packet common-buffer 2
   request-blank /request
   r> 0f and				\ cut off direction bit
   my-usb-addr
   execute-control
;

: stalled?  ( endp* -- stalled? )
   endpoint-status
   ?dup 2drop
   le-w@  1 and
;

\ For debugging.  Force an endpoint stall.
\ uses request-blank
: stall-endpoint  ( endpoint -- hw-err? | stat 0 )
   set-feature-req h# 200 or  clean-request-blank request-type w!
   endpoint-stall request-blank req-value le-w!
   dup request-blank req-index le-w!
   >r
   speed 1 max-packet 0 0		\ no data transfer
   request-blank /request
   r>  my-usb-addr
   execute-control
;

\ must set max-packet before using.
\ uses request-blank; no dma-free needed
: clear-stall  ( speed endpoint usb-adr -- hw-err? | stat 0 )
   >r
   clear-feature-req h# 200 or  clean-request-blank request-type w!
   endpoint-stall request-blank req-value le-w!
   request-blank req-index le-w!
   1 max-packet 0 0		\ no data transfer
   request-blank /request
   0 r>
   execute-control
;
