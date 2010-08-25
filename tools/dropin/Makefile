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
# id: @(#)Makefile 1.2 04/08/17
# copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.
#

ROOT            = ../..
INSTALLDIR      = ${ROOT}/lib
TARGET          = libdropin.a
TARGETDIR       = ${INSTALLDIR}/
DROPIN		= ${ROOT}/tools/dropin

LIBRARY_sparc	=	$(ROOT)/lib/libdropin.a
LIBRARY_sparcv9	=	$(ROOT)/lib/sparcv9/libdropin.a

CFILES =        finddropin.c 

include ${ROOT}/default.mk

MKDIR		= mkdir -p

CC32		= ${SPRO_PATH}/cc
LD32		= /usr/ccs/bin/ld
CFLAGS32	= -v

CC64		= ${SPRO_PATH}/cc
LD64		= /usr/ccs/bin/ld
CFLAGS64	= -xarch=v9

INC		= -I ${ROOT}/include
CFLAGS          = -g ${INC}


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

${ROOT}/include/sys:
	${MKDIR} ${ROOT}/include/sys

${ROOT}/include/sys/dropins.h: ${ROOT}/include/sys
${ROOT}/include/sys/dropins.h: ${DROPIN}/include/sys/dropins.h
	cp -f ${DROPIN}/include/sys/dropins.h ${ROOT}/include/sys/dropins.h

${ROOT}/include/sys/dilib.h: ${ROOT}/include/sys ${DROPIN}/include/sys/dilib.h
	cp -f ${DROPIN}/include/sys/dilib.h ${ROOT}/include/sys/dilib.h

sparc:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9/%.o: %.c
	$(CC64) $(CFLAGS64) $(CFLAGS) -c $< -o $@

sparc/%.o: %.c
	$(CC32) $(CFLAGS32) $(CFLAGS) -c $< -o $@

LDFLAGS         += -r -z nodlopen

COMPOBJS        = comp.o decomp.o
COMPOBJS_sparcv9    = $(COMPOBJS:%=sparcv9/%)
COMPOBJS_sparc      = $(COMPOBJS:%=sparc/%)
OBJS               += $(COMPOBJS_sparc) $(COMPOBJS_sparcv9)

COMPFLAGS       = ${CFLAGS} -DNOMAIN -DSTANDALONE -Dcomp=di_comp
DECOMPFLAGS     = ${CFLAGS} -DNOMAIN -DSTANDALONE -DDROPIN_LIB \
		-Ddecomp=di_decomp

HDRS            = ${ROOT}/include/sys/dilib.h ${ROOT}/include/sys/dropins.h

${OBJS}: ${HDRS}
all::		${OBJS}
# ${TARGETDIR}${TARGET}:	$(COMPOBJS_sparc)
# ${TARGETDIR}sparcv9/${TARGET}:	$(COMPOBJS_sparv9)

sparcv9/comp.o:		${ROOT}/tools/comp.c
	${CC64} -c $(CFLAGS64) ${COMPFLAGS} -o $@ ${ROOT}/tools/comp.c

sparc/comp.o:		${ROOT}/tools/comp.c
	${CC32} -c $(CFLAGS32) ${COMPFLAGS} -o $@ ${ROOT}/tools/comp.c

sparcv9/decomp.o:	${ROOT}/tools/decomp.c
	${CC64} -c $(CFLAGS64) ${DECOMPFLAGS} -o $@ ${ROOT}/tools/decomp.c

sparc/decomp.o:		${ROOT}/tools/decomp.c
	${CC32} -c $(CFLAGS32) ${DECOMPFLAGS} -o $@ ${ROOT}/tools/decomp.c

${TARGETDIR}sparcv9:
	${MKDIR} ${TARGETDIR}sparcv9

${TARGETDIR}sparcv9/${TARGET}:	$(OBJS_sparcv9) ${COMPOBJS_sparcv9} \
	${TARGETDIR}sparcv9
	$(LD64) -o $@ $(OBJS_sparcv9) ${COMPOBJS_sparcv9} ${LDFLAGS}

${TARGETDIR}${TARGET}:	$(OBJS_sparc) ${COMPOBJS_sparc}
	$(LD32) -o $@ $(OBJS_sparc) $(COMPOBJS_sparc) ${LDFLAGS}

clean:
	${RM}  ${OBJS} ${LIBRARY_sparc} ${LIBRARY_sparcv9} ${HDRS}

clobber:
	${SCCS} clean

FORCE:
