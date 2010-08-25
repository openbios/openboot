\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: endpoints.fth
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
id: @(#)endpoints.fth 1.4 03/05/12
purpose: 
copyright: Copyright 1999-2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Get endpoint descriptors for this interface.  Using the information,
\ construct the value of the endpoints property and publish it.
\ One particular use is for the usb keyboard stuff, so that it can work
\ with an interface as well as a combined device.  Similarly for the hub
\ interfaces.

\ endpoints property value is a string of pairs separated by a , character.
\ Each pair is a hex endpoint number, followed by a , character, followed
\ by the max-packet value for that endpoint.  The whole property starts
\ with endpoint 0.  The whole property value is string-encoded.
\ E.g., "0,8,1,40" shows endpoint 0 with max-packet 8, followed by
\ endpoint 1 with max-packet h# 40.

\ read ith endpoint descriptor
\ extract the endpoint # and its max-packet
: read-ith-endpoint#  ( int-desc i -- endpoint# max-pkt )
   find-ith-endpoint-start dup
   e-descript-endpoint-id c@  swap
   e-descript-max-pkt le-w@
;

: my-speed  ( -- lo-speed? )
   " low-speed" get-my-property  if
      false
   else  2drop true
   then
;

: my-usb-adr  ( -- usb-address )
   " assigned-address" get-inherited-property drop
   decode-int nip nip
;

\ uses string1 for a string buffer

: publish-endpoints  ( -- went-ok? )
   string1 h# 1000 erase
   0max-packet
   h# 30 string1 c!			\ always report endpoint 0
   string1 1				\ string so far
   ,append
   #append
   my-speed my-usb-adr my-space get-int#-descriptor
					( string1 len int-desc icnt hw-err? | stat 0 )
   ?dup  if
      drop
      dma-free
      2drop
      " disabled" encode-string " status" property	\ XXX not really; can't disable
							\ an interface by itself
      false  exit
   else  stall-or-nak?  if
         dma-free
         2drop
         " disabled" encode-string  " status" property	\ XXX still not really
         false  exit
      then
   then
   >r dup >r  -rot
   r@ i-descript-#endpoints c@		( int-desc $addr cnt #enpts ) ( R: icnt int-desc )
   0 ?do			( int-desc $addr cnt )  ( R: icnt int-desc )
      ,append
      2 pick i read-ith-endpoint#
      >r  -rot #append ,append				\ endpoint
      r> -rot #append					\ max-packet
   loop				( int-desc string1 cnt )  ( R: icnt int-desc )
   r> r> dma-free		\ dump all the memory used.
   encode-string  " endpoints" property
   drop
   true
;
