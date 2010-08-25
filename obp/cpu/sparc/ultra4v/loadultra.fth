\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadultra.fth
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
id: @(#)loadultra.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

[ifndef] assembler?  transient  [then]
fload ${BP}/cpu/sparc/ultra/implasm.fth
fload ${BP}/cpu/sparc/ultra4v/implasm.fth
[ifndef] assembler?  resident  [then]

transient
also assembler definitions
fload ${BP}/cpu/sparc/ultra4v/asmmacro.fth
previous definitions
resident

headers

fload ${BP}/cpu/sparc/ultra4v/hypervisor.fth
fload ${BP}/cpu/sparc/ultra4v/hypermmu.fth

fload ${BP}/cpu/sparc/ultra/impldis.fth

fload ${BP}/cpu/sparc/ultra4v/map.fth
fload ${BP}/cpu/sparc/ultra4v/mmuregs.fth
fload ${BP}/cpu/sparc/ultra4v/tte.fth
fload ${BP}/cpu/sparc/ultra4v/tlb.fth

alias cache-off   noop immediate
alias cache-on    noop immediate
alias clear-cache noop immediate
alias flush-cache-page drop
fload ${BP}/cpu/sparc/ultra/mmu.fth
fload ${BP}/cpu/sparc/ultra4v/tte-lookup.fth

headerless

