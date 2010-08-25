\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hfcodes.fth
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
id: @(#)hfcodes.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

code (htrap) ( arg0 ... arg4 fn trap# -- ret0 status )
   6 0 do			\ 5 args and one function number on stack
      sp %o5 i - pop		\ load them into the o's
   loop
   %g0 tos always trapif	\ trap# is located in 'tos'
   %o2 sp push			\ return value 1
   %o1 sp push			\ return value 0
   %o0 tos move			\ put 'status' on top of stack
c;

headers

: htrap ( ??? #in #out fun# trap# -- ??? status )
   rot >r 2>r			( ??? #in )( R: #out trap# fun# )
   5 swap - 0 ?do 0 loop	( arg0 ... arg4 )( R: #out trap# fun# )
   2r> (htrap) r>		( ret1 ret0 status #out )
   dup 3 <> if			( ret1 ret0 status #out )
      2 = if			( ret1 ret0 status )
         rot drop		( ret0 status )
      else			( ret1 ret0 status )
         -rot 2drop		( status )
      then			( ??? status )
   else				( ret1 ret0 status #out )
      drop			( ret1 ret0 status )
   then				( ??? status )
;

headerless
