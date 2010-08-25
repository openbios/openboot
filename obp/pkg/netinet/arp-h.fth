\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: arp-h.fth
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
id: @(#)arp-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

struct
   /w  field  >arp-hwtype	\ Format of hardware address
   /w  field  >arp-prtype	\ Format of protocol address
   /c  field  >arp-hwlen	\ Length of hardware address
   /c  field  >arp-prlen	\ Length of protocol address
   /w  field  >arp-op		\ ARP Opcode
constant /arp-header

: >arp-sha ( pkt -- adr )  /arp-header + ;
: >arp-spa ( pkt -- adr )  /arp-header +  if-addrlen@    + ;
: >arp-tha ( pkt -- adr )  /arp-header +  if-addrlen@    +  /ip-addr + ;
: >arp-tpa ( pkt -- adr )  /arp-header +  if-addrlen@ 2* +  /ip-addr + ;

: /arp-packet ( -- n )
   /arp-header if-addrlen@ /ip-addr + 2* + 
;

\ ARP/RARP Opcodes
1     constant  ARP_REQ
2     constant  ARP_REPLY
3     constant  RARP_REQ
d# 4  constant  RARP_REPLY

\ ARP cache entry structure 
struct
   /ip-addr            field  >ae-ipaddr	\ Protocol Address
   MAX_HWADDR_LEN      field  >ae-hwaddr	\ Hardware Address
   dup aligned over -  field  >ae-pad		\ For structure alignment
   /queue-head         field  >ae-pktq		\ Queue of pending packets
   /timer              field  >ae-timer		\ "Aging" timer entry
   /l                  field  >ae-state		\ State of this entry
   /l                  field  >ae-attempts	\ Number of retries so far
constant /arp-entry

\ ARP cache entry states
0  constant  AE_FREE		\ Entry is free
1  constant  AE_PENDING		\ Entry is awaiting address resolution
2  constant  AE_RESOLVED	\ Entry is valid

0     instance value  arp-table		\ ARP cache
d# 8  constant        ARP_TABLE_SIZE	\ Size of ARP cache

d#      4  constant  ARP_MAX_RETRIES	\ Maximum number of retries
d#   1000  constant  ARP_RETRY_INTERVAL	\ Minimum retry interval 
d# 600000  constant  ARP_ENTRY_TTL	\ Lifetime of valid ARP cache entry

: ae-state@ ( adr -- state )  >ae-state l@ ;
: ae-state! ( state adr -- )  >ae-state l! ;

: index>arp-entry ( index -- adr )  /arp-entry *  arp-table + ;

headers
