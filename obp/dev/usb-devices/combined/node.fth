\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: node.fth
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
id: @(#)node.fth 1.13 02/12/11
purpose: 
copyright: Copyright 1998-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: find-fcode  ( adr1 len1 -- adr2 len2 true | false )
   " sunw,find-fcode" get-inherited-property drop
   decode-int nip nip
   execute
;

: find-hub-fcode  ( -- addr len )  " hub"  find-fcode drop  ;

: find-kbd-fcode  ( -- addr len )  " kbd"  find-fcode drop  ;

: create-reg  ( -- )  my-space  encode-int  " reg" property  ;

: my-0max-packet  ( -- )		\ must be there
   " 0max-packet" get-my-property drop
   decode-int nip nip
   to 0max-packet
;

\ XXX really bad code
: finish-node  ( -- went-ok? )
   " combined finish" diag-crtype			\ XXX debug
   create-reg
   my-0max-packet
   my-speed my-usb-adr
   get-dev-descrip			( dadr dcnt hw-err? | stat 0 )
   ?dup  if
      data-overrun-error <>  if			\ data-over benign here
         dma-free
         device-name
         disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
         false  exit
      then
   else  stall-or-nak?  if
         dma-free
         device-name
         disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
         false  exit
      then
   then
   over d-descript-maxpkt c@
   to 0max-packet
   dma-free
   " combined d-desc" diag-crtype		\ XXX debug
   my-speed my-usb-adr
   get-dev-descrip		( dadr dcnt hw-err? | stat 0 )
   ?dup  if				\ hw-err found; already printed
      drop
      dma-free
      device-name
      disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
      false  exit
   else  stall-or-nak?  if
         dma-free
         device-name
         disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
         false  exit
      then
   then
   >r dup >r					( dadr ) ( R: dcnt dadr )
   " combined int-desc" diag-crtype		\ XXX debug
   my-speed my-usb-adr
   get-int-descrip	( dadr iadr icnt hw-err? | stat 0 ) ( R: dcnt dadr )
   ?dup  if
      drop
      r> r> dma-free dma-free
      drop
      device-name
      disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
      false  exit
   else  stall-or-nak?  if
         r> r> dma-free dma-free
         drop
         device-name
         disabled-prop			\ XXX wrong, actually, since the
						\ hub has it still enabled.
         false  exit
      then
   then				( dadr iadr icnt ) ( R: dcnt dadr )
   >r dup >r			( dadr iadr ) ( R: dcnt dadr icnt iadr )
   " combined name" diag-crtype			\ XXX debug
   2dup create-combined-name
   swap create-combined-compat
   r> r> dma-free
   r> r> dma-free
   " combined endpts" diag-crtype		\ XXX debug
   publish-endpoints
   " combined published" diag-crtype		\ XXX debug
;

: my-name?  ( adr len -- my-name? )
   " name" get-my-property drop
   decode-string 2swap 2drop
   rot over =  if
      comp 0=
   else  2drop drop false
   then
;

: hub?  ( -- hub? )  " hub" my-name?  ;

: kbd?  ( -- kbd? )  " keyboard" my-name?  ;

: mouse?  ( -- mouse? )  " mouse" my-name?  ;

: bogus-properties  ( -- )
   kbd?  if  0 0 " keyboard" property  then
   mouse?  if  0 0 " mouse" property  then
;

: make-hub  ( -- )
   find-hub-fcode
   over 1 byte-load
   dma-free
;

: make-kbd  ( -- )
   find-kbd-fcode
   over 1 byte-load
   dma-free
;

: make-node  ( -- )
   finish-node  if
      hub?  if  make-hub
      else  kbd?  if  make-kbd
         then
      then
      bogus-properties		\ For bad coupling to main OBP and OS
   then
;

make-node

\ Parent creates low-speed, assigned-address properties.
\ This stuff creates name, compatible, reg, endpoints, and conditionally
\ executes hub or kbd fcode.
