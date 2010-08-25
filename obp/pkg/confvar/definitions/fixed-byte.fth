\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fixed-byte.fth
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
id: @(#)fixed-byte.fth 1.2 01/11/30
purpose:
copyright: Copyright 1998-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Fixed config variables may not be created at runtime, so all the
\ construction routines are transient.

unexported-words 

7 actions
action: ( apf -- value )                fixed-adr c@ 0<> ;
action: ( value apf -- )                swap n->c swap set-fixed-vocab-value  ;
action: ( apf -- adr )                  fixed-adr ;
action: ( value apf -- adr,len )        swap n->c swap get-fixed-vocab-value  ;
action: ( adr,len apf -- value )        fixed-vocab-encode 0<> ;
action: ( apf -- value )                fixed-nodefault? 0<> ;
action: ( apf -- value )                >fixed-default c@ 0<> ;

exported-headers transient
 
: fixed-flag \ name ( default -- )
   0 decode-flag ['] boolean-voc >r    ( default$ ) 
   r@ voc-string>value                 ( default )
   1 dup fixed-config c, c,            ( )
   align r> token,                     ( )
   use-actions                         ( )
;
 
: nodefault-fixed-flag \ name ( voc -- )
   1 dup nodefault-fixed-config c,     ( )
   align ['] boolean-voc token,        ( )
   use-actions                         ( )
;
 
resident unexported-words
