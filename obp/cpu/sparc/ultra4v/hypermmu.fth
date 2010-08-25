\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hypermmu.fth
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
id: @(#)hypermmu.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ htrap numbers
h# 00 constant fast-trap#
h# 03 constant map-addr-htrap#
h# 04 constant unmap-addr-htrap#

\ htrap function numbers
h# 27 constant mmu-on-off-func#
h# 25 constant map-perm-addr-func#
h# 28 constant unmap-perm-addr-func#
h# 26 constant mmu-miss-area-func#
h# 22 constant demap-page-func#

h# 80 constant /mmu-miss-area

headers
1 4 map-perm-addr-func#  fast-trap#
   hypercall: map-perm-addr ( tlb tte ctx vadr -- error? )

1 3 unmap-perm-addr-func#  fast-trap#
   hypercall: unmap-perm-addr ( tlb ctx vadr -- error? )

1 3 0 unmap-addr-htrap#
   hypercall: demap-page ( tlb ctx vadr -- error? )

1 4 0 map-addr-htrap#
   hypercall: map-addr ( tlb tte ctx vadr -- error? )

\ 
\ we had better not take a miss in this code..
\ 
code set-cpu-miss-area ( pa -- )
   tos				%o0     move
   sp				tos	pop
   %g0  h# 30			%o1	add
   %g0  mmu-miss-area-func#	%o5	add
   %o0  %g0  %o1  h# 20			stxa		\ Set scratch
   %g0  0				always htrapif
c;
