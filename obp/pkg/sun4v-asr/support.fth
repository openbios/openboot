\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: support.fth
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
id: @(#)support.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

h# 200 buffer: svc-buf

\ [key][0][src][num][hi][lo][[str]reason[0]][hi][lo][[data]reason]
: (disable)  ( key$ rsn$ src -- status )
   >r 2swap tuck svc-buf swap move	( rsn$ klen )        \ key
   dup svc-buf + 0 over c!		( rsn$ klen buf )    \ null
   1+ r> over c!			( rsn$ klen buf )    \ src
   1+ 1 over c!				( rsn$ klen buf )    \ num
   1+ 2 pick over 2dup + 3 + >r		( rsn$ klen buf lo buf ) ( r: buf )
   0 swap c!				( rsn$ klen buf lo ) \ hi
   over 1+ c!				( rsn$ klen buf )    \ lo
   1 over 2+ c!				( rsn$ klen buf )    \ strtype
   3 + -rot over + >r move		( ) ( r: buf len )   \ rsn
   r> 0 r> c!				( len )              \ null
   7 + svc-buf swap			( buf len )
   svc-disable				( status )
;

\ [key][0][src]
: (enable)  ( key$ src -- status )
   -rot tuck svc-buf swap move		( src keylen )
   svc-buf over + 0 swap c!		( src keylen )
   tuck svc-buf + 1+ c!			( keylen )
   2 + svc-buf swap			( buf len )
   svc-enable				( status )
;

\ cmd: [nexus][0][unit][0]
: (query)  ( nexus$ unit$ -- flags )
   dup >r 2swap dup >r			( unit$ nexus$ ) ( r: ulen nlen )
   tuck svc-buf swap move		( unit$ nlen ) ( r: ulen nlen )
   svc-buf + dup >r 0 swap c!		( unit$ ) ( r: ulen nlen buf )
   tuck r@ 1+ swap move			( ulen )
   r> 1+ + 0 swap c!			( )
   svc-buf r> r> + 2+			( buf len )
   svc-query				( flags )
;

: (asr-state) ( buf -- len )  svc-state drop ;
: (statelen) ( -- len )  svc-statelen drop ;
