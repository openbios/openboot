\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ip-h.fth
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
id: @(#)ip-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

struct
   /c        field  >ip-ver,hlen	\ Version and header length
   /c        field  >ip-service		\ Type of service
   /w        field  >ip-len		\ Total length
   /w        field  >ip-id		\ Identification
   /w        field  >ip-fraginfo	\ Flags and fragment offset
   /c        field  >ip-ttl		\ Time to Live
   /c        field  >ip-protocol	\ Protocol
   /w        field  >ip-cksum		\ Header checksum
   /ip-addr  field  >ip-src		\ IP source address
   /ip-addr  field  >ip-dest		\ IP destination address
constant /ip-header

h#  2000  constant  IP_MF		\ More fragments flag
h#  4000  constant  IP_DF		\ Dont fragment flag
h#  1fff  constant  IP_FRAGOFF		\ Fragment offset mask

d# 65535  constant  IP_MAX_PKTSIZE	\ Maximum packet size
d#    64  constant  IP_DEFAULT_TTL	\ Default TTL

: ip-ver@  ( pkt -- n )  >ip-ver,hlen c@  4 rshift ;

: ip-hlen@ ( pkt -- n )  >ip-ver,hlen c@  h# f and  2 lshift ;

: ip-hlen! ( n pkt -- )
   tuck  >ip-ver,hlen c@ h# f0 and  swap 2 rshift or  swap  >ip-ver,hlen c!
;

: ip-len@  ( pkt -- n )  >ip-len ntohw@ ;
: ip-len!  ( n pkt -- )  >ip-len htonw! ;

: ip-protocol@ ( pkt -- n )  >ip-protocol c@ ;

: ip-datalen@ ( pkt -- n )  dup ip-len@  swap ip-hlen@ - ;

: ipf-start@ ( pkt -- n )
   >ip-fraginfo ntohw@  IP_FRAGOFF and  3 <<
;

: ipf-end@   ( pkt -- n )
   dup ipf-start@  swap ip-datalen@ +  1-
;

: ipf-flags@ ( pkt -- n )
   >ip-fraginfo ntohw@  IP_FRAGOFF invert and
;

\ Get to payload of IP packet. Assumes IP header has no options 
: ippkt>payload ( pkt -- adr len )
   dup ip-len@  /ip-header  encapsulated-data
;

headers
