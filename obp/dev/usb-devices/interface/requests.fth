\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: requests.fth
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
id: @(#)requests.fth 1.5 00/05/09
purpose: 
copyright: Copyright 1997-2000 Sun Microsystems, Inc.  All Rights Reserved

: request-blank  ( -- addr )  /request dma-alloc  ;

: descript-form  ( len -- addr )
   request-blank
   get-descript-req over request-type w!
   swap over req-len le-w!
;

: get-dev-descript-form  ( len -- addr )
   descript-form
   device-descript over req-value 1+ c!
;

: get-config-descript-form  ( len -- addr )
   descript-form
   config-descript over req-value 1+ c!		\ need index as well
;

: get-dev-descrip  ( speed usb-adr -- dev-descrip-addr dcnt hw-err? | stat 0 )
   0 swap 0max-packet swap
   /dev-descriptor dma-alloc
   dup >r swap
   /dev-descriptor swap
   /dev-descriptor get-dev-descript-form
   dup >r swap
   /request swap
   0 swap execute-control
   r> /request dma-free
   ?dup
   r> /dev-descriptor
   2swap
   0=  if  0  then
;

: get-config-descrip  ( speed usb-adr n cnt
			-- config-n-descrip-addr cnt hw-err? | stat 0 )
   swap rot >r >r >r				( R: usb-addr n cnt )
   0 0max-packet
   r@ dma-alloc					( speed in max c-d-addr )
   r> r> r>				( speed in max c-d-addr cnt n u-addr )
   2over >r >r >r >r			( R: cnt c-addr u-addr n )
   dup get-config-descript-form
   r> over req-value c!		( speed in max c-addr cnt pak-adr )
   r> over >r >r		( R: cnt config-desc packet-addr usb-addr )
   /request 0 r>  execute-control
   r> /request dma-free
   ?dup
   r> r>
   2swap
   0=  if  0  then
;

\ XXX keyboard/mouse respond with expected stuff at 1
: get-config1-descrip  ( speed usb-adr
			-- config1-descrip-addr ccnt hw-err? | stat 0 )
   0 /config-descriptor get-config-descrip
;

: .usb  ( stat -- )
   case  2 of  noop              endof
         6 of  cr ." usb-nak"    endof
         e of  cr ." usb-stall"  endof
      cr ." usb-unknown"
   endcase
;

: stall-or-nak?  ( stat -- stall-or-nak? )
   dup .usb					\ XXX debug
   dup e =  swap 6 =  or
;

: idump  ( adr cnt -- )				\ XXX debug
   " dump" $find drop execute
;

\ get config1 descriptor for total count
\ get the entire config1 descriptor.  copy interfacen descriptor to buffer
: get-int#-descriptor  ( speed usb-adr i#
				-- intn-descrip-addr icnt hw-err? | stat 0 )
   " interface get-config1" diag-crtype		\ XXX debug
   >r  2dup get-config1-descrip
			( spd usb-adr c1-adr ccnt hw-err? | stat 0 )  ( R: i# )
   dup  if				\ hw-err found; already printed
      r> drop
      >r 2swap 2drop r>
      exit
   else
      over stall-or-nak?  if
         r> drop
         2rot 2drop
         exit
      else  2drop			\ ok so far
      then
   then
\   cr 2dup idump			\ XXX debug
   over c-descript-total le-w@		\ count of total descriptor
   -rot dma-free			( speed u-adr c-total ) ( R: i# )
\ XXX keyboard/mouse respond with expected stuff at 1
   " interface get-config-all" diag-crtype	\ XXX debug
   0 swap
   get-config-descrip		\ get entire config1 descriptor
   dup  if				\ hw-err; already printed
      r> drop
      exit
   else
      over stall-or-nak?  if
         r> drop
         exit
      else  2drop			\ went ok; status replaced below
      then
   then
\   cr 2dup idump			\ XXX debug
   2dup r> find-int-start		( c-addr ccnt i-addr ccnt2 )
   dup dma-alloc  over >r  dup >r	( R: icnt intn-descrip-addr )
   swap move				( c-addr ccnt )
   dma-free
   r> r>
   2 0					\ dummy good status replacement
;

: clear-stall  ( speed endpoint usb-adr -- hw-err? | stat 0 )
   >r
   request-blank >r
   clear-feature-req h# 200 or  r@ request-type w!
   endpoint-stall r@ req-value le-w!
   r@ req-index le-w!
   1 0max-packet 0 0
   r> /request
   0 r> 2over >r >r
   execute-control
   r> r> dma-free
;
