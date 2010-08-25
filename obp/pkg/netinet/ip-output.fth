\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ip-output.fth
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
id: @(#)ip-output.fth 1.1 04/09/07
purpose: IP output routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Fill in the IP header checksum and send the packet.
: (ip-output) ( ippkt nexthop -- #sent )
   swap  0          over >ip-cksum  htonw!	( nexthop ippkt )
   dup ip-checksum  over >ip-cksum  htonw!	( nexthop ippkt )
   tuck swap arp-resolve  if			( ippkt hwaddr )
      over ip-len@ swap IP_TYPE if-output	( #sent )
   else						( ippkt )
      drop 0					( 0 )
   then						( #sent )
;

: ipf-copydata ( dgram fragoff fraglen fragpkt -- )
   /ip-header ca+  swap >r >r  /ip-header + ca+  r> r>  move
;

\ Construct a fragment.
: ip-make-fragment ( dgram fragoff fraglen -- fragpkt )
   pkt-alloc ?dup 0=  if			( dgram offset len )
      3drop 0 exit				( 0 )
   then						( dgram offset len pkt )
   3 pick over /ip-header move			( dgram offset len pkt )
   over /ip-header +  over ip-len!		( dgram offset len pkt )
   2over 2over ipf-copydata			( dgram offset len pkt )
   >r						( dgram offset len ) ( r: pkt )
   over +  rot ip-datalen@  <>  if		( offset )
      IP_MF 					( offset ipf-flags )
   else						( offset )
      0						( offset ipf-flags )
   then						( offset ipf-flags )
   swap  3 rshift or  r@ >ip-fraginfo htonw!	( )
   r>						( pkt ) ( r: )
;

\ Create and send a single fragment.
: ipf-send ( dgram fragoff fraglen nexthop -- #sent )
   >r  ip-make-fragment  r>  over  if   (ip-output)  else  2drop 0  then 
;

\ Transmit datagram, fragmenting it if necessary.
: ip-send-datagram ( dgram nexthop -- #sent )
   over ip-len@  if-mtu@  <=  if			( dgram nexthop )
      (ip-output)					( #sent )
   else							( dgram nexthop )
      >r						( dgram ) ( r: nexthop )
      0  begin						( dgram nsent )
         over ip-datalen@  over -			( dgram nsent rem )
      ?dup while					( dgram nsent rem )
         dup /ip-header +  if-mtu@  >  if		( dgram nsent rem )
            drop  if-mtu@ /ip-header - h# fff8 and	( dgram nsent fragsize )
         then						( dgram nsent fragsize )
         3dup r@ ipf-send  0= if			( dgram nsent fragsize )
            r> 3drop  pkt-free  0  exit			( 0 ) ( r: )
         then						( dgram nsent fragsize )
         +						( dgram nsent' ) 
      repeat						( dgram nsent' )
      /ip-header +					( dgram #sent )
      swap pkt-free					( #sent )
      r> drop						( #sent ) ( r: )
   then							( #sent )
;

instance variable ip-sequence

\ Determine next hop, complete the IP header and send the datagram. Most
\ of the fields in the IP header are initialized by the transport layer 
\ protocol. Only the IP version, header length, datagram identifier and 
\ the checksum are filled in here.

: ip-output ( ippkt -- #sent | error# )
   dup >ip-dest  ipdest>nexthop  ?dup 0=  if		( pkt )
      pkt-free EHOSTUNREACH exit			( error# )
   then  swap						( nexthop pkt )

   h# 45          over >ip-ver,hlen  c!
   ip-sequence @  over >ip-id        htonw!   1 ip-sequence +!
   0              over >ip-fraginfo  htonw!

   swap ip-send-datagram				( #sent )
;

headers
