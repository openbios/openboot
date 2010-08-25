\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dq.fth
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
id: @(#)dq.fth 1.2 98/03/24
purpose: 
copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

: dump-copy  ( transfer-d -- )
   dup my-data @  swap caller-count @  give-chunk
;

: transfer-bits>copy-out?  ( transfer-d endp-bits -- copy-out? dummy )
   swap transfer-control le-l@
   d# 19 rshift  3 and				\ dp bits
   2 =						\ in
   swap
;

: copy-out?  ( transfer-d -- copy-out? )	\ look at bits
   dup my-endpoint @ endpoint-control le-l@
   d# 11 rshift  3 and				\ d bits
   case  1 of  drop false   endof
         2 of  drop true  endof
      transfer-bits>copy-out?
   endcase
;

: copy-out  ( transfer-d -- )			\ look at addresses/cnts
   dup my-data @ 0<>  over caller-data @ 0<> and
   over caller-count @ 0<> and  if
      dup my-data @
      over caller-data @
      rot caller-count @
      move
   else  drop
   then
;

: copy-for-client  ( transfer-d -- )
   dup copy-out?  if
      copy-out
   else  drop
   then
;

\ Dump the transfer-d.
: dump-transfer  ( transfer-d -- )
   dup my-endpoint @
   -1 swap transfer-count +!
   dup copy-for-client
   dup caller-count @  if  dup dump-copy  then
   /transfer give-chunk
;

\ XXX need special to dump all the copy-buffers??
: dump-isoc-transfer  ( transfer-d -- )
;

: ts-q>  ( endpoint-addr -- )
   dup td-tail@
   over td-head@ dev>virt			( endpt-addr tail-dev t-addr )
   begin
      2dup next-transfer le-l@ <> 
   while					( endpt-addr tail-dev t-addr )
      dup next-transfer le-l@ dev>virt
      swap dump-transfer
   repeat  drop				( endpoint-addr tail-dev )
   over td-head!
   sync-endpoint
;

\ Need to remove subsequent associated transfer d's when one has an error
\ or when removing an endpoint.
\ Assumes endpoint has been turned off.  Dump them all, except a dummy.
: clear-endpoint  ( endpoint-addr -- )
   dup td-tail@ over td-head@ = if		\ already empty
      drop
   else						( endpt-addr )
      ts-q>
   then
;

: wipe-endpoint  ( endpoint-addr -- )
   dup skip-endp
   next-frame
   clear-endpoint
;

\ Dump endpoint and dummy transfer
: toss-endpoint  ( addr -- )
   dup td-head@ dev>virt /transfer give-chunk
   /endpoint give-chunk
;

\ Assumes no transfer descriptors, except the dummy one at the end:
: eq>  ( addr -- )		\ Remove endpoint descriptor at addr from q

   dup  next-endpoint@		\ Stuff pointer to next into previous one
   over prev-endpoint @ next-endpoint!
   dup prev-endpoint @ sync-endpoint

	\ stuff pointer to prev into next:
   dup next-endpoint@ ?dup if				( addr next-dev )
      over prev-endpoint @
      swap dev>virt prev-endpoint !
      dup next-endpoint@ dev>virt sync-endpoint
   then							( addr )

   toss-endpoint
;

\ Don't dump the one at transfer-d, just the ones behind it.
: dump-following-transfer-d's  ( transfer-d endpoint -- )
   0 swap code-done-q !			\ this done-q can be reused now.
   next-transfer le-l@			( dev-transfer )
   begin
      ?dup
   while
      dev>virt  dup next-transfer le-l@
      swap dump-transfer
   repeat
;
