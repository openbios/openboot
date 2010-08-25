\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: arp.fth
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
id: @(#)arp.fth 1.1 04/09/07
purpose: ARP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 826: Ethernet Address Resolution Protocol

fload ${BP}/pkg/netinet/arp-h.fth

headerless

\ The ARP cache maintains recent mappings of IP to hardware addresses.
\ Unresolved entries maintain a queue of datagrams to be sent when the 
\ address is resolved. We only queue the most recent datagram to be
\ sent to a specified destination while that address is being resolved.

\ Enqueue datagram waiting for ARP resolution.
: arpq-enqueue ( arpentry pkt -- )
   swap  >ae-pktq  dup queue-empty? 0=  if		( pkt queue )
      dup pkt-dequeue pkt-free				( pkt queue )
   then							( pkt queue )
   swap pkt-enqueue					( )
;

\ Send datagrams waiting for ARP resolution.
: arpq-send ( arpentry -- )
   dup >ae-pktq  swap >ae-hwaddr			( queue hwaddr )
   begin  over pkt-dequeue ?dup while			( queue hwaddr pkt )
      2dup ip-len@ swap IP_TYPE if-output drop		( queue hwaddr )
   repeat  2drop					( )
;

\ Destroy queued datagrams
: arpq-free ( entry -- )
   >ae-pktq  begin  dup pkt-dequeue  ?dup while  pkt-free  repeat  drop
;

\ Allocate an entry in the ARP table. Choose an unused entry if one
\ exists. Otherwise, entries are replaced in a round-robin fashion. 

0  instance value  ae-next	\ Next entry to replace/write

: arp-alloc-entry ( -- entry )
   ARP_TABLE_SIZE 0 do
      ae-next index>arp-entry ae-state@ AE_FREE =  if leave  then 
      ae-next 1+ ARP_TABLE_SIZE mod to ae-next
   loop
   ae-next index>arp-entry				( entry )
   dup ae-state@ AE_PENDING =  if			( entry )
      dup arpq-free					( entry )
   then							( entry )
   dup >ae-pktq queue-init				( entry )
   AE_PENDING over ae-state!				( entry )
   0 over >ae-attempts l!				( entry )
   ae-next 1+ ARP_TABLE_SIZE mod to ae-next		( entry )
;

\ Add a RESOLVED entry to the ARP cache.
: arp-add-entry ( ipaddr hwaddr -- )
   arp-alloc-entry					( ipaddr hwaddr entry )
   tuck		  >ae-hwaddr           copy-hw-addr	( ipaddr entry )
   tuck		  >ae-ipaddr           copy-ip-addr	( entry )
   ARP_ENTRY_TTL  over >ae-timer swap  set-timer	( entry )
   AE_RESOLVED    swap                 ae-state!	( )
;

\ Mark an entry as FREE. Free queued datagram, if any.
: arp-free-entry ( entry -- )
   dup ae-state@ AE_FREE <>  if				( entry )
      dup arpq-free					( entry )
   then							( entry )
   AE_FREE swap ae-state!				( )
;

\ Find ARP entry for specified protocol address.
: arp-find-entry ( ipaddr -- entry )
   ARP_TABLE_SIZE 0 do					( ipaddr )
      i index>arp-entry dup ae-state@ AE_FREE <>  if	( ipaddr adr )
         2dup >ae-ipaddr ip=  if			( ipaddr adr )
            nip unloop exit				( entry )
         then						( ipaddr adr )
      then  drop					( ipaddr )
   loop  drop 0
;

\ Handle ARP table updates. If a translation for the sender's IP address
\ already exists, update the sender's hardware address and "refresh"
\ the cache entry; if this address was pending resolution, mark the
\ cache entry as RESOLVED and send any queued packet. Else, create
\ an entry for the sender if we are the target of the request.

: arptable-update ( pkt -- )
   dup >arp-spa  arp-find-entry ?dup if			( pkt entry )
      swap >arp-sha  over >ae-hwaddr  copy-hw-addr	( entry )
      dup >ae-timer  ARP_ENTRY_TTL  set-timer		( entry )
      dup ae-state@  AE_PENDING =  if			( entry )
         AE_RESOLVED over ae-state!  			( entry )
         dup arpq-send					( entry ) 
      then  drop					( )
   else                                                 ( pkt )
      dup >arp-tpa my-ip-addr ip=  if			( pkt )
         dup >arp-spa  over >arp-sha  arp-add-entry	( pkt )
      then  drop					( )
   then                                                 ( )
;

: arp-packet-ok? ( pkt len -- ok? )
   over >arp-hwtype ntohw@  if-htype@ =  if		( pkt len )
      over >arp-prtype ntohw@  IP_TYPE =  if		( pkt len )
         nip /arp-packet >=  exit			( ok? )
      then						( pkt len )
   then							( pkt len )
   2drop false						( false )
;

\ ARP input packet processing. Respond to incoming ARP requests, and 
\ handle ARP cache updates.

: arp-input ( pkt len -- )

   over swap arp-packet-ok? 0=  if  pkt-free exit  then		( pkt )

   \ Process each packet for ARP cache updates. If address spoofing 
   \ is detected, an error is logged and a reply is sent even if 
   \ this host was not the target.

   dup >arp-spa my-ip-addr ip= if				( pkt )
      my-ip-addr inaddr-any? 0=  if
         dup >arp-sha if-showaddr ."  is also using "  my-ip-addr .ipaddr cr
         my-ip-addr  over >arp-tpa  copy-ip-addr
      then
   else
      dup arptable-update
   then								( pkt )

   \ If this is an ARP request and this host is the target, send a
   \ response. Dont respond to ARP requests until our IP address
   \ has been determined.

   my-ip-addr inaddr-any?         if  pkt-free exit  then	( pkt )
   dup >arp-tpa  my-ip-addr ip<>  if  pkt-free exit  then
   dup >arp-op ntohw@  ARP_REQ <> if  pkt-free exit  then

   ARP_REPLY     over >arp-op   htonw!				( pkt )
   dup >arp-sha  over >arp-tha  copy-hw-addr			( pkt )
   if-hwaddr     over >arp-sha  copy-hw-addr			( pkt )
   dup >arp-spa  over >arp-tpa  copy-ip-addr			( pkt )
   my-ip-addr    over >arp-spa  copy-ip-addr			( pkt )

   /arp-packet over >arp-tha ARP_TYPE if-output drop		( ) 
;
['] arp-input  to (arp-input)

\ Common code to construct and transmit ARP and RARP packets.
: send-arp/rarp-packet ( target.ip target.ha arp.op type -- )
   pkt-alloc ?dup 0=  if  2drop 2drop exit  then	( tpa tha op type pkt )
   swap >r						( tpa tha op pkt )
   if-htype@   over >arp-hwtype  htonw!			( tpa tha op pkt )
   IP_TYPE     over >arp-prtype  htonw!			( tpa tha op pkt )
   if-addrlen@ over >arp-hwlen   c!			( tpa tha op pkt )
   /ip-addr    over >arp-prlen   c!			( tpa tha op pkt )
   if-hwaddr   over >arp-sha     copy-hw-addr		( tpa tha op pkt )
   my-ip-addr  over >arp-spa     copy-ip-addr		( tpa tha op pkt )
   tuck             >arp-op      htonw!			( tpa tha pkt )
   tuck             >arp-tha     copy-hw-addr		( tpa pkt )
   tuck             >arp-tpa     copy-ip-addr		( pkt )
   /arp-packet if-broadcast r> if-output drop		( ) ( r: )
;

\ Transmit an ARP request for the sought IP address.
: arprequest ( ipaddr -- )
   if-broadcast ARP_REQ ARP_TYPE send-arp/rarp-packet
;

\ ARP address resolution. If a translation exists, the interface layer 
\ can send the packet.  If not, initiate an ARP query and queue this 
\ packet for transmission once the address is resolved. If the destination 
\ is pending address resolution, only the most recent datagram is held 
\ for transmission.

: arp-resolve ( pkt ipaddr -- hwaddr true | false ) 
   dup ip=broadcast? if				( pkt ipaddr )
      2drop if-broadcast true exit		( hwaddr true )
   then						( pkt ipaddr )
   dup arp-find-entry ?dup if			( pkt ipaddr entry )
      nip dup ae-state@ AE_RESOLVED =  if	( pkt entry )
         nip >ae-hwaddr true			( hwaddr true )
      else					( pkt entry )
         swap arpq-enqueue false		( false )
      then					( hwaddr true | false ) 
   else						( pkt ipaddr )
      arp-alloc-entry				( pkt ipaddr entry )
      2dup >ae-ipaddr copy-ip-addr		( pkt ipaddr entry )
      rot over swap arpq-enqueue		( ipaddr entry )
      swap arprequest				( entry )
      >ae-timer ARP_RETRY_INTERVAL set-timer	( )
      false					( false )
   then						( hwaddr true | false ) 
;

\ Handling timer expiration events. If this entry is pending address
\ resolution, retransmit the ARP request; if the retransmission limit 
\ has been reached, deallocate the queued packet and free the entry.
\ Else, if this is a resolved entry, its maximum time-to-live has 
\ expired, and the entry is freed.

: ae-do-timer-events ( arpentry -- )
   dup >ae-timer timer-expired? 0=  if  drop exit  then		( entry )
   dup ae-state@ AE_RESOLVED =  if				( entry )
      arp-free-entry						( )
   else								( entry )
      1 over >ae-attempts +!					( entry )
      dup >ae-attempts l@  ARP_MAX_RETRIES >  if		( entry )
         arp-free-entry						( )
      else							( entry )
         dup >ae-ipaddr arprequest				( entry )
         >ae-timer ARP_RETRY_INTERVAL set-timer			( )
      then							( )
   then								( )
;

\ Periodic ARP cache maintenance. Runs once every second; iterate through 
\ ARP cache entries checking for and handling timer expiration events. 

/timer  instance buffer:  arp-event-timer

: arp-do-timer-events ( -- )
   arp-event-timer timer-expired? if				( )
      arp-event-timer d# 1000 set-timer				( )
      ARP_TABLE_SIZE 0  do					( )
         i index>arp-entry  dup ae-state@ AE_FREE <>  if	( arpentry )
            dup ae-do-timer-events				( arpentry )
         then  drop						( )
      loop							( )
   then								( )
;

\ Check to see if a given IP address is already in use.
: arp-check ( sought-ip ntries -- in-use? )
   0 ?do						( ip )
      get-msecs ARP_RETRY_INTERVAL +			( ip timeout )
      over arprequest					( ip timeout )
      begin						( ip timeout )
         if-poll					( ip timeout )
         over arp-find-entry ?dup if			( ip timeout entry )
            ae-state@ AE_RESOLVED =  if			( ip timeout )
               2drop true unloop exit			( true )
            then  					( ip timeout )
         then						( ip timeout )
         dup timed-out?					( ip timeout flag )
      until  drop					( ip )
   loop  drop false					( false )
;

\ Initialize ARP layer state.
: arp-init ( -- )
   ARP_TABLE_SIZE /arp-entry * alloc-mem  to arp-table		( )
   ARP_TABLE_SIZE 0 do						( )
      AE_FREE i index>arp-entry ae-state!			( )
   loop								( )
   0 to ae-next							( )
   arp-event-timer d# 1000 set-timer				( )
;

\ Free all ARP resources. 
: arp-close ( -- )
   ARP_TABLE_SIZE 0 do  i index>arp-entry arp-free-entry  loop
   arp-table ARP_TABLE_SIZE /arp-entry * free-mem
   0 to arp-table
;

[ifdef] DEBUG

: show-arp-table ( -- )
   ARP_TABLE_SIZE 0 do
      i .d  2 spaces  
      i index>arp-entry  dup ae-state@  case
         AE_FREE     of  ." Free"  endof
         AE_PENDING  of
            ." Pending "  dup >ae-ipaddr .ipaddr
         endof
         AE_RESOLVED of
            ." Resolved "
            dup >ae-ipaddr .ipaddr  2 spaces 
            dup >ae-hwaddr if-showaddr
         endof
      endcase  drop cr
   loop
;

[then]

headers
