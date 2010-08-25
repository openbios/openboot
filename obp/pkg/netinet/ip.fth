\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ip.fth
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
id: @(#)ip.fth 1.1 04/09/07
purpose: IP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 791: Internet Protocol

headerless

/l instance buffer:  ni-netnum		\ Network number, host byte order
/l instance buffer:  ni-netmask		\ Netmask, host byte order

\ Get default network mask on a network, as implied by the class A/B/C
\ classification of network numbers. 
: ip-default-netmask ( ip# -- netmask )
   dup h# 8000.0000 and 0=  if				( ip# )
      drop h# ff00.0000					( classa-mask )
   else							( ip# )
      h# c000.0000 and  h# 8000.0000 =  if		( )
         h# ffff.0000					( classb-mask )
      else						( )
         h# ffff.ff00					( classc-mask )
      then						( netmask )
   then							( netmask )
;

\ Determine whether the specified address is on the local network. 
: ip=localaddr? ( ipaddr -- flag )
   dup ip=broadcast? if					( ipaddr )
      drop true						( true )
   else							( ipaddr )
      ntohl@  ni-netmask l@  and  ni-netnum l@  =	( flag )
   then							( flag )
;

\ Compute IP header checksum.
: ip-checksum ( pkt -- checksum )
   0  swap dup ip-hlen@  in-cksum
;

fload ${BP}/pkg/netinet/route.fth
fload ${BP}/pkg/netinet/ip-input.fth
fload ${BP}/pkg/netinet/ip-output.fth

headerless

\ Initialize IP layer state.
: ip-init ( -- )
   init-routing-table  ipreasm-init 
;

\ Free IP resources.
: ip-close ( -- )
   ipreasm-close  free-routing-table
;

\ Configure IP layer state (address assignment and route initialization)
\ with the obtained host address and router information.
: ip-configure ( -- )
   my-netmask inaddr-any? if					( )
      my-ip-addr ntohl@  ip-default-netmask  my-netmask htonl!	( )
   then								( )
   router-ip inaddr-any? 0= if					( )
      inaddr-any router-ip RT_DEFAULT route-add			( )
   then								( )
   my-netmask ntohl@  dup ni-netmask l!				( netmask )
   my-ip-addr ntohl@  and ni-netnum  l!				( )
;

headers
