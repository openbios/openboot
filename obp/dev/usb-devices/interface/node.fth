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
id: @(#)node.fth 1.12 00/05/09
purpose: 
copyright: Copyright 1998-2000 Sun Microsystems, Inc.  All Rights Reserved

: find-fcode  ( adr1 len1 -- adr2 len2 true | false )
   " sunw,find-fcode" get-inherited-property drop
   decode-int nip nip
   execute
;

: find-hub-fcode  ( -- addr len )  " hub"  find-fcode drop  ;

: find-kbd-fcode  ( -- addr len )  " kbd"  find-fcode drop  ;

: disabled-prop  ( -- )  " disabled" encode-string " status" property  ;

: create-reg  ( -- )
   my-address my-space
   encode-int  rot encode-int encode+
   " reg" property
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

\ XXX don't activate this until hub code works for interface hubs:
: make-hub  ( -- )
\   find-hub-fcode
\   over 1 byte-load
\   dma-free
;

: make-kbd  ( -- )
   find-kbd-fcode
   over 1 byte-load
   dma-free
;

: make-node  ( -- )
   create-reg
   " interface get-ints" diag-crtype		\ XXX debug
   " 0max-packet" get-inherited-property	\ must be present
   drop  decode-int to 0max-packet
   2drop
   my-speed my-usb-adr my-space
   get-int#-descriptor
   ?dup  if				\ hw-err found; already printed
      drop
      dma-free
      interface-name
      disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
      exit
   else  stall-or-nak?  if
         dma-free
         interface-name
         disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
         exit
      then
   then
   2dup >r >r drop
   dup create-interface-name
   " interface get-config1" diag-crtype		\ XXX debug
   my-speed my-usb-adr get-config1-descrip
					( iadr cadr ccnt hw-err | stat 0 )
						( R: icnt iadr )
   ?dup  if				\ hw-err found; already printed
      drop
      r> r> dma-free dma-free
      drop
      disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
      exit
   else  stall-or-nak?  if
         r> r> dma-free dma-free
         drop
         disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
         exit
      then
   then
   2dup >r >r drop		( iadr cadr ) ( R: icnt iadr ccnt cadr )
   " interface get-dev" diag-crtype		\ XXX debug
   my-speed my-usb-adr get-dev-descrip
				( iadr cadr dadr dcnt hw-err? | stat 0 )
					( R: icnt iadr ccnt cadr )
   ?dup  if
      drop
      r> r> r> r> dma-free dma-free dma-free
      2drop
      disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
      exit
   else  stall-or-nak?  if
         r> r> r> r> dma-free dma-free dma-free
         2drop
         disabled-prop		\ XXX not really; interface can't
					\ be disabled by itself
         exit
      then
   then
   2dup >r >r drop
   create-interface-compat
   r> r> r> r> r> r>
   dma-free dma-free dma-free
   " interface endpoints" diag-crtype		\ XXX debug
   publish-endpoints  if
      hub?  if  make-hub
      else  kbd?  if  make-kbd
         then
      then
      bogus-properties		\ For bad coupling to main OBP and OS
   then
   " interface made" diag-crtype		\ XXX debug
;

make-node
