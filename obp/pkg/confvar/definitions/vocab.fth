\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: vocab.fth
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
id: @(#)vocab.fth 1.3 01/11/30
purpose:
copyright: Copyright 2000-2001 Sun Microsystems, Inc.  All Rights Reserved

unexported-words

: >vocab-acf      ( apf -- acf )  >config-default 1+ #align round-up token@ ;

: vocab-encode    ( adr,len apf -- value )                >vocab-acf voc-string>value ;
: vocab-decode    ( value apf -- adr,len false | n true ) >vocab-acf voc-value>string ;
: get-vocab-value ( value apf -- str,len )                vocab-decode  ?invalid-value ;
 
: set-vocab-value ( value apf -- )
   2dup vocab-decode  if		( value apf n )	
      ." Invalid value for configuration parameter; previous value retained." cr 3drop exit
   then 				( value apf adr,len)
   2drop config-byte! 			( )
;

7 actions
action: ( apf -- value )		config-adr c@  ;
action: ( value apf -- )		set-vocab-value  ;
action: ( apf -- adr )			config-adr  ;
action: ( value apf -- adr,len )	get-vocab-value  ;
action: ( adr,len apf -- value )	vocab-encode ;
action: ( apf -- value )		nodefault? ;
action: ( apf -- value )		>config-default c@ ;

exported-headers

: vocab-variable \ name ( default$ voc -- )
   dup >r				( default$ voc )
   voc-string>value			( default )
   1 config-create c,			( )
   align r> token,			( )
   use-actions				( )
;

: nodefault-vocab-variable \ name ( voc -- )
   1 dup nodefault-create c,            ( voc ) 
   align token,                         ( ) 
   use-actions                          ( ) 
; 

unexported-words
