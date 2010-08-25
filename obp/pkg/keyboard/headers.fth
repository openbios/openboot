\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: headers.fth
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
\ id: @(#)headers.fth 1.6 99/02/17
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
\
\ This is the data that the keyboard dropin will contain..
\
headerless

1 constant table-encoding
2 constant diff-encoding
3 constant alias-encoding

struct \ kbd-table-header
  d#   2 field >kbd-data-size
  d#   1 field >kbd-country-len
  d#   0 field >kbd-country
constant /kbd-table-header

struct \ kbd-dropin
  d# 4 field >kbd-di-magic
  d# 1 field >kbd-di-default
  d# 0 field >kbd-di-data
constant /kbd-dropin

\
\ These routines take into account the variable size of the keyboard name
\
: >kbd-type   ( addr -- addr' ) dup >kbd-country-len c@ swap >kbd-country + ;
: >kbd-coding ( addr -- addr' ) >kbd-type 1+ ;
: >kbd-alias  ( addr -- addr' ) >kbd-coding 1+ ;
: >kbd-alias-data  ( addr -- addr' ) >kbd-alias 1+ ;
: >kbd-data   ( addr -- addr' ) >kbd-coding 1+ ;

h# 20 instance buffer: current-kbd

headerless
\ Identification code returned from keyboard
instance variable keybid

: >kbd-name ( adr,len -- )
  current-kbd swap	( adr buf len )
  2dup + 0 swap c!	( adr buf len )
  cmove			( -- )
;

