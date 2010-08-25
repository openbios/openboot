\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: netif-h.fth
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
id: @(#)netif-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

d# 6   constant MAX_HWADDR_LEN	\ Largest hardware address length

\ IANA assigned ARP hardware types
1      constant HWTYPE_ETHER	\ Ethernet

\ Frame types
h#  800 constant IP_TYPE	\ Internet Protocol, v4
h#  806 constant ARP_TYPE	\ Address Resolution Protocol
h# 8035 constant RARP_TYPE	\ Reverse Address Resolution Protocol

\ Media Level information (MAC layer independent definitions) 
struct
   /c                  field  >if-htype		\ ARP hardware address type
   /c                  field  >if-hdrlen	\ Media header length
   /c                  field  >if-addrlen	\ Media address length
   MAX_HWADDR_LEN      field  >if-hwaddr	\ Hardware address
   MAX_HWADDR_LEN      field  >if-broadcast	\ Hardware broadcast address
   dup aligned over -  field  >if-pad		\ For alignment
   /n                  field  >if-output	\ Output routine
   /n                  field  >if-input		\ Input routine
   /n                  field  >if-showaddr	\ Address display routine
   /l                  field  >if-mtu		\ Interface MTU
constant /if-data

0 instance value  if-data

: if-htype@   ( -- n )  if-data >if-htype c@ ;
: if-hdrlen@  ( -- n )  if-data >if-hdrlen c@ ;
: if-addrlen@ ( -- n )  if-data >if-addrlen c@ ;
: if-mtu@     ( -- n )  if-data >if-mtu l@ ;

: if-frame-size@ ( -- n )  if-mtu@ if-hdrlen@ + ;

: if-hwaddr    ( -- adr )  if-data >if-hwaddr ;
: if-broadcast ( -- adr )  if-data >if-broadcast ;

: if-showaddr ( hwaddr -- )
   if-data >if-showaddr @ execute
;

: copy-hw-addr ( adr1 adr2 -- )  if-addrlen@ move ;
: hwaddr=      ( adr1 adr2 -- )  if-addrlen@ comp 0= ;

headers
