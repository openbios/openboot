\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: local-mac-addr.fth
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
id: @(#)local-mac-addr.fth 1.1 06/02/16
purpose: Apply local mac address properties using devaliases
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ local-mac-address := system-mac-address + n
: (do-local-mac-address) ( n $path -- )
   ['] find-device catch 0=  if		( n )
      system-mac-address            ( n mac len )
      here 2dup >r >r swap allot r@ ( n mac vaddr len r: n vaddr len )
      move r> r>                    ( n len vaddr )
      0 over 6 3 do                 ( n len vaddr 0 vaddr )
         dup i + c@ swap            \ Fetch low-order three bytes of MAC
      loop drop bljoin lbflip       ( n len vaddr low-order-mac )
      3 pick +                      ( n len vaddr low-order-mac' )
      over >r lbsplit drop r>       ( n len vaddr m5 m4 m3 vaddr )
      6 3 do
         tuck i + c!
      loop drop -rot nip            ( vaddr len )
      encode-bytes " local-mac-address" property  ( )
      device-end
   else 
      3drop				( ) \ find-device failed
   then
;

: do-local-mac-address ( -- )
   current-device >r
      0 " net0" (do-local-mac-address)
      1 " net1" (do-local-mac-address)
      2 " net2" (do-local-mac-address)
      3 " net3" (do-local-mac-address)
   r> push-device
;

stand-init: Set local mac address properties
   current-device >r
      do-local-mac-address
   r> push-device
;

