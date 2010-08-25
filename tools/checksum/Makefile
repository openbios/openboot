# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: Makefile
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
# Makefile 1.3 04/08/17
# copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.
#

ROOT            = ../..
INSTALLDIR      = ${ROOT}/lib
TARGET          = libchksum.a
TARGETDIR       = ${INSTALLDIR}/

LIBRARY_sparc	=	$(ROOT)/lib/libchksum.a
LIBRARY_sparcv9	=	$(ROOT)/lib/sparcv9/libchksum.a

CFILES =        checksum.c crc32.c

include ${ROOT}/default.mk

MKDIR		= mkdir -p

CC32		= ${SPRO_PATH}/cc
LD32		= /usr/ccs/bin/ld
CFLAGS32	= -v

CC64		= ${SPRO_PATH}/cc
LD64		= /usr/ccs/bin/ld
CFLAGS64	= -xarch=v9

LDFLAGS         += -r -z nodlopen

CFLAGS          = -g

COBJS 		= $(CFILES:%.c=%.o)
OBJS_sparcv9 	= $(COBJS:%=sparcv9/%)
OBJS_sparc 	= $(COBJS:%=sparc/%)
OBJS		= $(OBJS_sparc) $(OBJS_sparcv9)
TARGET32:sh	= echo "sparc \${TARGETDIR}\${TARGET} "
TARGET64:sh	= if [ -x /usr/bin/isalist ]; \
		then if [ ! -z "`/usr/bin/isalist | grep v9`" ]; \
		then echo "sparcv9 \${TARGETDIR}sparcv9/\${TARGET}"; fi; fi;
TARGETS		= ${TARGET32} ${TARGET64}

all:: ${TARGETS}

sparc:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9/%.o: %.c
	$(CC64) $(CFLAGS64) $(CFLAGS) -c $< -o $@

sparc/%.o: %.c
	$(CC32) $(CFLAGS32) $(CFLAGS) -c $< -o $@

${TARGETDIR}sparcv9:
	${MKDIR} ${TARGETDIR}sparcv9

${TARGETDIR}sparcv9/${TARGET}:	$(OBJS_sparcv9) ${TARGETDIR}sparcv9
	$(LD64) -o $@ $(OBJS_sparcv9) ${LDFLAGS}

${TARGETDIR}${TARGET}:	$(OBJS_sparc)
	$(LD32) -o $@ $(OBJS_sparc) ${LDFLAGS}

clean:
	${RM}  ${OBJS} ${LIBRARY_sparc} ${LIBRARY_sparcv9}

clobber:
	${SCCS} clean

FORCE:
