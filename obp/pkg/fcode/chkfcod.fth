\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: chkfcod.fth
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
id: @(#)chkfcod.fth 1.6 06/02/16 19:20:03
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\  Verify token addresses match FCodes

\ This is a post process step after we dispose all transient defs
\ so we need to reload the brackif support and the restored headers.
\
fload ${BP}/fm/lib/headless.fth
fload ${BP}/fm/lib/brackif.fth
[defined] kernel-hdr-file included

variable exp-fcode
0 exp-fcode !


headerless
\  If a word is not immediate,  get-token  returns 0 and  $find  returns -1
\  otherwise,  get-token  returns some non-zero and  $find  returns a 1.

: immediate-mismatch? ( get-tok-imm $find-imm -- mismatch? )
   1 = swap		( $find-imm=imm? get-tok-imm )
   0<>			( $find-imm=imm? get-tok-imm=imm? )
   xor
;

: .not-match-ferror ( $adr,len -- )
   ." FCode " exp-fcode @ .x ." does not match ferror's " type cr
   (compile-time-warning)
;

\ Verify all unimplemented fcodes point to ferror
: check-ferror ( -- )
   exp-fcode @ get-token swap ['] ferror  <>  if 	( immediate? )
      " address"         .not-match-ferror
   then
   ['] ferror immediate? <>  if
      " immediate field" .not-match-ferror
   then
;

: byte-code: \ name ( code# table# -- )

   bwjoin 					( fcode )

   \ Any fcodes skipped between byte-code: calls means it is an unimplemented fcode
   begin dup exp-fcode @ >  while		( fcode )
      check-ferror
      1 exp-fcode +!
   repeat

   \ get address and immediate field for current fcode and the token and verify
   \ token exists
   dup get-token swap				( fcode immediate? xt )

   safe-parse-word $find ?dup 0=  if 		( fcode immediate? xt adr len )
      ." token "  type	2drop			( fcode )
      ."  at FCode " dup .x ." does not exist" cr
      (compile-time-warning)
   else						( fcode immediate? xt acf n )
      \ addresses should match
      -rot 2swap 2>r  2>r  2r@  <>  if 	        (  fcode  ) ( r: immediate? n xt acf )
	 r@ ['] obsolete-fcode <>  if
	    ." FCode " dup .x 2r@ swap .name ." isn't the same as " .name cr
	    (compile-time-warning)
	 then
      then                                      (  fcode  ) ( r: immediate? n )
      2r> 2r>  immediate-mismatch?  if		( fcode xt acf )
         rot ." FCode " .x			( xt acf )
         ." has immediate-field mismatch with token " .name cr		( xt )
 	 (compile-time-warning) 		( xt )
     else					( fcode xt acf )
	 2drop					( fcode )
      then					( fcode )
   then  drop					(  )

   \ make sure exp-fcode points to next expected fcode
   1 exp-fcode +!
;

." Checking FCodes ...." cr

fload ${BP}/pkg/fcode/primlist.fth		\ Primitive (1-byte) fcodes
fload ${BP}/pkg/fcode/sysprims.fth		\ Basic system fcodes 
64\ fload ${BP}/pkg/fcode/sysprm64.fth		\ 64-bit fcodes

[ifdef] OBDIAG-SUPPORT
fload ${BP}/pkg/fcode/vfcodes/obdiag.fth	\ obdiag vfcodes
[then]

[ifdef] SUN4V
fload ${BP}/pkg/fcode/vfcodes/sun4v.fth		\ sun4v vfcodes
[then]

fload ${BP}/pkg/fcode/vfcodes/cmn-msg.fth	\ cmn messaging vfcodes 

headers

