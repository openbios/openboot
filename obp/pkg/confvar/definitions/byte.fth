\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: byte.fth
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
id: @(#)byte.fth 1.2 01/11/30
purpose: Configuration option data types, encoding, and commands
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

unexported-words

7 actions
action: config-byte@		;
action: config-byte!		;
action: config-adr		;
action: drop (.d)		;
action: encode-number		;
action: nodefault?		;
action: >config-default c@	;

exported-headers

: config-char  \ name  ( default-value -- )
   1 config-create  c, align  use-actions
;

: nodefault-char  \ name  ( default-value -- )
   1 nodefault-create  use-actions
;

unexported-words

7 actions
action: ( apf -- value )                config-byte@ 0<> ;
action: ( value apf -- )                swap n->c swap set-vocab-value  ;
action: ( apf -- adr )                  config-adr  ;
action: ( value apf -- adr,len )        swap n->c swap get-vocab-value  ;
action: ( adr,len apf -- value )        vocab-encode 0<> ;
action: ( apf -- value )                nodefault? 0<> ;
action: ( apf -- value )                >config-default c@ 0<> ;

exported-headers

: config-flag \ name ( default -- )
   0 decode-flag ['] boolean-voc >r	( default$)
   r@ voc-string>value                  ( default )
   1 config-create c,                   ( )
   align r> token,                      ( )
   use-actions                          ( )
;
 
: nodefault-flag \ name ( -- )
   1 dup nodefault-create c,            ( )
   align ['] boolean-voc token,         ( )
   use-actions                          ( )
;
 
unexported-words
