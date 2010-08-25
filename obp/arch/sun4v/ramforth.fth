\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ramforth.fth
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
id: @(#)ramforth.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
false value forth-in-ram?
: (romforth) ( -- )  ; immediate

: mem-base ( -- pa.lo pa.hi )
   hi-memory-base @  pageshift lshift ( base+ )
   8meg round-down  obmem             ( pa.lo pa.hi )
;
\ : mem-top ( -- pa.lo pa.hi )
\   hi-memory-base @  hi-memory-size @ +	( #pages )
\   pageshift lshift			( bytes )
\   8meg round-up  obmem			( pa.lo pa.hi )
\ ;

: RAMphys ( -- pa.lo pa.hi )
   mem-base >r  2meg + h# 1.0000 - r>
;

: ROMphys ( -- pa.lo pa.hi )  mem-base  ;

\
\ XXX need to flush-tlb after a demap perm??
\
: (flush-tlb-entry) ( va i&d? -- )
   swap >r if ['] flush-tlb-page 3 else ['] demap-dtlb 1 then 	( acf tlb )
   0 r@ unmap-perm-addr drop			( acf )
   r> swap execute				( )
;

\ After this step we have no locked DTLB entries.
: flush-temporary-mappings ( -- )
   0 true (flush-tlb-entry)
   RAMbase true (flush-tlb-entry)
   mem-base drop true (flush-tlb-entry)
   ROMbase 4meg round-down false (flush-tlb-entry)
;

struct
   /x	field	>mmu-miss-pa
constant /mmu-miss-info
/x (align) here /mmu-miss-info allot origin- constant mmu-info

headers
: (cacheforth)  ( -- )
   true to forth-in-ram?

   \ fixup the root-vpt-pa instructions
   RAMphys drop pagesize - setup-root-vpt

   rombase mmu-info + >r
   h# 2000 dup mem-claim drop dup r> >mmu-miss-pa x!	( pa )
   mid@ /mmu-miss-area * + set-cpu-miss-area		( )

   \ Create the VPT entries for RAMbase, RAMsize
   RAMphys RAMbase RAMsize-start map-pages

   \ Create the VPT entries for monvirtsize, 4M
   mem-base monvirtbase 4meg map-pages

   enable-map-flushing

   flush-temporary-mappings
;

: cacheforth ( -- )
   forth-in-ram?  if  exit  then
   (cacheforth)
;

headerless

stand-init: Copying ROM to RAM
   cacheforth
;

fload ${BP}/arch/sun/dynamic-user.fth	\ S

headers
