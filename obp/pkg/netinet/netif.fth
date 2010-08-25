\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: netif.fth
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
id: @(#)netif.fth 1.1 04/09/07
purpose: Network interface layer abstraction
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

defer (arp-input)   ' 2drop  to (arp-input)	\ Forward reference
defer (rarp-input)  ' 2drop  to (rarp-input)	\ Forward reference
defer (ip-input)    ' 2drop  to (ip-input)	\ Forward reference

\ Process incoming frame. Handle link-level demultiplexing.
: if-input ( frame framelen type -- )
   >r  if-hdrlen@ encapsulated-data  r>		( pkt pktlen type )
   case
      IP_TYPE   of  (ip-input)    endof
      ARP_TYPE  of  (arp-input)   endof
      RARP_TYPE of  (rarp-input)  endof
      ( default )   nip swap pkt-free
   endcase					( )
;

\ Poll for incoming packets.
: if-poll ( -- )
   if-data >if-input @ execute  if		( frame framelen type )
      if-input					( )
   then						( )
;

\ Network output interface function.
: if-output ( pkt len dest.hwaddr type -- len' )
   3 pick >r					( pkt len hwaddr type )
   2swap if-hdrlen@ encapsulating-hdr 2swap	( frame framelen hwaddr type )
   if-data >if-output @ execute			( len' )
   r> pkt-free					( len' )
;

\ Determine the network interface type (Ethernet is assumed by default).
: network-interface-type ( -- iftype )
   " ethernet" " network-interface-type" my-parent ihandle>phandle
   get-package-property 0=  if
      2swap 2drop  decode-string 2swap 2drop
   then
   " ethernet" $=  if  HWTYPE_ETHER  else  0  then
;

\ Network interface layer initialization.
: netif-init ( -- )
   /if-data dup alloc-mem tuck swap erase to if-data
   network-interface-type  case
      0            of  ether-ifinit  endof	\ Unknown I/F; Assume ethernet
      HWTYPE_ETHER of  ether-ifinit  endof
   endcase
   init-nbpools
;

\ Free network interface layer resources.
: netif-close ( -- )
   free-nbpools						( )
   if-htype@  case					( )
      HWTYPE_ETHER of  ether-ifclose  endof		( )
   endcase						( )
   if-data /if-data free-mem  0 to if-data		( )
;

headers
