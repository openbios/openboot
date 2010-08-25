\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ethernet.fth
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
id: @(#)ethernet.fth 1.1 04/09/07
purpose: Ethernet initialization and input/output routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

d# 6  constant	/ether-addr		\ Ethernet Address, 6 octets

\ Ethernet header structure
struct
   /ether-addr  field   >en-dest-addr
   /ether-addr  field   >en-src-addr
   /w           field   >en-type
constant /ether-header

d# 1500 constant ETHERMTU       	\ Max frame without header or fcs
d# 1514 constant ETHERMAX       	\ Max frame with header and without fcs

: send-ethernet-frame    ( adr len -- #sent )  " write" $call-parent ;
: receive-ethernet-frame ( adr len -- #rcvd )  " read" $call-parent 0 max ;

: ether-input ( -- frame framelen type true | false )
   frame-alloc dup if
      dup ETHERMAX receive-ethernet-frame ?dup  if
         over >en-type ntohw@ true
      else
         frame-free false
      then
   then
;

: ether-output ( frame framelen dest.enaddr type -- #sent )
   3 pick tuck    >en-type      htonw!
   if-hwaddr over >en-src-addr  copy-hw-addr
                  >en-dest-addr copy-hw-addr
   send-ethernet-frame
;
    
: .enaddr ( enaddr -- )
   base @ >r  hex
   /ether-addr 1- 0  do dup c@ (u.) type ." :"  ca1+ loop c@ (u.) type
   r> base !
;

\ Initialize MAC interface state
: ether-ifinit ( -- )
   if-data >r
   HWTYPE_ETHER        r@ >if-htype        c!
   /ether-addr         r@ >if-addrlen      c!
   /ether-header       r@ >if-hdrlen       c!
   ETHERMTU            r@ >if-mtu          l!
   mac-address         r@ >if-hwaddr swap  move
   r@ >if-broadcast    /ether-addr h# ff   fill
   ['] ether-output    r@ >if-output       !
   ['] ether-input     r@ >if-input        !
   ['] .enaddr         r> >if-showaddr     !
;

: ether-ifclose ( -- )  ;

headers
