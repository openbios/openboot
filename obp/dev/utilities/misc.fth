\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: misc.fth
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
id: @(#)misc.fth 1.8 06/04/21 17:09:09
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

-1 d# 32 rshift constant 32bit-mask

\ Logical operations only work on 32 bits for this code.
: or32  ( a b -- c ) or  32bit-mask and  ;
: and32 ( a b -- c ) and 32bit-mask and  ;

: diag-cr ( -- )		diagnostic-mode? if  cr  then  ;
: diag-type ( str$ -- )		diagnostic-mode? if  type  else  2drop  then  ;
: diag-type-cr ( str$ -- )	diag-type diag-cr  ;

\ Watch-out!!
: 2>r ( a b -- ) r> -rot swap >r >r >r ;
: 2r> ( -- a b ) r> r> r> rot >r swap ;

: push-hex ( -- ) r> base @ >r >r hex ;
: pop-base ( -- ) r> r> base ! >r ;

: integer-property ( n name$ -- ) rot encode-int  2swap property  ;
: boolean-property ( name$ -- ) 0 0 2swap property ;

: round-down ( n -- n' )  1- invert and ;
: round-up   ( n -- n' )  1- tuck + swap invert and  ;

: $call-self ( method$ -- ?? ) my-self $call-method ;

: $hnumber ( str len -- true | n false )  push-hex  $number  pop-base  ;

: $hdnumber?  ( adr len -- false | d true )
   push-hex $number if 0 else 1 then pop-base
;

: $hold  ( adr len -- )
   dup  if  bounds swap 1-  ?do  i c@ hold  -1 +loop  else  2drop  then
;

: $save ( str len save -- save,len )  2dup 2>r swap move 2r> swap  ;

: /string tuck - -rot + swap ;

: align ( -- )  here /n round-up here - 0 ?do 0 c, loop ;

: en+ ( xdr,len int -- xdr',len' ) encode-int encode+ ;

\ The top 5 stack elements when this routine is called will be
\ en+'d.
: encode5 ( xdr,len a b c d e -- xdr',len' )
   >r >r >r >r en+			( xdr,len )
   r> en+ r> en+ r> en+ r> en+		( xdr,len )
;

\ The tokenizer expands '.x' into this sequence, it is more efficient to
\ do it this way.
: .x ( n -- ) push-hex . pop-base ;

\  This gets called quite a lot...
: (decode-unit) ( unit$ -- pa.lo pa.mid pa.hi )  " decode-unit" $call-self  ;
