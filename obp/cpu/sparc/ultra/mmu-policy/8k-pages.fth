\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: 8k-pages.fth
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
id: @(#)8k-pages.fth 1.1 03/06/04
purpose: 
copyright: Copyright 2003 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headers

\ NOTE:
\ The final 2drop is patched at RUNTIME by enable-map-flushing
\ this code is in a performance path which is why it is not
\ using a variable/value/defer to switch this feature on/off.
: map-pages ( pa.lo pa.hi virtual size -- )
   pagesize >mmu-boundaries			( pa.lo pa.hi va' size' )
   2>r 2r@ (map-pages)				( )
   2r>						( va size )
   \ patched to flush-tlb-range
   2drop
;

: unmap-pages ( va len -- )
   pagesize >mmu-boundaries			( va' len' )
   2dup bounds ?do				( va' len' )
      i pgmap@ 0 >tte-valid invert and		( va' len' tte )
      i pgmap!					( va' len' )
   pagesize +loop				( va' len' )
   flush-tlb-range				( )
;

headerless
