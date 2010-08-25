\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: udp.fth
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
id: @(#)udp.fth 1.1 04/09/07
purpose: UDP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 768: User Datagram Protocol

fload ${BP}/pkg/netinet/udp-h.fth

headerless

/queue-head  instance buffer:  udp-inpcb-list	\ Head of UDP's INPCB list

: udp-init  ( -- )  udp-inpcb-list queue-init ; 
: udp-close ( -- )  ;

\ Allocate UDP control block.
: ucb-alloc ( -- ucb )
   /udp-control-block dup alloc-mem tuck swap erase	( ucb )
   dup >ucb-dgramq queue-init				( ucb )
;

\ Free resources held by UDP control block.
: ucb-free ( ucb -- )
   dup >ucb-dgramq					( ucb qhead )
   begin  dup pkt-dequeue  ?dup while			( ucb qhead pkt )
      pkt-free						( ucb qhead )
   repeat  drop						( ucb )
   /udp-control-block free-mem				( )
;

\ Compute UDP packet checksum.
: udp-checksum ( ip-pkt -- checksum )
   IPPROTO_UDP  over >ip-src  /ip-addr    (in-cksum)
                over >ip-dest /ip-addr    (in-cksum)
   swap  ippkt>payload  rot over +  -rot  in-cksum
;

\ Verify UDP packet checksum. The checksum field will be zero if the
\ sender did not compute a checksum.
: udp-checksum-ok? ( udpip-pkt -- flag )
   dup >udp-cksum ntohw@ 0=  swap  udp-checksum 0=  or
;

\ Check if datagram is for this INPCB
: ucb-match? ( pkt inpcb -- pkt match? )
   over >udp-dport ntohw@  over in-lport@ =  if		( pkt inpcb )
      over >ip-dest  over >in-laddr  ip=  if		( pkt inpcb )
         drop true					( pkt true )
      else						( pkt inpcb )
         >in-laddr inaddr-any?				( pkt match? )
      then						( pkt match? )
   else							( pkt inpcb )
      drop false					( pkt false )
   then							( pkt match? )
;

\ UDP demultiplexing.
: ucb-locate ( pkt -- ucb | 0 )
   udp-inpcb-list  ['] ucb-match?  find-queue-entry nip  dup if
      inpcb>ucb
   then
;

\ Handle incoming UDP datagram.
: udp-input ( pkt -- )
   dup udp-checksum-ok?  if				( pkt )
      dup ucb-locate  ?dup if				( pkt ucb )
         >ucb-dgramq swap pkt-enqueue			( )
      else						( pkt )
         pkt-free					( )
      then						( )
   else							( pkt )
      pkt-free						( )
   then							( )
;
['] udp-input to (udp-input)

\ Format and send the UDP datagram.
: udp-output ( inpcb data len -- #sent | error# )
   pkt-alloc ?dup 0=  if  3drop 0 exit  then		( inpcb data len pkt )
   over >r						( inpcb data len pkt )
   dup /udpip-header +  2swap rot swap move		( inpcb pkt ) ( r: len )

   IPPROTO_UDP         over >ip-protocol  c!
   my-ip-addr          over >ip-src       copy-ip-addr
   over >in-faddr      over >ip-dest      copy-ip-addr
   IP_DEFAULT_TTL      over >ip-ttl       c!
   0                   over >ip-service   c!
   r@ /udpip-header +  over >ip-len       htonw!	( inpcb pkt )

   over in-lport@      over >udp-sport    htonw!	( inpcb pkt )
   swap in-fport@      over >udp-dport    htonw!	( pkt )
   r@ /udp-header +    over >udp-len      htonw!	( pkt )
   0                   over >udp-cksum    htonw!	( pkt )
   dup udp-checksum    over >udp-cksum    htonw!	( pkt )

   ip-output						( #sent | error# )
   r> drop						( #sent | error# )
;

: udp-poll ( -- )  ip-poll ;

headers
