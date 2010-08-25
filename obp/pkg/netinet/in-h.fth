\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: in-h.fth
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
id: @(#)in-h.fth 1.1 04/09/07
purpose: IP layer constants and support routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Constants and structures defined by IANA, and other support routines.

headerless

\ Version numbers
d#  4  constant	IP_VERSION

\ Protocols
1      constant  IPPROTO_ICMP
d#  6  constant  IPPROTO_TCP
d# 17  constant  IPPROTO_UDP

\ Port numbers
d#   67  constant IPPORT_BOOTPS
d#   68  constant IPPORT_BOOTPC
d#   69  constant IPPORT_TFTP
d#   80  constant IPPORT_HTTP
d# 8080  constant IPPORT_HTTP_ALT

\ IPV4 address structure
d#  4  constant  /ip-addr

\ IPV4 special addresses
create inaddr-any            0 c,     0 c,     0 c,     0 c,
create inaddr-broadcast  h# ff c, h# ff c, h# ff c, h# ff c,

\ ntohw@, htonw!, ntohl@, and htonl! manage conversion of 16 and 32 bit
\ quantities between network and host byte order. 

: ntohw@ ( adr -- w )
   dup  ca1+ c@  swap c@  bwjoin
;

: htonw! ( w adr -- )
   >r  wbsplit  r@ c!  r> ca1+ c!
;

: ntohl@ ( adr -- l )
   dup  3 ca+ c@  swap dup 2 ca+ c@  swap dup ca1+ c@  swap c@ bljoin
;

: htonl! ( l adr -- )
   >r lbsplit  r@ c!  r@ ca1+ c!  r@ 2 ca+ c!  r> 3 ca+ c!
;

\ Other support functions.

: ip=   ( adr1 adr2 -- flag )  /ip-addr comp 0=  ;
: ip<>  ( adr1 adr2 -- flag )  /ip-addr comp 0<> ;

: copy-ip-addr ( src dst -- )  /ip-addr move ;

: ip=broadcast? ( ipaddr -- flag )
   dup inaddr-broadcast ip=  swap inaddr-any ip=  or
;

: inaddr-any? ( ipaddr -- flag )  inaddr-any ip= ;

: .ipaddr ( ipaddr -- )
   base @ >r  decimal
   /ip-addr 1- 0  do dup c@ (u.) type ." ."  ca1+ loop c@ (u.) type
   r> base !
;

headers
