\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: package.fth
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
id: @(#)package.fth 1.2 06/06/02 
purpose: asr package methods
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

alias query-ok<> 0<>

: do-query  ( nexus$ unit$ -- status )
   ['] (query) catch if				( flags )
      2drop 2drop
      cmn-error[ " ASR Query Failed" ]cmn-end
      query-ok exit
   then						( flags )

   case
      flag-user-disabled of
         query-u-dis
      endof
      flag-diag-disabled of
         query-d-dis
      endof
      flag-user-disabled flag-diag-disabled or of
         query-ud-dis
      endof
      flag-user-disabled flag-override or of
         query-ovr
      endof
      flag-diag-disabled flag-override or of
         query-d-dis
      endof
      0 of
         query-ok
      endof
   endcase					( status )
;

external

defer query

headerless

: setup-query  ( -- )
   ['] do-query is query
;

0 value open-state

external

: open  ( -- okay? )
   open-state 0= if
      1 to open-state
      (asr-attach)
      svc-open
      setup-query
   then
   true
;

: close  ( -- )  ;

: update  ( key$ rsn$ src func -- status )
   >r >r				( key$ rsn$ )  ( r: func src ) 
   dup max-reason-buf-len > if
      2drop 2drop r> r> 2drop
      asr-reason-too-big exit 
   then
   2over nip 0= if
      2drop 2drop r> r> 2drop
      asr-unknown-key exit
   then
   r> r>				( key$ rsn$ src func )

   case					( key$ rsn$ src )
       1 of nip nip (enable) endof	( status )
      -1 of (disable) endof		( status )
   endcase
;

headerless
