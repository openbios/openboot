\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: finder.fth
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
id: @(#)finder.fth 1.7 99/06/03
purpose: 
copyright: Copyright 1998-1999 Sun Microsystems, Inc.  All Rights Reserved

\ XXX for plugin card.  map fcode prom. find fcode bits.  save in
\ buffer(s).  unmap fcode prom.  do at probe time.  dump after probing
\ is complete.
\ : get-fcode-bits  ( -- )
\ ;

\ for cpu bootprom.  look in /packages/SUNW,builtin-drivers.
\ If found, user must dma-free when done with the image.

\ adr1 len1 is a string that is the name of a bunch of fcode.
\ adr2 len2 is a location&size for it (max 64K).
\ return true if it can be found.  return false if it is not found.

: find-fcode  ( adr1 len1 -- adr2 len2 true | false )
   my-self >r
   saved-self to my-self
   " SUNW,builtin-drivers" find-package  drop	\ XXX must be present
   find-method  if
      >r
      h# 1.0000 dma-alloc
      h# 1.0000  2dup
      r> execute  if
         true
      else  dma-free false
      then
   else
      false
   then
   r> to my-self
;

\ make a property for find-fcode so that child nodes can get the fcode
\ they need.
: publish-finder  ( -- )
   ['] find-fcode  encode-int  " sunw,find-fcode" property
;

\ XXX better be present:
: find-device-fcode  ( -- addr len )  " device" find-fcode drop  ;

\ XXX better be present:
: find-combined-fcode  ( -- addr len )  " combined" find-fcode drop  ;


