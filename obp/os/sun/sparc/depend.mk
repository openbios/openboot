# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: depend.mk
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
# id: @(#)depend.mk  1.4  03/07/17
# purpose:  @(#)depend.mk 
# copyright 1985-1990 Bradley Forthware
# copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

FORTH-SOURCES = \
	${BP}/os/sun/sparc/loadutil.fth \
	${BP}/fm/lib/copyrigh.fth \
	${BP}/fm/lib/transien.fth \
	${BP}/fm/lib/headless.fth \
	${BP}/fm/lib/brackif.fth \
	${BP}/fm/kernel/sparc/loadsyms.fth \
	${BP}/fm/lib/stubs.fth \
	${BP}/fm/lib/filetool.fth \
	${BP}/fm/lib/dispose.fth \
	${BP}/fm/lib/showspac.fth \
	${BP}/fm/lib/chains.fth \
	${BP}/os/stand/romable.fth \
	${BP}/fm/lib/hidden.fth \
	${BP}/fm/lib/th.fth \
	${BP}/fm/lib/patch.fth \
	${BP}/fm/kernel/hashcach.fth \
	${BP}/fm/lib/strings.fth \
	${BP}/fm/lib/suspend.fth \
	${BP}/fm/lib/util.fth \
	${BP}/fm/lib/format.fth \
	${BP}/fm/lib/cirstack.fth \
	${BP}/fm/lib/pseudors.fth \
	${BP}/fm/lib/headtool.fth \
	${BP}/fm/lib/needs.fth \
	${BP}/fm/lib/stringar.fth \
	${BP}/fm/lib/split.fth \
	${BP}/fm/lib/dump.fth \
	${BP}/fm/lib/words.fth \
	${BP}/fm/lib/decomp.fth \
	${BP}/fm/lib/seechain.fth \
	${BP}/fm/lib/loadedit.fth \
	${BP}/fm/lib/fileed.fth \
	${BP}/fm/lib/editcmd.fth \
	${BP}/fm/lib/unixedit.fth \
	${BP}/fm/lib/cmdcpl.fth \
	${BP}/fm/lib/fcmdcpl.fth \
	${BP}/fm/lib/caller.fth \
	${BP}/fm/lib/callfind.fth \
	${BP}/fm/lib/substrin.fth \
	${BP}/fm/lib/sift.fth \
	${BP}/fm/lib/array.fth \
	${BP}/fm/lib/linklist.fth \
	${BP}/fm/lib/initsave.fth \
	${BP}/cpu/sparc/assem.fth \
	${BP}/cpu/sparc/code.fth \
	${BP}/cpu/sparc/asmmacro.fth \
	${BP}/fm/lib/loclabel.fth \
	${BP}/cpu/sparc/disforw.fth \
	${BP}/cpu/sparc/ultra/impldis.fth \
	${BP}/fm/lib/instdis.fth \
	${BP}/fm/lib/sparc/decompm.fth \
	${BP}/os/stand/sparc/notmeta.fth \
	${BP}/fm/lib/sparc/bitops.fth \
	${BP}/fm/cwrapper/binhdr.fth \
	${BP}/fm/cwrapper/sparc/savefort.fth \
	${BP}/cpu/sparc/doccall.fth \
	${BP}/fm/lib/sparc/debugm.fth \
	${BP}/fm/lib/debug.fth \
	${BP}/fm/lib/sparc/objsup.fth \
	${BP}/fm/lib/objects.fth \
	${BP}/cpu/sparc/cpustate.fth \
	${BP}/fm/lib/savedstk.fth \
	${BP}/fm/lib/rstrace.fth \
	${BP}/fm/lib/sparc/ftrace.fth \
	${BP}/fm/lib/sparc/cpubpsup.fth \
	${BP}/fm/lib/breakpt.fth \
	${BP}/cpu/sparc/call.fth \
	${BP}/os/sun/sparc/signal.fth \
	${BP}/os/sun/sparc/catchexc.fth \
	${BP}/os/unix/sparc/arcbpsup.fth \
	${BP}/fm/lib/version.fth

FORTH32-SOURCES	= \
	${FORTH-SOURCES} \
	${BP}/cpu/sparc/traps.fth \
	${BP}/cpu/sparc/register.fth \
	${BP}/fm/lib/sparc/ctrace.fth

FORTH64-SOURCES	= \
	${FORTH-SOURCES} \
	${BP}/cpu/sparc/traps9.fth \
	${BP}/cpu/sparc/register9.fth \
	${BP}/fm/lib/sparc/ctrace9.fth

# Start with the 32 bit forths
${BOOTSTRAPFORTH}.dic: ${BOOTSTRAPKERNEL}.dic ${BOOTSTRAPKERNEL}.fth
${BOOTSTRAPFORTH}.dic: ${BP}/os/sun/sparc/loadutil.fth
${BOOTSTRAPFORTH}.dic: ${FORTH} ${FORTH32-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH} ${VERBOSE} \
		-d ${BOOTSTRAPKERNEL}.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${BOOTSTRAPKERNEL}.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

${BOOTSTRAPFORTH}-xref.dic: ${BOOTSTRAPKERNEL}-xref.dic
${BOOTSTRAPFORTH}-xref.dic: ${BOOTSTRAPKERNEL}-xref.fth
${BOOTSTRAPFORTH}-xref.dic: ${BP}/os/sun/sparc/loadutil.fth
${BOOTSTRAPFORTH}-xref.dic: ${FORTH} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH} ${VERBOSE} \
		-d ${BOOTSTRAPKERNEL}-xref.dic -u ${FFLAGS} \
		-D dic-file-name=$@ -D XREF -x $@.xref \
		-D kernel-hdr-file=${BOOTSTRAPKERNEL}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

# now the rest
${F32T32}.dic: ${K32T32}-xref.dic ${K32T32}-xref.fth
${F32T32}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F32T32}.dic: ${FORTH} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH} ${VERBOSE} \
		-d ${K32T32}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K32T32}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

${F32T16S2}.dic: ${K32T16S2}-xref.dic ${K32T16S2}-xref.fth
${F32T16S2}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F32T16S2}.dic: ${FORTH} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH} ${VERBOSE} \
		-d ${K32T16S2}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K32T16S2}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)


${F32T16S4}.dic: ${K32T16S4}-xref.dic ${K32T16S4}-xref.fth
${F32T16S4}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F32T16S4}.dic: ${FORTH} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH} ${VERBOSE} \
		-d ${K32T16S4}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K32T16S4}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

# Now the 64bit ones
# These all have a dependancy upon the same 32bit kernel

${F64T32}.dic: ${K64T32}-xref.dic ${K64T32}-xref.fth
${F64T32}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F64T32}.dic: ${FORTH64} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH64} ${VERBOSE} \
		-d ${K64T32}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K64T32}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

${F64T16S2}.dic: ${K64T16S2}-xref.dic ${K64T16S2}-xref.fth
${F64T16S2}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F64T16S2}.dic: ${FORTH64} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH64} ${VERBOSE} \
		-d ${K64T16S2}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K64T16S2}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)


${F64T16S4}.dic: ${K64T16S4}-xref.dic ${K64T16S4}-xref.fth
${F64T16S4}.dic: ${BP}/os/sun/sparc/loadutil.fth
${F64T16S4}.dic: ${FORTH64} ${FORTH-SOURCES}
	@${NOTIFY} Creating $@
	( BP=${BP}; export BP; \
		${FORTH64} ${VERBOSE} \
		-d ${K64T16S4}-xref.dic -u ${FFLAGS} \
		-D XREF -D dic-file-name=$@ \
		-D kernel-hdr-file=${K64T16S4}-xref.fth \
		-s "${FTHFLAGS}" \
		${BP}/os/sun/sparc/loadutil.fth \
	)

clean::
	${RM} ${BOOTSTRAPFORTH}.dic
	${RM} ${F32T32}.dic
	${RM} ${F32T16S2}.dic
	${RM} ${F32T16S4}.dic
	${RM} ${F64T32}.dic
	${RM} ${F64T16S2}.dic
	${RM} ${F64T16S4}.dic
