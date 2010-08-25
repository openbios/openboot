\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 1.15 03/08/20
purpose: 
copyright: Copyright 1999-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

warning off
: headerless0 ;
fload ${BP}/fm/lib/filetool.fth
fload ${BP}/fm/lib/chains.fth
fload ${BP}/os/sun/nlist.fth
fload ${BP}/os/sun/elf.fth
fload ${BP}/os/sun/sparc/elf.fth
fload ${BP}/os/sun/elfsym.fth
fload ${BP}/os/sun/sparc/reloc.fth
fload ${BP}/fm/cwrapper/binhdr.fth
fload ${BP}/fm/cwrapper/sparc/savefort.fth
fload ${BP}/os/sun/saveelf.fth
fload ${BP}/os/bootprom/release.fth

[ifnexist] assembler
fload ${BP}/cpu/sparc/assem.fth
fload ${BP}/cpu/sparc/code.fth
fload ${BP}/cpu/sparc/asmmacro.fth
fload ${BP}/fm/lib/loclabel.fth
fload ${BP}/cpu/sparc/ultra/implasm.fth
[then]

fload ${BP}/arch/sun4u/asmmacros.fth
fload ${BP}/cpu/sparc/ultra3/asmmacro.fth
fload ${BP}/arch/sun/reset/common.fth
