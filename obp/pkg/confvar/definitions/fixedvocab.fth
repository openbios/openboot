\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fixedvocab.fth
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
id: @(#)fixedvocab.fth 1.5 01/11/02
purpose: Implements binary representation of text strings
copyright: Copyright 1995-2001 Sun Microsystems, Inc.  All Rights Reserved

unexported-words

: >fixed-vocab-acf ( apf -- acf ) >fixed-default #align round-up token@ ;

: fixed-vocab-encode    ( adr,len apf -- value )                
   >fixed-vocab-acf voc-string>value ;

: fixed-vocab-decode    ( value apf -- adr,len false | n true ) 
   >fixed-vocab-acf voc-value>string ;

: get-fixed-vocab-value ( value apf -- str,len ) 
   fixed-vocab-decode ?invalid-value ;

: set-fixed-vocab-value ( value apf -- )
   2dup fixed-vocab-decode  if          ( value apf n )   
      ." Invalid value for configuration parameter; previous value retained." 
      cr 3drop exit
   then                                 ( value apf adr,len)
   2drop fixed-byte!                    ( )
;
 
7 actions
action: ( apf -- value )		fixed-adr c@  ;
action: ( value apf -- )		set-fixed-vocab-value  ;
action: ( apf -- adr )			fixed-adr  ;
action: ( value apf -- adr,len )	get-fixed-vocab-value  ;
action: ( adr,len apf -- value )	fixed-vocab-encode ;
action: ( apf -- value )		fixed-nodefault? ;
action: ( apf -- value )		>fixed-default c@ ;

exported-headers

: fixed-vocab-variable \ name ( default-value voc -- )
   dup >r				( default$ voc )
   voc-string>value			( default )
   1 dup fixed-config c, c,		( )
   align r> token, 			( )
   use-actions				( )
;

: nodefault-fixed-vocab-variable \ name ( voc -- )
   1 dup nodefault-fixed-config c,      ( voc )
   align token,                         ( )
   use-actions                          ( )
;

unexported-words
