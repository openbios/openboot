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
# id: @(#)depend.mk 1.8 06/02/16
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.
#
# .fth files used in all kernels.

KCOMPILER	= ${COMPILER} ${VERBOSE} ${FFLAGS} 

KERNEL-SOURCES = \
	${BP}/fm/meta/meta1.fth \
	${BP}/cpu/sparc/assem.fth \
	${BP}/fm/lib/loclabel.fth \
	${BP}/fm/lib/message.fth \
	${BP}/fm/meta/nswapmap.fth \
	${BP}/fm/meta/sparc/target.fth \
	${BP}/fm/meta/forward.fth \
	${BP}/fm/meta/sparc/fixvoc.fth \
	${BP}/fm/meta/compilin.fth \
	${BP}/fm/kernel/sparc/metainit.fth \
	${BP}/fm/kernel/sparc/kerncode.fth \
	${BP}/fm/kernel/sparc/divrem.fth \
	${BP}/fm/kernel/uservars.fth \
	${BP}/fm/kernel/sparc/multiply.fth \
	${BP}/fm/kernel/sparc/move.fth \
	${BP}/fm/kernel/sparc/extra.fth \
	${BP}/fm/kernel/double.fth \
	${BP}/fm/kernel/dmuldiv.fth \
	${BP}/fm/kernel/dmul.fth \
	${BP}/fm/kernel/io.fth \
	${BP}/fm/kernel/stresc.fth \
	${BP}/fm/kernel/comment.fth \
	${BP}/fm/kernel/catchsel.fth \
	${BP}/fm/kernel/sparc/checkpt.fth \
	${BP}/fm/kernel/kernel2.fth \
	${BP}/fm/kernel/compiler.fth \
	${BP}/fm/kernel/interp.fth \
	${BP}/fm/kernel/kernport.fth \
	${BP}/fm/kernel/definers.fth \
	${BP}/fm/kernel/tagvoc.fth \
	${BP}/fm/kernel/voccom.fth \
	${BP}/fm/kernel/order.fth \
	${BP}/fm/kernel/is.fth \
	${BP}/fm/kernel/sparc/field.fth \
	${BP}/fm/kernel/sparc/filecode.fth \
	${BP}/fm/kernel/filecomm.fth \
	${BP}/fm/kernel/cold.fth \
	${BP}/fm/kernel/disk.fth \
	${BP}/fm/kernel/readline.fth \
	${BP}/fm/kernel/fileio.fth \
	${BP}/fm/lib/cstrings.fth \
	${BP}/fm/cwrapper/sysdisk.fth \
	${BP}/fm/cwrapper/syskey.fth \
	${BP}/os/unix/sparc/sys.fth \
	${BP}/fm/lib/alias.fth \
	${BP}/fm/kernel/cmdline.fth \
	${BP}/fm/kernel/nswapmap.fth \
	${BP}/fm/kernel/ansio.fth \
	${BP}/fm/cwrapper/sparc/boot.fth \
	${BP}/fm/kernel/init.fth \
	${BP}/fm/kernel/sparc/finish.fth \
	${BP}/fm/kernel/sparc/double.fth \
	${BP}/fm/kernel/guarded.fth \
	${BP}/fm/kernel/sparc/moveslow.fth \
	${BP}/fm/kernel/sparc/parseline.fth \
	${BP}/fm/meta/sparc/savemeta.fth

KERNEL-COMMON	= \
	${KERNEL-SOURCES} \
	${FORTH} \
	${BP}/os/sun/sparc/forth.dic \
	${BP}/fm/kernel/${CPU}/loadkern.fth

KERNEL64-SRC	= \
	${BP}/fm/kernel/sparc/mulv9.fth \
	${BP}/fm/kernel/sparc/divrem9.fth

KERNELMODEL = /usr/bin/basename $@ | sed -e 'sX\..*XX'

# same as k32t32.dic
# used to bootstrap all the other kernels
${BOOTSTRAPKERNEL}.dic: ${KERNEL-COMMON} ${BP}/os/sun/sparc/forth.dic
${BOOTSTRAPKERNEL}.dic: ${BP}/fm/meta/conft32.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${FORTH} ${VERBOSE} \
	  -d ${BP}/os/sun/sparc/forth.dic \
	  ${XFFLAGS} -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  ${BP}/fm/meta/conft32.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${BOOTSTRAPKERNEL}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${BOOTSTRAPKERNEL}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${BOOTSTRAPKERNEL}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${BOOTSTRAPKERNEL}-xref.dic: ${KERNEL-COMMON} ${BP}/os/sun/sparc/forth.dic
${BOOTSTRAPKERNEL}-xref.dic: ${BP}/fm/meta/conft32.fth
${BOOTSTRAPKERNEL}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${FORTH} ${VERBOSE}  \
	  -d ${BP}/os/sun/sparc/forth.dic \
	  ${XFFLAGS} -F -D dic-file-name=$@ -D KERNEL -D XREF -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  ${BP}/fm/meta/conft32.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${BOOTSTRAPKERNEL}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${BOOTSTRAPKERNEL}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${BOOTSTRAPKERNEL}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

# Now all the 32bit targets starting with kernels

${K32T32}.dic: ${KERNEL-COMMON} ${BOOTSTRAPFORTH}.dic
${K32T32}.dic: ${BP}/fm/meta/conft32.fth
${K32T32}.dic: ${BP}/cpu/sparc/ultra/impldis.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${FORTH} ${VERBOSE} -d ${BOOTSTRAPFORTH}.dic \
	   -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  ${BP}/fm/meta/conft32.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T32}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T32}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T32}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic


#  NOTE:  The  {K32T32}-xref  model created here, or the identical
#  {F32T32}-xref.dic created in os/sun/sparc, may be used to replace
#  the saved  forth.dic  forth-engine that starts creation of the new
#  kernels and forth-engines.  *DO NOT USE THE NON-xref VERSION*
#
#  And when you do, be sure to replace the saved   os/sun/sparc/headless.fth 
#  with the  {K32T32}-xref.headless.fth  created here; it supplies the 
#  restored-heads data for the forth-engine to which it corresponds,
#  and is highly version-sensitive.  *DO NOT LET THEM GET OUT OF SYNC*
#
${K32T32}-xref.dic: ${KERNEL-COMMON} ${BOOTSTRAPFORTH}-xref.dic
${K32T32}-xref.dic: ${BP}/fm/meta/conft32.fth
${K32T32}-xref.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K32T32}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${FORTH} ${VERBOSE} \
	   -d ${BOOTSTRAPFORTH}-xref.dic \
	   -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  ${BP}/fm/meta/conft32.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T32}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T32}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T32}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K32T16S2}.dic: ${KERNEL-COMMON} ${FORTHDIC}
${K32T16S2}.dic: ${BP}/fm/meta/conft16.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s '2 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conft16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T16S2}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T16S2}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T16S2}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K32T16S2}-xref.dic: ${KERNEL-COMMON} ${FORTHDIC}
${K32T16S2}-xref.dic: ${BP}/fm/meta/conft16.fth
${K32T16S2}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s '2 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conft16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T16S2}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T16S2}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T16S2}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K32T16S4}.dic: ${KERNEL-COMMON}  ${FORTHDIC}
${K32T16S4}.dic: ${BP}/fm/meta/conft16.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 4 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conft16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T16S4}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T16S4}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T16S4}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K32T16S4}-xref.dic: ${KERNEL-COMMON}  ${FORTHDIC}
${K32T16S4}-xref.dic: ${BP}/fm/meta/conft16.fth
${K32T16S4}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 4 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conft16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K32T16S4}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K32T16S4}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K32T16S4}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

# Now the 64 bit targets starting with kernels.
${K64T32}.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T32}.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64T32}.dic: ${BP}/fm/meta/conf64.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T32}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T32}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T32}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64T32}-xref.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T32}-xref.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64T32}-xref.dic: ${BP}/fm/meta/conf64.fth
${K64T32}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T32}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T32}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T32}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

# Now the 64 bit miniforth
${K64MINI}.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64MINI}.dic: ${BP}/fm/kernel/${CPU}/loadkern.fth
${K64MINI}.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64MINI}.dic: ${BP}/fm/meta/conf64.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D "miniforth?" -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64MINI}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64MINI}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64MINI}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64MINI}-xref.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64MINI}-xref.dic: ${BP}/fm/kernel/${CPU}/loadkern.fth
${K64MINI}-xref.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64MINI}-xref.dic: ${BP}/fm/meta/conf64.fth
${K64MINI}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D "miniforth?" -D dic-file-name=$@ -D KERNEL -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64MINI}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64MINI}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64MINI}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

# Now the 64 bit miniforth
${K64MINI}-t16.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64MINI}-t16.dic: ${BP}/fm/kernel/${CPU}/loadkern.fth
${K64MINI}-t16.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64MINI}-t16.dic: ${BP}/fm/meta/conf64t16.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D "miniforth?" -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64MINI}-t16.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64MINI}-t16.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64MINI}-t16.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64MINI}-t16-xref.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64MINI}-t16-xref.dic: ${BP}/fm/kernel/${CPU}/loadkern.fth
${K64MINI}-t16-xref.dic: ${BP}/cpu/sparc/ultra/impldis.fth
${K64MINI}-t16-xref.dic: ${BP}/fm/meta/conf64t16.fth
${K64MINI}-t16-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D "miniforth?" -D dic-file-name=$@ -D KERNEL -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64MINI}-t16-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64MINI}-t16-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64MINI}-t16-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64T16S2}.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T16S2}.dic: ${BP}/fm/lib/sparc/debugm16.fth
${K64T16S2}.dic: ${BP}/fm/meta/conf64t16.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 2 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T16S2}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T16S2}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T16S2}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64T16S2}-xref.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T16S2}-xref.dic: ${BP}/fm/lib/sparc/debugm16.fth
${K64T16S2}-xref.dic: ${BP}/fm/meta/conf64t16.fth
${K64T16S2}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 2 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T16S2}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T16S2}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T16S2}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64T16S4}.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T16S4}.dic: ${BP}/fm/meta/conf64t16.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 4 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T16S4}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T16S4}.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T16S4}.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${K64T16S4}-xref.dic: ${KERNEL-COMMON} ${FORTHDIC} ${KERNEL64-SRC}
${K64T16S4}-xref.dic: ${BP}/fm/meta/conf64t16.fth
${K64T16S4}-xref.dic: ${BP}/fm/lib/xref.fth
	@${NOTIFY} Creating $@
	${RM} $@
	${RM} nheads.${KERNELMODEL:sh}.dic
	(BP=${BP} ; export BP ; ${KCOMPILER} \
	  -D dic-file-name=$@ -D KERNEL  -D XREF -F -x $@.idx \
	  -D nheads-dic-name=nheads.${KERNELMODEL:sh}.dic \
	  -s ' 4 constant tshift-t' \
	  -s "${FTHFLAGS}" \
	  ${BP}/fm/meta/conf64t16.fth ${BP}/fm/kernel/${CPU}/loadkern.fth)
	@${RM} ${K64T16S4}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheads" | \
		${SORT} +1 > ${K64T16S4}-xref.fth
	${FORTH} -d nheads.${KERNELMODEL:sh}.dic -s " nheadless" | \
		${SORT} +1 > ${K64T16S4}-xref.headless.fth
	${RM} nheads.${KERNELMODEL:sh}.dic

${BOOTSTRAPKERNEL}.fth: ${BOOTSTRAPKERNEL}.dic
${K32T32}.fth: ${K32T32}.dic
${K32T16S2}.fth: ${K32T16S2}.dic
${K32T16S4}.fth: ${K32T16S4}.dic
${K64T32}.fth: ${K64T32}.dic
${K64T16S2}.fth: ${K64T16S2}.dic
${K64T16S4}.fth: ${K64T16S4}.dic

# Now the xref versions
${BOOTSTRAPKERNEL}-xref.fth: ${BOOTSTRAPKERNEL}-xref.dic
${K32T32}-xref.fth: ${K32T32}-xref.dic
${K32T16S2}-xref.fth: ${K32T16S2}-xref.dic
${K32T16S4}-xref.fth: ${K32T16S4}-xref.dic
${K64T32}-xref.fth: ${K64T32}-xref.dic
${K64T16S2}-xref.fth: ${K64T16S2}-xref.dic
${K64T16S4}.fth: ${K64T16S4}-xref.dic

clean::
	${RM} ${BOOTSTRAPKERNEL}.dic ${BOOTSTRAPKERNEL}.fth
	${RM} ${BOOTSTRAPFORTH}.dic ${BOOTSTRAPFORTH}.fth
	${RM} ${K32T16S2}.dic ${K32T16S2}.fth
	${RM} ${K32T16S4}.dic ${K32T16S4}.fth
	${RM} ${K32T32}.dic ${K32T32}.fth
	${RM} ${K64T32}.dic ${K64T32}.fth
	${RM} ${K64MINI}.dic ${K64MINI}.fth
	${RM} ${K64T16S2}.dic ${K64T16S2}.fth
	${RM} ${K64T16S4}.dic ${K64T16S4}.fth
	${RM} ${BOOTSTRAPKERNEL}-xref.dic ${BOOTSTRAPKERNEL}-xref.fth
	${RM} ${BOOTSTRAPFORTH}-xref.dic ${BOOTSTRAPFORTH}-xref.fth
	${RM} ${K32T32}-xref.dic ${K32T32}-xref.fth
	${RM} ${K32T16S2}-xref.dic ${K32T16S2}-xref.fth
	${RM} ${K32T16S4}-xref.dic ${K32T16S4}-xref.fth
	${RM} ${K64T32}-xref.dic ${K64T32}-xref.fth
	${RM} ${K64MINI}-xref.dic ${K64MINI}-xref.fth
	${RM} ${K64T16S2}-xref.dic ${K64T16S2}-xref.fth
	${RM} ${K64T16S4}-xref.dic ${K64T16S4}-xref.fth
	${RM} ${BOOTSTRAPKERNEL}-xref.dic.idx
	${RM} ${BOOTSTRAPFORTH}-xref.dic.idx
	${RM} ${K32T32}-xref.dic.idx
	${RM} ${K32T16S2}-xref.dic.idx
	${RM} ${K32T16S4}-xref.dic.idx
	${RM} ${K64T32}-xref.dic.idx
	${RM} ${K64MINI}-xref.dic.idx
	${RM} ${K64T16S2}-xref.dic.idx
	${RM} ${K64T16S4}-xref.dic.idx
	${RM} ${BOOTSTRAPKERNEL}.headless.fth
	${RM} ${BOOTSTRAPKERNEL}-xref.headless.fth
	${RM} ${K32T32}.headless.fth
	${RM} ${K32T32}-xref.headless.fth
	${RM} ${K32T16S2}.headless.fth
	${RM} ${K32T16S2}-xref.headless.fth
	${RM} ${K32T16S4}.headless.fth
	${RM} ${K32T16S4}-xref.headless.fth
	${RM} ${K64T32}.headless.fth
	${RM} ${K64T32}-xref.headless.fth
	${RM} ${K64MINI}.headless.fth
	${RM} ${K64MINI}-xref.headless.fth
	${RM} ${K64MINI}-t16.headless.fth
	${RM} ${K64MINI}-t16-xref.headless.fth
	${RM} ${K64T16S2}.headless.fth
	${RM} ${K64T16S2}-xref.headless.fth
	${RM} ${K64T16S4}.headless.fth
	${RM} ${K64T16S4}-xref.headless.fth
