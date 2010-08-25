\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: makecent9.fth
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
id: @(#)makecent9.fth 1.1 94/11/08
copyright: Copyright 1991-1994 Sun Microsystems, Inc.  All Rights Reserved

\ Processor-dependent code to create entry points to allow C code to call
\ Forth words.
\
\ make-c-entry  ( #args #returns acf -- entry-code-adr )
\
\	Creates an interface routine to allow the Forth word whose
\	compilation address is "acf" to be called from C.  #args is
\	the number of stack arguments expected by the Forth word,
\	and #results is the number of results returned on the stack.
\
\	#returns must be either 0 or 1, since C functions have at most 1
\	return value.

decimal

headerless
: make-c-entry  ( #args #returns acf -- c-entry-code-adr )
   align
   here >r              ( #args #returns acf )

   [ also assembler ]

   %o6 /entry-frame  %o6  save  \ Allocate space for locals, globals, stacks

   forth-entry call
   nop

   [ previous ]         ( #args #returns acf )

   token,               ( #args #returns )
   2drop                ( )
   compile return-to-c
   r>
;
: $c-entry  ( #args #results forth-acf C-name$ -- )
   2>r make-c-entry  origin-  2r>  ( entry-adr C-name$ )
   external-procedure $add-symbol
;
: $double-return-c-entry  ( #args #results forth-acf C-name$ -- )
   $c-entry
   ['] double-return-to-c here /token - token!
;
headers

