\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: icmp.fth
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
id: @(#)icmp.fth 1.1 04/09/07
purpose: ICMP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 792: Internet Control Message Protocol

headerless

struct
   /ip-header  field  >icmp-iphdr	\ IP header, no options
   /c          field  >icmp-type	\ Message type
   /c          field  >icmp-code	\ Message type subcode
   /w          field  >icmp-cksum	\ Checksum
   0           field  >icmp-gwaddr	\ Preferred gateway (ICMP_REDIRECT) 
   /w          field  >icmp-id		\ Message id (ICMP_ECHO)
   /w          field  >icmp-seq		\ Sequence number (ICMP_ECHO)
   0           field  >icmp-ip		\ IP header (ICMP_REDIRECT)
   0           field  >icmp-data	\ Data (ICMP_ECHO)
constant /icmpip-header

\ ICMP message types 
0     constant	ICMP_ECHOREPLY		\ Echo reply
d# 5  constant  ICMP_REDIRECT		\ Better route available
d# 8  constant  ICMP_ECHO		\ Echo request

\ Compute checksum on the ICMP (IP payload) packet
: icmp-checksum ( ip-pkt -- checksum )
    0 swap ippkt>payload in-cksum
;

\ Fill in ICMP checksum and send the packet 
: icmp-output ( ip-pkt -- )
   0                  over >icmp-cksum  htonw!		( pkt )
   dup icmp-checksum  over >icmp-cksum  htonw!		( pkt )
   ip-output  drop					( )
;

\ Handle an incoming ICMP redirect. Network redirects and host redirects
\ are treated identically.
: icmp-redirect ( ip-pkt -- )
   dup >icmp-ip >ip-dest  swap >icmp-gwaddr  RT_HOST route-update 
;

\ Respond to ICMP ECHO requests.
: icmp-reflect ( ip-pkt -- )
   dup >ip-src     over >ip-dest    copy-ip-addr	( pkt )
   my-ip-addr      over >ip-src     copy-ip-addr	( pkt )
   ICMP_ECHOREPLY  over >icmp-type  c!			( pkt )
   icmp-output						( )
;

\ Process incoming ICMP packet
: icmp-input ( pkt -- )
   my-ip-addr inaddr-any? 0=  if				( pkt )
      dup icmp-checksum  0=  if					( pkt )
         dup >icmp-type c@  case
            ICMP_ECHO      of  icmp-reflect exit  endof
            ICMP_REDIRECT  of  dup icmp-redirect  endof
         endcase
      then							( pkt )
   then								( pkt )
   pkt-free							( )
;
['] icmp-input  to (icmp-input) 

headers
