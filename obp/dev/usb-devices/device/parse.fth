\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: parse.fth
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
id: @(#)parse.fth 1.2 00/04/04
purpose: 
copyright: Copyright 1998, 2000 Sun Microsystems, Inc.  All Rights Reserved

: next-descriptor  ( addr1 -- next-addr )
   dup c@ +
;

: #remaining  ( addr1 addr2 cnt1 -- cnt2 )
   -rot swap - -
;

: interface-descript?  ( addr -- interface? )
   1+ c@  interface-descript =
;

: alt0?  ( addr -- ok? )  i-descript-alt-id c@ 0=  ;

: int-alt0?  ( addr -- this-one? )
   dup interface-descript?
   swap  alt0? and
;

\ loop through the descriptor as long as it is not an interface descriptor,
\ alternative setting 0.  When it is, return the start and remaining number of
\ bytes in the descriptor.
: find-int-descrips  ( conf-adr ccnt -- int-adr ccnt2 )
   >r					( R: cnt )
   begin			( addr )  ( R: cnt )
      dup next-descriptor	( addr1 addr2 )
      tuck r> #remaining >r
      dup int-alt0?
   until
   r>
;

\ Advance the address, decrement the count to the next interface descriptor
\ if there is one.  Watch out if input is already the last valid descriptor.
\ Would ...do +loop work here?  Not sure of the interaction with 32/64 bitness
\ and addresses.
: no-more-interfaces?  ( iadr icnt -- iadr1 icnt1 no-more? )
   2dup + >r				( R: max-valid-address )
   begin
      over next-descriptor		( iadr icnt iadr' )  ( R: max-valid )
      r@ <  if				\ valid descriptor address
         >r  dup next-descriptor
         tuck r> #remaining		( iadr' icnt' ) ( R: max-valid )
         over int-alt0?  if		\ found the next interface descriptor
            false			( iadr1 icnt1 no-more? ) ( R: max-valid )
            true			\ interface descriptor found
         else
            false			\ try next descriptor
         then
      else				\ invalid descriptor address; walked out the end
         true				( iadr1 icnt1 no-more? ) ( R: max-valid )
         true				\ all descriptors used up
      then
   until
   r> drop
;
