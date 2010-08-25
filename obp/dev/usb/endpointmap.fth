\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: endpointmap.fth
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
id: @(#)endpointmap.fth 1.9 98/03/17
purpose: 
copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

\ XXX need to re-do this, as the fields may not line up correctly for
\ @ and ! especially for-controller, ping- and pong-
struct
   4 field endpoint-control
   4 field td-tail
   4 field td-head
   4 field next-endpoint
  /n field prev-endpoint		\ used by software only, virt
					\ 0 means first on q
  /n field q-id				\ this endpoint is on the q q-id
   4 field dummy?			\ false if this is a real endpoint
\ These next 3 fields are dependent on being in this order and together:
  /n field for-controller		\ 0 if reply distributor puts
					\ transfer descriptors on ping-q,
					\ /n if distributor puts onto pong-q.
  /n field ping-done-q			\ 0 if no transfer-d's here, virt
  /n field pong-done-q			\    ditto
\  /n field caller-buf
  /n field caller-len
  /n field interrupt-buf		\ used for interrupt transfers, virt
  /n field transfer-count	\ number of real transfer d's outstanding
   h# 10 over h# 10 mod -		\ pad to next 16 byte boundary
     field endpad

( endpoint descrip. size ) constant /endpoint

\ XXX The above allocation wastes a dictionary entry for endpad and 16 bytes
\ of space if the other fields add up to 0 mod 16.  Can save the dict. space
\ by pushing calculation into the size of transfer-count

\ q-id above is needed so that if a transfer descriptor on the done q shows
\ an error which requires flushing other descriptors for its endpoint, and
\ the endpoint has no transfer descriptors left after flushing, and hence
\ the endpoint should be pulled off the q, the software can figure out
\ which code should be used to pull the endpoint off the q.

\ dummy? above is needed to help figuring out the ends of the interrupt q's
\ more easily, instead of checking whether a particular address of an
\ endpoint is actually the start of the next q.

\ ping-done-q and pong-done-q, with for-controller, are used as done q's for
\ this endpoint.  The reply distributor code moves transfer descriptors from
\ the done q of the controller to (only) one of these endpoint done q's.
\ The endpoint reply processing code takes transfer descriptors from the
\ other ping-pong done q.  This avoids a race condition between the distributor
\ code and the processing code.
\ ping- and pong-done-q hold virtual addresses.  The transfer descriptors
\ themselves are linked via the next-transfer field, which holds dev addresses,
\ little endian.

\ transfer-count does not include the dummy transfer-d.

\ 0-3e (0-62) are interrupt q id's.
d# 63 constant isoc-id
d# 64 constant control-id
d# 65 constant bulk-id

d# 66 constant #dummy-qs

: isoc-endpoint?  ( e-addr -- isoc? )
   endpoint-control le-l@ h# 8000 and
;

: dummy-endpoint?  ( e-addr -- dummy? )  dummy? l@  ;

: halted?  ( e-addr -- halted? )  td-head le-l@  1 and  ;

: end-toggle  ( e-addr -- toggle )  td-head le-l@ 2 and 1 rshift  ;

: skip-endp  ( e-addr -- )
   endpoint-control dup le-l@
   h# 4000 or
   swap le-l!
;

: unskip-endp  ( e-addr -- )
   endpoint-control dup le-l@
   h# 4000 invert and
   swap le-l!
;

\ Need to leave some td-tail bits alone:
: td-tail@  ( e-addr -- td-tail )  td-tail le-l@  h# f invert and  ;

: td-tail!  ( n e-addr -- )
   td-tail tuck le-l@  h# f and  or
   swap le-l!
;

\ Need to leave some td-head bits alone:
: td-head@  ( e-addr -- n )  td-head le-l@  h# f invert and  ;

: td-head!  ( n e-addr -- )
   td-head tuck le-l@  h# f and  or
   swap le-l!
;

\ Need to leave some next-endpoint bits alone:
: next-endpoint@  ( e-addr -- n )  next-endpoint le-l@  h# f invert and  ;

: next-endpoint!  ( n e-addr -- )
   next-endpoint tuck le-l@  h# f and  or
   swap le-l!
;

: empty-endp?  ( e-addr -- empty? )
   dup td-tail@  swap td-head@  =
;

: stopped?  ( e-addr -- empty?-or-halted? )
   dup empty-endp?
   swap halted?  or
;

: code-done-q  ( endpoint -- q-head )
   dup ping-done-q  swap for-controller @  /n - abs  +
;

: ping-pong  ( endpoint -- )
   dup for-controller @
   /n - abs
   swap for-controller !
;

\ XXX the endpoints/transfers can't have a device address of 0, or the
\ chip won't function correctly when traversing the q's.  The code to detect
\ q ends won't work either.

\ XXX the various queued descriptors have alignment restrictions

\ 63 dummy interrupt endpoint descriptors are arranged so that the
\ next-endpoint fields hook them together in a tree.  See ohci 3.3.2,
\ figure 3-4.  These are marked SKIP.  There are no transfer descriptors,
\ since they will never be activated.  When a real interrupt endpoint is
\ desired, it is hooked into the interrupt tree after the dummy endpoint at
\ a spot for its interrupt interval.  The dummies remain on the tree.  They
\ use q-ids 0 through 62.  They are each considered to be head of q, so
\ prev-endpoint is 0 for each of them.

\ Level 1 of the tree is directly connected to the interrupt slots in hcca,
\ dummies 0 thru 31.  Level 2 of the tree (dummies 32 thru 47) is connected
\ to level 1 dummies.  Level 3 (dummies 48 thru 55) is connected to level 2.
\ Level 4 (dummies 56 thru 59) is connected to level 3.  Level 5 (dummies 60
\ thru 61) is connected to level 4, and level 6 (dummy 62) is connected to
\ level 5.  The dummies are connected so as to space the times for each
\ entry of each level evenly through the 32 millisecond round robin cycle
\ of periodic frame processing.

\ Interrupt endpoints on level 1 are processed once per 32 msec.  Level 2
\ endpoints are processed once per 16 msec.  Level 3 endpoints are processed
\ once per 8 msec.  Level 4 endpoints go once per 4 msec.  Level 5 endpoints
\ run once per 2 msec, and level 6 endpoints run every msec.

\ Connection algorithm:
\  Start with level 1 -- dummies 0 thru 31.  Each is connected to the same
\	number slot in the interrupt table as its q-id.
\	Each is connected to a dummy in level 2 whose q-id is determined thus:
\		1. change bit 4 of its q-id to 0.
\		2. change bit 5 of its q-id to 1.
\  Each level 2 dummy is connected to a level 3 dummy whose q-id is determined:
\		1. change bit 3 of its q-id to 0.
\		2. change bit 4 of its q-id to 1.
\  Connect all level 3 dummies to level 4 dummies:
\		1. change bit 2 of the q-id to 0.
\		2. change bit 3 of the q-id to 1.
\  Level 4 dummies connect to level 5 dummies:
\		1. change bit 1 of the q-id to 0.
\		2. change bit 2 of the q-id to 1.
\  Connect both level 5 dummies to level 6:
\		1. change bit 0 of the q-id to 0.
\		2. change bit 1 of the q-id to 1.

\  0\
\    32\
\ 16/   \
\        48\
\  8\   /   \
\    40/     \
\ 24/         \
\              56\
\  4\         /   \
\    36\     /     \
\ 20/   \   /      |
\        52/       |
\ 12\   /          |
\    44/           |
\ 28/              |
\                  60\
\  2\              |  \
\    34\           |   \
\ 18/   \          |   |
\        50\       |   |
\ 10\   /   \      |   |
\    42/     \     /   |
\ 26/         \   /    |
\              58/     |
\  6\         /        |
\    38\     /         |
\ 22/   \   /          |
\        54/           |
\ 14\   /              |
\    46/               |
\ 30/                  |
\                      62
\  1\                  |
\    33\               |
\ 17/   \              |
\        49\           |
\  9\   /   \          |
\    41/     \         |
\ 25/         \        |
\              57\     |
\  5\         /   \    |
\    37\     /     \   |
\ 21/   \   /      |   |
\        53/       |   |
\ 13\   /          |   |
\    45/           |   /
\ 29/              |  /
\                  61/
\  3\              |
\    35\           |
\ 19/   \          |
\        51\       |
\ 11\   /   \      |
\    43/     \     /
\ 27/         \   /
\              59/
\  7\         /
\    39\     /
\ 23/   \   /
\        55/
\ 15\   /
\    47/
\ 31/

\ XXX code to balance the tree is desired.

\ The control, bulk, and isochronous q's each have one dummy start endpoint
\ descriptor that has no transfer descriptors.  Each dummy is marked with
\ SKIP.  Each is considered to be head of q, so prev-endpoint is 0.

\ The isoc q dummy hooks onto the end of interrupt q 62.  It is marked as
\ isochronous endpoint format.

\ XXX Bandwidth problems or chip problems may require going back to the
\ earlier q style, with no dummy q heads.

0 value dummy-endpoints
0 value dev-dummy-endpoints
/endpoint #dummy-qs * constant /dummies

: sync-dummies  ( -- )  sync-mem  ;

\ The interrupt dummies come first:
: interrupt-dummy  ( q-id -- addr )  /endpoint * dummy-endpoints +  ;

: dev-interrupt-dummy  ( q-id -- devaddr )
   /endpoint * dev-dummy-endpoints +
;


: isoc-dummy  ( -- addr )  isoc-id interrupt-dummy  ;

: dev-isoc-dummy  ( -- devaddr )  isoc-id dev-interrupt-dummy  ;

: control-dummy  ( -- addr )  control-id interrupt-dummy  ;

: dev-control-dummy  ( -- devaddr )  control-id dev-interrupt-dummy  ;

: bulk-dummy  ( -- addr )  bulk-id interrupt-dummy  ;

: dev-bulk-dummy  ( -- devaddr )  bulk-id dev-interrupt-dummy  ;


: plugdummy  ( devaddr q-id -- )
   interrupt-dummy next-endpoint le-l!
;

\ XXX could use two nested loops, passing in the level to a common routine:
: getnext1  ( q-id -- devaddr )	\ devaddr of next for level 1 of int dummies
   h# 10 invert and  h# 20 or  dev-interrupt-dummy
;

: getnext2  ( q-id -- devaddr )
   8 invert and  h# 10 or  dev-interrupt-dummy
;

: getnext3  ( q-id -- devaddr )
   4 invert and  8 or  dev-interrupt-dummy
;

: getnext4  ( q-id -- devaddr )
   2 invert and  4 or  dev-interrupt-dummy
;

: getnext5  ( q-id -- devaddr )
   1 invert and  2 or  dev-interrupt-dummy
;

: connect-dummies  ( -- )	\ connect the interrupt dummies into a tree
   d# 32  0  do				\ connect 1st to 2nd level
      i getnext1 i plugdummy
   loop
   d# 48  d# 32  do			\ connect 2nd to 3rd level
      i getnext2 i plugdummy
   loop
   d# 56  d# 48  do			\ connect 3rd to 4th level
      i getnext3 i plugdummy
   loop
   d# 60  d# 56  do			\ connect 4th to 5th level
      i getnext4 i plugdummy
   loop
   d# 62  d# 60  do			\ connect 5th to 6th level
      i getnext5 i plugdummy
   loop
   dev-isoc-dummy d# 62 plugdummy	\ connect isoc dummy to int 62
;

: skip-dummies  ( -- )			\ mark dummies to be skipped
   dummy-endpoints dummy?			\ mark as dummies
   #dummy-qs 0  do
      true over l!  /endpoint +
   loop drop
   dummy-endpoints endpoint-control		\ mark to be skipped
   #dummy-qs 0  do
      h# 4000 over le-l!  /endpoint +
   loop drop
   h# c000 isoc-dummy endpoint-control le-l!	\ mark isoc q head format
;

: name-dummies  ( -- )			\ set q-ids
   dummy-endpoints q-id
   #dummy-qs 0  do
      i over !  /endpoint +
   loop drop
;

: make-dummies  ( -- )
   /dummies get-chunk  to dummy-endpoints
   dummy-endpoints  virt>dev to dev-dummy-endpoints
   skip-dummies
   connect-dummies
   name-dummies
   sync-dummies
;

: dump-dummies  ( -- )
   -1 to dev-dummy-endpoints
   dummy-endpoints /dummies give-chunk
   -1 to dummy-endpoints
;


\ : dev-dummy?  ( dev-addr -- dev-dummy? )	\ true if a dummy dev addr.
\   dev-dummy-endpoints /dummies bounds swap  between
\ ;

: dummydev>virt  ( dev-addr -- virt )		\ for dummies
   dev>virt
;
