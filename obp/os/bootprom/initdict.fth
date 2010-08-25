\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: initdict.fth
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
id: @(#)initdict.fth 2.18 03/12/08 13:22:40
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ For use in virtual-memory systems in which the Forth dictionary does
\ not have memory preallocated to it, this file establishes a mechanism
\ for allocating physical memory to the dictionary "on demand".

headerless
\ Called when ALLOT can't satisfy the request.  Allocates some more
\ physical memory for the dictionary, maps it in, and updates limit
\ to include the new memory.
h# 1.0000 constant /dictionary-growth	\ 64K chosen to reduce map calls

\ Return a "success" indication if called when the dictionary already
\ satisfies the request.

\  Implementation factor.
\  Restriction:  both parameters must be  mmu-aligned
: extend-dict-phys ( old-top-adr size' -- )
   dup /dictionary-growth		( old-top size' size' alignment )
   mem-claim				( old-top size' p.lo p.hi )
   2swap				( p.lo p.hi old-top=start-addr size' )
   mem-mode mmu-map
;

: extend-dictionary  ( size -- size )
   dup  pad + d# 100 +                             ( size top-adr ) 
   /dictionary-growth round-up			   ( size new-top-adr ) 
   dup  dictionary-top  >  if  allot-abort  then   ( size new-top-adr )
   limit				( size new-top-adr old-top-adr )

   \  We didn't expect to call this routine unless we're about
   \  to run out of space, but it's more robust this way...
   2dup u<= if
      2drop exit		\  Retreat and claim victory.
   then
	 				( size new-top-adr old-top-adr )
   2dup -				( size new-top-adr old-top-adr size' )
   extend-dict-phys			( size new-top-adr )
   is limit
;

\  The  in-dictionary?  function is used to validate an
\  instruction-pointer or the occurrence of a token in a
\  colon-definition.  But if set to point to  origin  it
\  can get tripped up, for instance, when the trap-table
\  address was put on the return-stack and  ftrace  is run.
\
\  Instead, point it to the first code-definition in the
\  dictionary, which, after all, is the *real* start of
\  the area where valid IPs or tokens can begin.

: init-dictionary  ( -- )

   RAM-dictionary-base dp !
   initial-limit  is limit
   ['] extend-dictionary is allot-error

   ['] origin		 is lo-segment-base
   ['] origin		 is lo-segment-limit
   ['] first-code-word   is hi-segment-base
    \  XXX  Later, we may change  first-code-word  to low-dictionary-adr
   ['] here		 is hi-segment-limit
;

stand-init: Init Dictionary
   init-dictionary
;

headers
