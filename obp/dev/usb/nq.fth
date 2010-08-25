\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nq.fth
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
id: @(#)nq.fth 1.4 99/09/21
purpose: 
copyright: Copyright 1997-1999 Sun Microsystems, Inc.  All Rights Reserved

\ Look down the q until the next-endpoint is 0 (which will be on the last
\ descriptor), or next-endpoint points to a dummy q (which will be on the
\ last of one of the interrupt q's).
: find-last-endpoint  ( addr1 -- addr2 )
   begin						( e-addr )
      dup next-endpoint@				( curr-addr nxt-addr )
      dup  if  dev>virt dummy-endpoint? invert  then	( e-addr use-next? )
   while  next-endpoint@ dev>virt
   repeat
;

\ Stick new endpoints only on the end of the q.  So even for the interrupt
\ q's, any following endpoint does not need its prev-endpoint pointer changed,
\ since it is head of queue and has prev = 0.
\ So this endpoint descriptor and the previous one are the ones that must be
\ synced.
: e>q  ( addr q-id -- )			\ endpoint to q-id
   2dup swap q-id !
   interrupt-dummy find-last-endpoint >r
   dup  r@ next-endpoint@			\ there are other q's, so
   swap next-endpoint!				\ copy next into this one
   r> swap 2dup prev-endpoint !			\ hook this one in
   2dup virt>dev swap next-endpoint!		( prev-ep cur-ep )
   sync-endpoint sync-endpoint
;

\ XXX need to carry data toggle from endpoint descriptor forward from
\ transfer descriptor to transfer descriptor?  it is returned in the
\ endpoint descriptor.
\ No, let the transfer descriptor handle it -- which means the child
\ device, essentially.  This works for control transactions, but seems
\ cumbersome for interrupt transactions.

\ The endpoint descriptors must have at least a null transfer descriptor
\ attached before putting the endpoint desc. on a queue to avoid a race
\ condition when queueing real transfer descriptors.
\ The last transfer descriptor is not touched by the chip (ohci 4.6).

: make-transfer-d  ( -- addr )
   /transfer get-chunk
;

\ Assume no endpoint will be put on q unless it has a real transfer
\ descriptor.
\ endpoint direction from transfer descriptors
: make-endpoint  ( speed max-pkt endpt usb-addr -- addr )
   /endpoint get-chunk >r
   swap 7 lshift  or  swap h# 10 lshift  or
   swap if  h# 2000 or  then
   r@ endpoint-control le-l!  r>
\ Make empty transfer-d and attach.
   make-transfer-d  virt>dev
   tuck over td-tail!  tuck td-head!
;


: transfer-bits>copy-in?  ( transfer-d endp-bits -- copy-in? dummy )
   swap transfer-control le-l@
   d# 19 rshift  3 and				\ dp bits
   2 <						\ setup or out
   swap
;

: copy-in?  ( transfer-d -- copy-in? )
   dup my-endpoint @ endpoint-control le-l@
   d# 11 rshift  3 and				\ d bits
   case  1 of  drop true   endof
         2 of  drop false  endof
      transfer-bits>copy-in?
   endcase
;

\ for setup packets or out packets -- need to look at endp-d
: copy-in  ( transfer-d -- )
   dup copy-in?  if
      dup caller-data @
      over my-data @
      rot caller-count @
      move
   else  drop
   then
;

: copy-for-me  ( transfer-d -- )
   dup caller-count @ ?dup  if		\ a real transfer
      get-chunk	over my-data !		\ make a copy buffer
      copy-in
   else  drop
   then
;

: my-dev-data  ( transfer-d -- dev-data-adr )
   my-data @  dup  if  virt>dev  then
;

: buffer-bounds  ( transfer-d -- )
   dup my-dev-data over curr-buffer le-l!
   dup my-dev-data over caller-count @  +
   dup if  1-  then			\ may be a 0 len transfer
   swap buffer-end le-l!
;

\ XXX don't allow caller-addr <>0 with caller-len = 0.  the other way
\ is ok (for interrupt transfers).
\ bufferRounding, no DelayInterrupt
: fill-transfer-d  ( caller-data-adr buf-len toggle pid-code transfer-adr -- )
   >r
   d# 19 lshift  h# 4.0000 or  swap d# 24 lshift  or
   r@ transfer-control le-l!		( caller-addr len ) ( R: transfer-d )
   r@ caller-count !
   r@ caller-data !
   r@ copy-for-me
   r> buffer-bounds
;


\ buffer to hold offsets so they can be reversed; 100 nominal
h# 100 buffer: isoc-temp		\ must be global

: make-isoc-offsets  ( dev-badr blen -- offset7 ... offset0 )
   isoc-temp h# 100 erase
   isoc-temp 0 2swap		( buf-adr index dev-badr blen )
   swap h# fff and swap		\ only bottom 12 bits needed
   bounds  do			( buf-adr index )
      2dup na+
      i swap !
      1+
   d# 1023 +loop
   drop				( buf-adr )
   0 7  do
      dup i na+ @ swap
   -1 +loop			( off7 ... off0 buf-adr )
   drop
;

: fill-isoc-offsets  ( offset7 ... offset0 transfer-d -- )
   4 0 do
      >r
      swap wljoin
      r@ offset0 i 4 * + le-l!
      r>
   loop
   drop
;

: (set-isoc-offsets)  ( dev-badr blen transfer-d -- )
   >r
   dup d# 1023 /mod
   swap if  1+  then
   1-  7 and  d# 24 lshift
   r@ isoc-control tuck
   le-l@ h# f8ff.ffff and  or
   swap le-l!				( dev-badr blen ) ( R: transfer-d )
   make-isoc-offsets
   r> fill-isoc-offsets		\ fill in the offsets from offsets on stack
;

\ ohci 4.3.2.3.5.4 says max isoc data packet 3ff (1023) bytes, but the
\ transfer descriptor seems to allow 400 (1024) bytes.
\ uhci 3.2.3 says max len is 1023 also, and says it's in the usb spec.
\ it also says that 1280 is the max theoretical for one frame.
\ usb 5.6.3 says 1023 bytes max
\ each page 4K, two pages max.
: set-isoc-offsets  ( dev-badr blen transfer-d -- )
   over  if  (set-isoc-offsets)  then
;

\ XXX isoc transfer direction seems to be in the endpoint, not the transfer
\ no DelayInterrupt
: fill-isoc-transfer-d  ( f# caller-d dev-badr blen transfer-d -- )
   >r  r@ /transfer erase
   over h# ffff.f000 and
   r@ buff-page le-l!
   2dup +  over if  1-  then		\ could be 0 len transfer
   r@ buffer-end le-l!
   r@ set-isoc-offsets			( f# caller-d ) ( R: transfer-d )
   r@ caller-data !
   h# ffff and				\ only least 16 bits of frame used
   r> isoc-control tuck le-l@
   h# ffff.0000 and
   or swap le-l!
;


\ The data gets copied into the last transfer descriptor, a new empty
\ descriptor gets hooked to it, then the tail pointer is updated to point
\ to the new empty one.

\ transfer to endpoint q:
: t>endq  ( caller-data-adr buf-len toggle pid-code endpoint-addr -- )

	\ Find last transfer d on q:
   >r r@ td-tail@ dev>virt		( ... tail-trans-d-addr )
   r@ over my-endpoint !

	\ Put transfer info into the last one on the q:
   dup >r fill-transfer-d r>		( tail-d-addr )  ( R: endpt-addr )

   make-transfer-d			( tail-addr new-last-addr )

	\ Hook new one into old tail d:
   virt>dev tuck swap next-transfer le-l!   ( tail-addr new-last new-dev-addr )
   1 r@ transfer-count +!		\ bump transfer count
   r> td-tail!				\ Update td-tail in the endpoint d
   sync-mem
;

\ XXX no dev-badr
\ isoc transfer to endpoint q:
: isoct>endq  ( f# caller-d dev-badr blen endp-d -- )
   >r r@ td-tail@ dev>virt		( ... tail-transfer-d )
   dup >r fill-isoc-transfer-d		( -- ) ( R: endp-d tail-d )
   r> dup r@ swap my-endpoint !
   make-transfer-d			( tail-addr new-last-addr )

	\ Hook new one into old tail d:
   virt>dev tuck swap next-transfer le-l!   ( tail-addr new-last new-dev-addr )
   1 r@ transfer-count +!		\ bump transfer count
   r> td-tail!				\ Update td-tail in the endpoint d
\ XXX should fill my-endpoint for the new last descriptor.
   sync-mem
;


\ Two alternative strategies:

\ 1. Each request from child node gets essentially one endpoint with a string
\ of transfers. when transfer finishes, retire the endpoint.
\ 2. the same endpoint can be used for more than one request from child node.

\ I lean towards 1.  This means that it probably makes most sense for the
\ endpoint to have all its transfer d's installed before putting the endpoint
\ on the q.


\ : low-bits?  ( n high-bit -- low-bits? )
\   xor
\ ;

: find-high-bit  ( n1 -- n2 )
   dup h# 20 and  if  drop h# 20 exit  then
   dup h# 10 and  if  drop h# 10 exit  then
   dup     8 and  if  drop     8 exit  then
   dup     4 and  if  drop     4 exit  then
           2 and  if  2  else  1  then
;

\ : next-power-of-two  ( n -- power )
\   dup find-high-bit
\   tuck  low-bits?  if  1+  then
\ ;

: prev-power-of-two  ( n -- power )
   find-high-bit
;

\ Use power to find the correct range of q's.  Maybe use ms to "hash" into
\ the range for the specific q.  Should also take into account the loading
\ of the various q's.
\ XXX Stupid algorithm, pick the last q of the right priority.
\ It always works:
: choose-q  ( ms power -- [q#] q-found? )
   nip  d# 63 swap -
   true
;

\ Pick the q to use based on ms, the maximum polling interval, and the
\ loading of the various q's with that interval.
\ q-found? is non-false if it was able to pick a q.  If q-found? is non-false,
\ q# is returned also.
\ Use semi-brute-force:  The numbers are only up to 32, so for the valid
\ ones, 1) mask for the high bit, 2) check for any low bits, and 3) if there
\ are low bits, double the high bit.  This gets to the next greater
\ power-of-two.
\ Previous algorithm uses minimum polling interval.  For maximum polling
\ interval, semi-brute-force:  1) mask for the high bit.  This gets to the
\ previous power-of-two.
: pick-q  ( ms -- [q#] q-found? )
   dup 0<= over d# 32 > or  if			\ out of range
      drop 0
   else
      dup prev-power-of-two			( ms power )
      choose-q
   then
;

\ XXX There should be a bandwidth check when adding and deleting transfers and
\ endpoints.  And picking q's?
