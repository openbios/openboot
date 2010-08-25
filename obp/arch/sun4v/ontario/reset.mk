# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: reset.mk
# 
# Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
# 
#  - Do no alter or remove copyright notices
# 
#  - Redistribution and use of this software in source and binary forms, with 
#    or without modification, are permitted provided that the following 
#    conditions are met: 
# 
#  - Redistribution of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
# 
#  - Redistribution in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution. 
# 
#    Neither the name of Sun Microsystems, Inc. or the names of contributors 
# may be used to endorse or promote products derived from this software 
# without specific prior written permission. 
# 
#     This software is provided "AS IS," without a warranty of any kind. 
# ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
# INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
# MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
# ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
# DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
# OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
# FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
# DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
# ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
# SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
# 
# You acknowledge that this software is not designed, licensed or
# intended for use in the design, construction, operation or maintenance of
# any nuclear facility. 
# 
# ========== Copyright Header End ============================================
# id: @(#)reset.mk  1.1  06/02/16
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
# This is a machine generated file
# DO NOT EDIT IT BY HAND
reset.o: ${BP}/arch/preload.fth
reset.o: ${BP}/arch/sun/auto-field.fth
reset.o: ${BP}/arch/sun/reset-cleanup.fth
reset.o: ${BP}/arch/sun/reset-dropin.fth
reset.o: ${BP}/arch/sun/reset/common.fth
reset.o: ${BP}/arch/sun4s/reset/common.fth
reset.o: ${BP}/arch/sun4u/asmmacros.fth
reset.o: ${BP}/arch/sun4v/diagprint.fth
reset.o: ${BP}/arch/sun4v/error-reset.fth
reset.o: ${BP}/arch/sun4v/niagara/reset.fth
reset.o: ${BP}/arch/sun4v/niagara/tlbsetup.fth
reset.o: ${BP}/arch/sun4v/savestate.fth
reset.o: ${BP}/cpu/sparc/ultra3/asmmacro.fth
reset.o: ${BP}/cpu/sparc/ultra4v/tlbasm.fth
reset.o: ${BP}/fm/cwrapper/binhdr.fth
reset.o: ${BP}/fm/cwrapper/sparc/savefort.fth
reset.o: ${BP}/fm/lib/brackif.fth
reset.o: ${BP}/fm/lib/chains.fth
reset.o: ${BP}/fm/lib/copyrigh.fth
reset.o: ${BP}/fm/lib/filetool.fth
reset.o: ${BP}/fm/lib/headless.fth
reset.o: ${BP}/fm/lib/message.fth
reset.o: ${BP}/fm/lib/transien.fth
reset.o: ${BP}/os/bootprom/release.fth
reset.o: ${BP}/os/sun/elf.fth
reset.o: ${BP}/os/sun/elfsym.fth
reset.o: ${BP}/os/sun/nlist.fth
reset.o: ${BP}/os/sun/saveelf.fth
reset.o: ${BP}/os/sun/sparc/elf.fth
reset.o: ${BP}/os/sun/sparc/reloc.fth
reset.o: ${BP}/os/unix/simforth/findnext.fth
reset.o: ${BP}/pkg/dropins/sparc/find-dropin.fth
