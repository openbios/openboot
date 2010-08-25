\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: confact.fth
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
id: @(#)confact.fth 1.9 01/11/30
purpose: Action names for configuration option data types
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Action names for configuration objects
\ 0 action = value on stack		( apf -- value )
\      call with: fieldname
\ 1 action = store value		( value apf -- )
\      call with: value to fieldname
\ 2 action = adr on stack		( apf -- adr )
\      call with: addr fieldname
\ 3 action = decode for display		( apf -- adr len )
\ 4 action = encode for storage		( adr len apf -- )
\ 5 action = has-default?		( apf -- flag )
\ 6 action = default value		( apf -- value )
\ "value" is either int, char, or ( adr len) for strings
\ action 6 is only required to be present for values that have defaults.

\ Decoding byte values
: c->n ( byte -- n )  d# 24 <<  l->n  d# 24 >>a  ;
: n->c ( apf value -- byte apf ) h# ff and ;

\ Two useful boolean strings.
: true$ ( - str,len ) " true"  ;
: false$ ( -- str,len ) " false"  ;

\ Encoding/Decoding boolean flags 
: decode-flag ( n apf -- str,len )      drop if  true$  else  false$  then  ;
\ : encode-flag ( str,len apf -- n )      drop true$ $=  ;

\ encode-number is defined elsewhere

exported-headerless

: nodefault? ( acf -- flag )		5 perform-action  ;
: get-default  ( acf -- ??value?? )	6 perform-action  ;

: do-get-default ( acf -- str,len )
   dup nodefault? if			( acf )
      drop " No default"		( adr,len )
   else					( -- )
      >r r@ get-default			( ??value?? )
      r> decode				( adr,len )
   then					( adr,len )
;

: do-set-default ( acf -- )
   dup nodefault? if			( acf )
      drop				( -- )
   else					( acf )
      >r r@ get-default			( ??value?? )
      r> set				( -- )
   then					( -- )
;

unexported-words
