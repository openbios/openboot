\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: idprom.fth
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
id: @(#)idprom.fth 2.18 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

h# 20 constant /idprom
/idprom buffer: idprom-buf

[ifndef] SUN4V
0 value idprom-phandle

also magic-device-types definitions
headers

: idprom ( xdr,len prop$ -- )
   idprom-phandle if  exit  then
   my-self ihandle>phandle to idprom-phandle
;

previous definitions
[then]

headerless
: idprom@  ( -- byte )  idprom-buf + c@  ;
: idprom-checksum  ( -- n )
   0  d# 15 0  do  i idprom@ xor  loop
;

\ Verifying ID PROM format and checksum is sufficient
\ to validate ID PROM structure
: (idprom-valid?  ( -- flag )
   0 idprom@  1 =                          \ Verify the ID PROM format
   idprom-checksum  d# 15 idprom@  =  and  \ Verify the checksum
;
' (idprom-valid? is idprom-valid?

: .idbytes  ( offset count -- )  bounds do  i idprom@ .h  loop ;

: hostid  ( -- n )
   d# 14 idprom@	( b.lo )
   d# 13 idprom@	( b.mlo )
   d# 12 idprom@	( b.mhi )
       1 idprom@ 	( b.hi )
   bljoin		( n )
;

: (serial#  ( -- n )  hostid 1 d# 31 lshift invert and  ;
' (serial# is serial#

: (system-mac-address  ( -- adr len )  idprom-buf 2+  6  ;
' (system-mac-address is system-mac-address

headers
: .idprom  ( -- )
   ." Format/Type: "  0     2 .idbytes
   ." Ethernet: "     2     6 .idbytes
   ." Date: "         8     4 .idbytes
   cr
   ." Serial: "   d# 12     3 .idbytes
   ." Checksum: " d# 15     1 .idbytes
\  ." Reserved: " d# 16 d# 16 .idbytes
;

[ifdef] SUN4V
: idprom! ( d n -- ) idprom-buf + c! ;

: init-idprom  ( -- )
   idprom-buf /idprom erase
   h# 01 0 idprom!
   " platform" 0 pdfind-node  >r			( ) ( r: node )
   " hostid" -1 r@ pdget-prop ?dup if			( prop )
      pdentry-data@					( n )
      lbsplit 
      1 idprom!	 3 0 do	 d# 12 i +  idprom!  loop	( )
   then							( ) ( r: node )
   " mac-address" -1 r>  pdget-prop ?dup if		( prop ) ( r: )
      pdentry-data@					( n )
      6 0 do dup 7 i - idprom! 8 >> loop drop		( )
   then							( )
   idprom-checksum d# 15 idprom!			( )
   root-device
      idprom-buf /idprom  encode-bytes " idprom" property
   device-end
;
[else]
: init-idprom ( -- )
   idprom-phandle ?dup 0= abort" No IDPROM"r"n"
   phandle>devname open-dev ?dup if
      >r
      idprom-buf /idprom " read" r@ $call-method drop
      r> close-dev
      root-device
         idprom-buf /idprom  encode-bytes " idprom" property
      device-end
   else
      ." IDPROM device didn't open" cr
   then
;
[then]

stand-init: Setting IDPROM property
   ['] init-idprom catch drop
;
