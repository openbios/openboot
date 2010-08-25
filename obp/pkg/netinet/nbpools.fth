\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nbpools.fth
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
id: @(#)nbpools.fth 1.1 04/09/07
purpose: Network buffer pool management
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ To speed packet processing time, we must be able to allocate space
\ quickly and must avoid copying data as packets move between protocol
\ layers. 
\
\ We preallocate many buffers large enough to hold a single packet
\ and a few buffers large enough to hold large datagrams. These
\ buffer pools are maintained as linked lists. Network level I/O is
\ performed using small buffers; large buffers are used when generating
\ or reassembling large datagrams.  An entire buffer is passed to IP
\ after reading a packet into it; data needs to be copied only when
\ dealing with large datagrams.
\
\ To make buffer processing uniform, a self-identifying buffer scheme
\ is used. Each buffer entry maintains its size using which the
\ buffer is returned to the appropriate (small or large) buffer pool
\ when freed.

headerless

struct
   /queue-entry field  >netbuf-link	\ Queue pointers
   /l           field  >netbuf-len	\ Buffer size
   0            field  >netbuf-adr	\ Buffer contents
constant /netbuf-hdr

\ Allocate memory for a network buffer
: netbuf-alloc ( bufsize -- netbuf )
   dup /netbuf-hdr + alloc-mem  dup queue-init  tuck >netbuf-len l!
;

\ Destroy a network buffer
: netbuf-free ( netbuf -- )
   dup >netbuf-len l@  /netbuf-hdr +  free-mem
;

\ Initialize a buffer pool
: netbuf-pool-create ( qhead bufsize nbufs -- )
   2 pick queue-init
   0 ?do  2dup netbuf-alloc enqueue  loop  2drop
;

\ Destroy a buffer pool
: netbuf-pool-destroy ( qhead -- )
   begin  dup dequeue  ?dup while  netbuf-free  repeat  drop
;

/queue-head instance buffer:  netpkt-bufq	\ Network packet buffer pool
/queue-head instance buffer:  lrgpkt-bufq	\ Large packet buffer pool

d#    32  constant NETPKT_POOL_SIZE	\ Number of network packet buffers
d#     4  constant LRGPKT_POOL_SIZE	\ Number of large packet buffers

\ Allocate a frame from the network packet buffer pool
: frame-alloc ( -- frame )
   netpkt-bufq dequeue dup if  >netbuf-adr  then
;

\ Return a frame to the network packet buffer pool
: frame-free ( frame -- )
   netpkt-bufq swap /netbuf-hdr - enqueue
;

\ Allocate a packet from the network packet buffer pool
: pkt-alloc ( -- pkt )
   netpkt-bufq dequeue dup if  >netbuf-adr if-hdrlen@ +  then
;

\ Allocate a packet from the large packet buffer pool
: lrgpkt-alloc ( -- pkt )
   lrgpkt-bufq dequeue dup if  >netbuf-adr if-hdrlen@ +  then
;

\ Return a packet to the pool from which it was allocated
: pkt-free ( pkt -- )
   if-hdrlen@ -  /netbuf-hdr -			( netbuf )
   dup >netbuf-len l@  if-frame-size@ =  if	( netbuf )
      netpkt-bufq				( netbuf netpkt-qhead )
   else						( netbuf )
      lrgpkt-bufq				( netbuf lrgpkt-qhead )
   then						( netbuf qhead )
   swap enqueue					( )
;

\ Enqueue a packet buffer in the specified queue
: pkt-enqueue ( qhead pkt -- )
   if-hdrlen@ - /netbuf-hdr - enqueue
;

\ Dequeue a packet buffer from the specified queue
: pkt-dequeue ( qhead -- pkt )
   dequeue dup if  >netbuf-adr if-hdrlen@ +  then
;

\ Initialize network buffer pools
: init-nbpools ( -- )
   netpkt-bufq if-frame-size@              NETPKT_POOL_SIZE netbuf-pool-create
   lrgpkt-bufq IP_MAX_PKTSIZE if-hdrlen@ + LRGPKT_POOL_SIZE netbuf-pool-create
;

\ Destroy network buffer pools
: free-nbpools ( -- )
   netpkt-bufq netbuf-pool-destroy
   lrgpkt-bufq netbuf-pool-destroy
;

headers
