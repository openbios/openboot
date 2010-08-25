\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hypervisor.fth
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
id: @(#)hypervisor.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
: hypercall: ( #out #in func# trap# -- )
	\ ( [ argn .. arg0 ] -- [ ret1 ret0 ] error? )
   2>r 2>r  code  2r@			( out in ) ( r: func# trap# out in )

   2dup +  if
      [ also assembler ]
      tos sp push		( out in ) ( r: func# trap# out in )
      [ previous ]
   then				( out in ) ( r: func# trap# out in )
   [ also assembler ]
   0 ?do			( out )    ( r: func# trap# out in )
      sp i /n* %o0 i + nget	( out )    ( r: func# trap# out in )
   loop				( out )    ( r: func# trap# out in )

   drop 2r> 2r>			( out in func# trap# )
   swap  %g0 swap %o5 add	( out in trap# )
   %g0 swap always htrapif	( out in )
   2dup over - 			( out in out in-out )
   [ also forth ]  ?dup  if [ previous ]	( out in out in-out )
      [ also forth ] dup 0< if [ previous ]	( out in out in-out )
           sp swap negate /n* sp sub	( out in out )
      [ also forth ] else [ previous ]	( out in out )
           sp swap /n* sp add		( out in out )
      [ also forth ]
      then				( out in out )
   then					( out in out )
   [ previous previous ]
   0 ?do				( out in )
      [ also assembler ]
      %o0 i +  sp  i /n*  nput		( out in )
      [ previous ]
   loop					( out in )
   +  if				(  )
      [ also assembler ]
      sp tos pop			(  )
      [ previous ]
   then					(  )
   [ also assembler  previous ]
   c;					(  )
;

