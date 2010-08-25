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
# id: @(#)depend.mk 1.10 03/08/20
# purpose: 
# copyright: Copyright 1997-2003 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

include ${ROOT}/include/depend.mk

${TOOLS}/makeprom: ${TOOLDIR}/makeprom.c
${TOOLS}/makeprom: ${ROOT}/include/sys/dropins.h
${TOOLS}/makeprom: ${ROOT}/lib/libchksum.a
	@${RM} $@
	${CC} ${TOOLDIR}/makeprom.c -I ${ROOT}/include \
	-L${ROOT}/lib -lchksum -o ${TOOLS}/makeprom

${TOOLS}/makedi: ${TOOLDIR}/makedi.c
${TOOLS}/makedi: ${TOOLDIR}/comp.c
${TOOLS}/makedi: ${ROOT}/include/sys/dropins.h
${TOOLS}/makedi: ${ROOT}/lib/libchksum.a
	${CC} -DNOMAIN -I ${ROOT}/include \
	-L ${ROOT}/lib -lchksum -o ${TOOLS}/makedi \
	${TOOLDIR}/makedi.c ${TOOLDIR}/comp.c

${TOOLS}/comp: ${TOOLDIR}/comp.c
	@${RM} $@
	${CC} ${TOOLDIR}/comp.c -o ${TOOLS}/comp

${TOOLS}/elf2bin: ${TOOLDIR}/elf2bin.c
	${CC} ${TOOLDIR}/elf2bin.c -o ${TOOLS}/elf2bin -lelf

${TOOLS}/bin2srec: ${TOOLDIR}/bin2srec.c
	${CC} ${TOOLDIR}/bin2srec.c -o ${TOOLS}/bin2srec


${TOOLS}/didepend: ${ROOT}/lib/defines.h
${TOOLS}/didepend: ${TOOLDIR}/didepend.c ${ROOT}/lib/libdef.a
	${CC} $(CFLAGS) -I ${ROOT}/lib -o $@ ${TOOLDIR}/didepend.c \
		-L ${ROOT}/lib -ldef

${TOOLS}/bin2obj: ${TOOLDIR}/bin2obj.sh
	${CP} -f ${TOOLDIR}/bin2obj.sh ${TOOLS}/bin2obj
	chmod ugo+x ${TOOLS}/bin2obj

${TOOLS}/mkflash: ${TOOLDIR}/mkflash.sh
	${CP} -f ${TOOLDIR}/mkflash.sh ${TOOLS}/mkflash
	chmod ugo+x ${TOOLS}/mkflash

${TOOLS}/jbos_mkflash: ${TOOLDIR}/jbos_mkflash.sh
	${CP} -f ${TOOLDIR}/jbos_mkflash.sh ${TOOLS}/jbos_mkflash
	chmod ugo+x ${TOOLS}/jbos_mkflash

${TOOLS}/move-if-changed: ${TOOLDIR}/move-if-changed.sh
	${CP} -f ${TOOLDIR}/move-if-changed.sh ${TOOLS}/move-if-changed
	chmod ugo+x ${TOOLS}/move-if-changed

${TOOLS}/forth: ${ROOT}/obp/os/unix/sparc/forth
	${CP} -f ${ROOT}/obp/os/unix/sparc/forth ${TOOLS}/forth
	chmod ugo+x ${TOOLS}/forth

${TOOLS}/sparcv9/forth: ${TOOLS}/sparcv9 ${ROOT}/obp/os/unix/sparcv9/forth
	${CP} -f ${ROOT}/obp/os/unix/sparcv9/forth ${TOOLS}/sparcv9/forth
	chmod ugo+x ${TOOLS}/sparcv9/forth

${TOOLS}/tokenize.dic: ${ROOT}/obp/pkg/tokenizr/sparc/tokenize.dic
	${CP} -f ${ROOT}/obp/pkg/tokenizr/sparc/tokenize.dic ${TOOLS}/tokenize.dic

${TOOLS}/forth.dic: ${ROOT}/obp/os/sun/sparc/f32t32.dic
	${CP} -f ${ROOT}/obp/os/sun/sparc/f32t32.dic ${TOOLS}/forth.dic

