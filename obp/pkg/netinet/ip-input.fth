\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ip-input.fth
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
id: @(#)ip-input.fth 1.1 04/09/07
purpose: IP input routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 815: IP Datagram Reassembly Algorithms

fload ${BP}/pkg/netinet/ipreasm-h.fth

headerless

/queue-head  instance buffer:  iprd-list	\ Reassembly descriptor list

\ Create a new frag hole descriptor entry
: ipfhd-create ( start end -- ipfhd )
   /ipf-hole-descriptor alloc-mem		( start end ipfhd )
   tuck >ipfhd-end l!  tuck >ipfhd-start l!	( ipfhd )
;

\ Free a frag hole descriptor entry
: ipfhd-free ( ipfhd -- )  /ipf-hole-descriptor free-mem  ;

\ Hole descriptor list initialization. The initial entry describes the 
\ datagram as being completely missing. 

: iprd-hdlist-init ( iprd -- )
   >iprd-hdlist  dup queue-init					( hdlist )
   0  IP_MAX_PKTSIZE /ip-header -  1- ipfhd-create enqueue	( )
;

\ Manage hole descriptor updates. If the arriving datagram fills a hole
\ described by a hole descriptor entry, that entry is destroyed, and
\ any new hole descriptors, if necessary, are created.

: ipfhd-update ( ipfhd pkt -- )
   swap						( pkt ipfhd )
   over ipf-start@  over ipfhd-end@  >  if	( pkt ipfhd )
      2drop exit				( )
   then						( pkt ipfhd )
   over ipf-end@   over ipfhd-start@ <  if	( pkt ipfhd )
      2drop exit				( )
   then						( pkt ipfhd )
   over ipf-start@  over ipfhd-start@ >  if	( pkt ipfhd )
      2dup ipfhd-start@  swap ipf-start@ 1-	( pkt ipfhd nhd-start,end )
      ipfhd-create				( pkt ipfhd ipfhd-new )
      over queue-prev  swap insqueue		( pkf ipfhd )
   then						( pkt ipfhd )
   over ipf-end@  over ipfhd-end@  <  if	( pkt ipfhd )
      over ipf-flags@ IP_MF and  if		( pkt ipfhd )
         over ipf-end@ 1+   over ipfhd-end@	( pkt ipfhd nhd-start,end )
         ipfhd-create				( pkt ipfhd ipfhd-new )
         over swap insqueue			( pkt ipfhd )
      then					( pkt ipfhd )
   then						( pkt ipfhd )
   nip  dup remqueue  ipfhd-free		( )
;

\ Updating the hole descriptor list. Clear any holes which the arriving
\ datagram may fill.

: iprd-hdlist-update ( iprd pkt -- )
   >r						( iprd ) ( r: pkt )
   >iprd-hdlist  dup queue-first		( hdlist ipfhd )
   begin  2dup queue-end? 0=  while		( hdlist ipfhd )
      dup queue-next swap			( hdlist ipfhd' ipfhd )
      r@ ipfhd-update				( hdlist ipfhd' )
   repeat  					( hdlist ipfhd' )
   r> 3drop					( ) ( r: )
;

\ Checking for completion of reassembly. Reassembly is complete if the
\ hole descriptor list is now empty.

: iprd-dgram-complete? ( iprd -- flag )
   >iprd-hdlist queue-empty?
;

\ Constructing the final datagram. Once all fragments have been received,
\ build a valid datagram header and return it.

: iprd-make-datagram ( iprd -- dgram )
   dup >iprd-dgram @					( iprd dgram )
   swap >iprd-dglen w@  over >ip-len       htonw!	( dgram )
   0                    over >ip-fraginfo  htonw!	( dgram )
;

\ Set reassembly timeout.
: iprd-set-ttl ( iprd -- )  >iprd-ttl IP_REASM_TTL set-timer ;

\ Check for reassembly timer expiry
: iprd-timer-expired? ( iprd -- flag )  >iprd-ttl timer-expired?  ;

\ Create reassembly descriptor for the incoming fragment. If a reassembly
\ buffer cannot be allocated, the packet will be dropped.
 
: iprd-create ( ippkt -- iprd | 0 )
   lrgpkt-alloc ?dup 0=  if  drop 0 exit  then		( pkt lrgpkt )

   /ipreasm-descriptor alloc-mem			( pkt lrgpkt iprd )
   dup iprd-hdlist-init					( pkt lrgpkt iprd )

   tuck                    >iprd-dgram     !		( pkt iprd )
   0                  over >iprd-dglen     w!		( pkt iprd )
   over >ip-src       over >iprd-src       copy-ip-addr	( pkt iprd )
   over >ip-dest      over >iprd-dest      copy-ip-addr	( pkt iprd )
   over >ip-id ntohw@ over >iprd-dgid      w!		( pkt iprd )
   swap ip-protocol@  over >iprd-protocol  c!		( iprd )

   dup iprd-set-ttl					( iprd )
   iprd-list over enqueue				( iprd )
;

\ Free datagram reassembly descriptor
: iprd-free ( iprd -- )
   dup remqueue  /ipreasm-descriptor free-mem
;

\ Destroy all resources held for reassembling a datagram.
: iprd-destroy ( iprd -- )
   dup >iprd-dgram @  pkt-free			( iprd )
   dup >iprd-hdlist				( iprd hdlist )
   begin  dup dequeue  ?dup while		( iprd hdlist hd )
      ipfhd-free				( iprd hdlist )
   repeat  drop					( iprd )
   iprd-free					( )
;

\ Check if this reassembly descriptor is for the incoming fragment.
: iprd-match? ( pkt iprd -- pkt match? )
   over >ip-id ntohw@  over >iprd-dgid w@  =  if		( pkt iprd )
      over >ip-src  over >iprd-src  ip=  if			( pkt iprd )
         over >ip-dest  over >iprd-dest  ip=  if		( pkt iprd )
            over ip-protocol@  over >iprd-protocol c@ =  if	( pkt iprd )
               drop true exit					( pkt true )
            then						( pkt iprd )
         then							( pkt iprd )
      then							( pkt iprd )
   then								( pkt iprd )
   drop false							( pkt false )
;

\ Locate the reassembly descriptor for the incoming fragment.
: iprd-locate ( pkt -- iprd | 0 )
   iprd-list ['] iprd-match? find-queue-entry nip
;

\ Fragmented packets must have a non-zero data length.  All fragments except 
\ the last must have a length which is a multiple of 8 octets. 

: ipf-ok? ( pkt -- ok? )
   dup ip-datalen@  dup if				( pkt len )
      over ipf-flags@  IP_MF and  if			( pkt len )
         dup  3 rshift  3 lshift =			( pkt ok? ) 
      else						( pkt len )
         drop true					( pkt ok? )
      then						( pkt ok? )
   then  nip						( ok? )
;

\ Fragment processing. Copy data from the incoming fragment at the proper
\ offset in the reassembly buffer. If this is the first fragment, the IP 
\ header is copied. If this is the last fragment, the total length of the 
\ datagram is computed. 

: ipf-process-data ( iprd pkt -- )

   \ Record datagram length from the last fragment 
   dup ipf-flags@  IP_MF and  0=  if			( iprd pkt )
      2dup ipf-end@ 1+  /ip-header +			( iprd pkt iprd dglen )
      swap >iprd-dglen w!				( iprd pkt )
   then							( iprd pkt )

   \ Get pointer to reassembly buffer
   swap >iprd-dgram @					( pkt dgram )

   \ Copy IP header from the first fragment
   over ipf-start@  0= if				( pkt dgram )
      2dup /ip-header move				( pkt dgram )
   then							( pkt dgram )

   \ Copy fragment data into reassembly buffer
   over ipf-start@ +  /ip-header +			( pkt adr )
   over ippkt>payload  rot swap move			( pkt )

   pkt-free						( )
;

\ Reassembling fragmented datagrams. Locate the reassembly descriptor
\ associated with the incoming fragment, and create one if a match isn't 
\ found. If a reassembly buffer cannot be allocated, the fragment is
\ discarded. If reassembly is complete, return the complete datagram.

: ip-reassemble ( pkt -- dgram | 0 )
   dup iprd-locate  ?dup 0=  if				( pkt )
      dup iprd-create  ?dup 0=  if			( pkt )
         pkt-free 0 exit				( 0 )
      then						( pkt iprd )
   then							( pkt iprd )
   over ipf-end@ 1+  IP_MAX_PKTSIZE >  if		( pkt iprd )
      iprd-destroy  pkt-free 0 exit			( 0 )
   then							( pkt iprd )
   swap 2dup iprd-hdlist-update				( iprd pkt )
   over swap ipf-process-data				( iprd )
   dup iprd-dgram-complete?  if				( iprd )
      dup iprd-make-datagram  swap iprd-free		( dgram )
   else							( iprd )
      drop 0						( 0 )
   then							( dgram | 0 )
;

\ Check reassembly descriptor queue and release resources held by
\ entries whose reassembly timers have expired.

: ipf-do-timer-events ( -- )
   iprd-list dup queue-first			( list iprd )
   begin  2dup queue-end?  0=  while		( list iprd )
      dup queue-next swap			( list iprd' iprd )
      dup iprd-timer-expired?  if		( list iprd' iprd )
         dup iprd-destroy			( list iprd' iprd )
      then  drop				( list iprd' )
   repeat  2drop				( )
;

\ Initialize reassembly descriptor queue
: ipreasm-init  ( -- )  iprd-list queue-init ;

\ Destroy all reassembly descriptors
: ipreasm-close ( -- )
   iprd-list begin  dup dequeue  ?dup while  iprd-destroy  repeat  drop
;

\ Validate IP packet before further processing.
: ip-packet-ok? ( pkt -- ok? )
   dup ip-ver@  IP_VERSION =  if		( pkt ) 
      dup ip-hlen@  /ip-header >=  if		( pkt )
         dup ip-checksum 0=  if			( pkt )
            drop true exit			( true )
         then					( pkt )
      then					( pkt )
   then						( pkt )
   drop false					( false )
;

\ Accept broadcast packets and packets addressed to us. If we dont know
\ our IP address yet, accept all incoming datagrams.

: ip-accept-packet? ( pkt -- accept? )
   dup >ip-dest ip=broadcast?  if		( pkt )
      drop true					( true )
   else						( pkt )
      my-ip-addr inaddr-any?  if		( pkt )
         drop true				( true )
      else					( pkt )
         >ip-dest my-ip-addr ip=		( accept? )
      then					( accept? )
   then						( accept? )
;

\ IP option processing. We dont handle IP options; any options present in 
\ incoming datagrams are deleted after the IP checksum is verified.

: ip-strip-options ( ippkt -- )
   dup ip-hlen@ /ip-header <>  if			( pkt )
      dup >r						( pkt ) ( r: pkt )
      dup ip-len@  over ip-hlen@  encapsulated-data	( data datalen )
      dup /ip-header +  r@ ip-len!			( data datalen )
      /ip-header        r@ ip-hlen!			( data datalen )
      r@ /ip-header + swap move				( )
      r>						( pkt ) ( r: )
   then  drop						( )
;

: ip-process-packet ( pkt -- dgram | 0 )
   dup ip-strip-options					( pkt )
   dup >ip-fraginfo ntohw@  IP_MF IP_FRAGOFF or and if	( pkt )
      dup ipf-ok?  if					( pkt )
         ip-reassemble					( dgram | 0 )
      else						( pkt )
         pkt-free 0					( 0 )
      then						( dgram | 0 )
   then							( dgram | 0 )
;

defer (tcp-input)   ' drop to (tcp-input)	\ Forward reference
defer (udp-input)   ' drop to (udp-input)	\ Forward reference
defer (icmp-input)  ' drop to (icmp-input)	\ Forward reference

: ip-input ( pkt len -- )
   drop							( pkt )
   dup ip-packet-ok?  over ip-accept-packet? and if	( pkt )
      ip-process-packet ?dup if				( dgram )
         dup ip-protocol@  case	
            IPPROTO_TCP  of  (tcp-input)   endof
            IPPROTO_UDP  of  (udp-input)   endof
            IPPROTO_ICMP of  (icmp-input)  endof
            ( default )  swap pkt-free
         endcase
      then						( )
   else							( pkt )
      pkt-free						( )
   then							( )
; 
['] ip-input to (ip-input)

: ip-poll ( -- )
   ipf-do-timer-events  arp-do-timer-events  if-poll
;

headers
