\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: vocab-util.fth
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
id: @(#)vocab-util.fth 1.4 02/05/24
purpose:
copyright: Copyright 2000-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

exported-headers

\ byte-keyword is treated as a byte value, therefore one and only one
\ byte-keyword can be accepted by SETENV.
\ bit-keyword is treated as a bit value, therefore multiple bit-keywords
\ can be accepted by SETENV, as long as *different* bits are set in
\ the stream of keywords accepted by SETENV.
\ Both bit-keywords and byte-keywords may be defined in a 
\ single keyword vocabulary.

4 actions
action: c@      ;  \ return value
action: 2drop   ;  \ should not be used
action:         ;  \ should not be used
action: /c + c@ ;  \ return mask

: byte-keyword create c, h# ff c, use-actions ;
: bit-keyword  create dup c, c,   use-actions ;

unexported-words

d# 20 buffer: invalid-value 

: save-value ( str len -- )  invalid-value $cat ;

: ?invalid-value ( flag -- str len )
   if
      0 invalid-value c! (.d) save-value "  (invalid value)" save-value 
      invalid-value count
   then
;

alias value> get ( acf -- value ) ( 0 perform-action ) 
: mask>          ( acf -- mask  )   3 perform-action ;

: next-keyword ( str len -- rem len str len' true | false )
   begin				( str len)
      bl left-parse-string		( rem len str len')
      dup 0<> if			( rem len str len')
         true exit			( rem len str len' true)
      else				( rem len str len')
         2drop				( rem len)
      then				( rem len)
   dup 0= until				( rem len str len')
   2drop false				( rem len str len' true | false)
;

: wrong-keyword ( voc -- )
   cr ." Options:" also execute words previous cr cr abort 
;

\ Accepts both byte-keywords and bit-keywords; For byte-keywords checks
\ the validity of the keywords and returns the associated value n;
\ For bit-keywords checks the validity and applicability of every
\ bit-keyword in the stream; Multiple bit-keywords are not allowed,
\ for example
\ setenv post-trigger none none
\ will result in error.

: voc-string>value ( adr,len voc -- n )
   over 0=  if  wrong-keyword  then  \ Empty string can't contain a valid keyword
   >r 0 0 2>r				( adr len)		( R: voc c-n c-mask)   
   begin  next-keyword  while		( rem,len adr len)	( R: voc c-n c-mask)
     2r> r@ -rot 2>r search-wordlist if	( rem,len acf)		( R: voc c-n c-mask)
       dup mask>			( rem,len acf mask)	( R: voc c-n c-mask)
       r@ and  if			( rem,len acf)		( R: voc c-n c-mask)
          2r> r> wrong-keyword \ Keyword not permitted	( ??? )	( R:) 
       else				( rem,len acf)		( R: voc c-n c-mask)
          r> over mask> or swap		( rem,len mask acf)	( R: voc c-n)
          value> r> or >r >r		( rem,len)		( R: voc c-n c-mask)
       then				( rem,len)		( R: voc c-n c-mask) 
     else				( rem,len)		( R: voc c-n c-mask) 
       2r> r> wrong-keyword    \ No such keyword 	( ???)	( R:)
     then				( rem,len)		( R: voc c-n c-mask)
   repeat				( rem,len)		( R: voc c-n c-mask)
   r> drop r> r> drop			( n )
;

d# 255 buffer: keywords
 
: add-keyword ( addr len -- )  keywords $cat "  " keywords $cat ;

\ Works with both byte-keywords and bit-keywords. For byte-keywords
\ simply tries to match the value n to the associated byte-keyword.
\ For bit-keywords tries to match all bits set in n to the associated
\ bit-keywords and returns the list of all "matching" bit-keywords.

: voc-value>string ( n voc -- adr,len false | n true )
   0 keywords c!			( n voc)
   swap >r 0 swap			( alf voc)		( R: n)
   begin  another-word?  while		( alf voc anf)		( R: n)
     dup name> 				( alf voc anf acf)	( R: n)
     dup mask> h# ff =  if ( byte kwrd) ( alf voc anf acf)	( R: n)
        value> r@ = keywords c@ 0= and  if ( alf voc anf)	( R: n)
           -rot r> 3drop name>string	( adr,len) 
           false exit			( adr,len false)
        then				( alf voc anf)		( R: n)
     else  ( bit keyword)		( alf voc anf addr)	( R: n)
        value> r@ over and =  if	( alf voc anf)		( R: n)
           dup name>string add-keyword	( alf voc anf)		( R: n)
        then				( alf voc anf)		( R: n)
     then				( alf voc anf)		( R: n)
     drop				( alf voc)		( R: n)
   repeat				( )                     ( R: n)
   keywords count dup  if  r> drop false exit  then ( adr,len ) 
   2drop r> true			( true )
;
