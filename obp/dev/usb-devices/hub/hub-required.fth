\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hub-required.fth
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
id: @(#)hub-required.fth 1.8 01/09/20
purpose: 
copyright: Copyright 1998-2001 Sun Microsystems, Inc.  All Rights Reserved

create bad-number			\ "Bad number syntax"
   d# 17 c,
   ascii B c,  ascii a c,  ascii d c,  bl c,  ascii n c,
   ascii u c,  ascii m c,  ascii b c,  ascii e c,  ascii r c,
   bl c,  ascii s c,  ascii y c,  ascii n c,  ascii t c,
   ascii a c,  ascii x c,  0 c,

: $>number  ( adr len -- n )
   $number  if  bad-number throw  then
;

0 value open-count

external

: decode-unit  ( adr len -- port# )
   base @ >r  hex
   dup if  $>number
   else  2drop  bad-number throw
   then
   r> base !
;

10 buffer: unit-address		\ can be used while no instance is open.

\ XXX check the other encode-units for other modules -- uses a volatile
\ area.
: encode-unit  ( port# -- adr len )
   unit-address 10 erase
   base @ >r  hex
   <# u#s u#>
   dup >r
   unit-address swap move
   unit-address r>
   r> base !
;


\ XXX open dma-alloc a request packet and a data buffer (close dma-free them)
\ for talking to the status endpoint.
\ XXX need two data buffers, one for config-descrip, one for dev-descrip
\ maybe three?
: open  ( -- ok )
   open-count 0=  if
      /request dma-alloc  to request-blank
      /common-buffer dma-alloc  to common-buffer
      0max-packet to max-packet
   then
   open-count 1+  to open-count
   true
;

: close  ( -- )
   open-count 1-  to open-count
   open-count 0=  if
      common-buffer /common-buffer dma-free
      -1 to common-buffer
      request-blank /request dma-free
      -1 to request-blank
   then
;

: reset  ( -- )  ;

headers
