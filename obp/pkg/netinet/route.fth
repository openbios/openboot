\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: route.fth
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
id: @(#)route.fth 1.1 04/09/08
purpose: Routing table management
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 1122: Requirements for Internet Hosts -- Communication Layers

\ Routing table entries are keyed on destination host addresses. Each
\ routing table entry (other than the default route entry) contains the
\ destination IP address and the IP address of the corresponding
\ next-hop router.

headerless

d# 32  constant  RT_TABLE_SIZE		\ Routing table size

struct
   /ip-addr  field  >rt-dest		\ Destination IP
   /ip-addr  field  >rt-gateway		\ Next hop
   /c        field  >rt-flags		\ Flags
constant /route-entry

1  constant  RT_DEFAULT			\ Default route 
2  constant  RT_HOST			\ Route to host 

0  instance value  routing-table	\ Routing table
0  instance value  rt-next		\ Next free routing table entry 

: index>route-entry ( index -- adr )  /route-entry *  routing-table + ;

\ Initialize routing table data structures.
: init-routing-table ( -- )
   RT_TABLE_SIZE /route-entry *  dup alloc-mem		( n adr )
   tuck swap erase  to routing-table			( )
   0 to rt-next						( )
;

\ Free routing table structures.
: free-routing-table ( -- )
   routing-table RT_TABLE_SIZE /route-entry *  free-mem
   0 to routing-table
;

\ Check for routing entry match.
: rtentry-match? ( dest-ip rtflags rtentry -- flag )
   tuck >rt-flags c@ =  if			( ip entry )
      >rt-dest ip=				( flag )
   else						( ip entry )
      2drop false				( false )
   then						( flag )
; 

\ Get specified route.
: find-route-entry ( dest-ip rtflags -- rtentry )
   rt-next 0  ?do					( ip flags )
      i index>route-entry 3dup rtentry-match?  if	( ip flags entry )
         nip nip unloop exit				( entry )
      then  drop					( ip flags )
   loop  2drop 0					( 0 )
;

\ Set routing table entry fields.
: set-route-entry ( dest-ip gateway-ip rtflags rtentry -- )
   tuck >rt-flags   c!					( ip gateway entry )
   tuck >rt-gateway copy-ip-addr			( ip entry )
        >rt-dest    copy-ip-addr			( )
;

\ Add a route to the routing table.
: route-add ( dest-ip gateway-ip flags -- )
   rt-next RT_TABLE_SIZE =  if				( ip gateway flags )
      3drop ." Routing Table Full" cr			( )
   else							( ip gateway flags )
      rt-next index>route-entry set-route-entry		( )
      rt-next 1+ to rt-next				( )
   then							( )
;

\ Update a routing table entry. Called by ICMP redirect processing.
: route-update ( dest-ip gateway-ip flags -- )
   2 pick over find-route-entry ?dup if		( ip gateway flags entry )
      set-route-entry				( )
   else						( ip gateway flags )
      3drop					( )
   then						( )
;

\ Get route to specified destination. If a routing table entry for the 
\ specified destination is not found, select the default router as the
\ next-hop, but build an entry for this destination. If the default 
\ router is not the best next-hop, the route entry will be updated by 
\ the incoming ICMP redirect message.

: route-get ( dest-ip -- gateway-ip | 0 )
   dup RT_HOST find-route-entry ?dup if			( ip entry )
      nip >rt-gateway					( gateway )
   else							( ip )
      inaddr-any RT_DEFAULT find-route-entry dup if	( ip entry ) 
         >rt-gateway 2dup RT_HOST route-add		( ip gateway )
      then  nip						( gateway | 0 )
   then							( gateway | 0 )
;

\ If the destination is not on the directly connected network, consult
\ the routing table to get the next-hop router.
: ipdest>nexthop ( dest-ip -- nexthop | 0 )
   dup ip=localaddr? 0=  if  route-get  then
;

[ifdef] DEBUG
: show-routing-table ( -- )
   rt-next 0 ?do
      i index>route-entry
      dup >rt-dest    .ipaddr  2 spaces
      dup >rt-gateway .ipaddr  2 spaces
      >rt-flags c@  RT_DEFAULT = if  ." Default"  else  ." Host"  then  cr
   loop
;
[then]

headers
