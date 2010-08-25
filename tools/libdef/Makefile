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
# id: @(#)Makefile 1.1 03/08/20
# purpose: 
# copyright: Copyright 2003 Sun Microsystems, Inc.  All Rights Reserved.
# copyright: Use is subject to license terms.

ROOT	= ../..
BP	= ${ROOT}/obp

include ${ROOT}/default.mk

CC64	= ${CC}
CC32	= ${CC}
DFLAGS	= -g
CFLAGS	= ${DFLAGS} ${LIBFLAGS} ${OFLAGS}
CFLAGS64 = -xarch=v9
CFLAGS32 = 
INCLUDES = -I .
MKDIR	= mkdir -p

CFILES	=	defines.c

HDRS	=	defines.h

TARGET = libdef.a

OBJS = $(CFILES:%.c=%.o)
OBJS_sparcv9 = $(OBJS:%=sparcv9/%)
OBJS_sparc = $(OBJS:%=sparc/%)

TARGETS:sh =	echo "sparc sparc/\${TARGET} "; if [ -x /usr/bin/isalist ]; \
		then if [ ! -z "`/usr/bin/isalist | grep v9`" ]; \
		then echo "sparcv9 sparcv9/\${TARGET}"; fi; fi;

INSTALL:sh =	echo "\${ROOT}/lib//\${TARGET} "; if [ -x /usr/bin/isalist ]; \
		then if [ ! -z "`/usr/bin/isalist | grep v9`" ]; \
		then echo "\${ROOT}/lib/sparcv9/\${TARGET}"; fi; fi;

all:	${TARGETS} ${INSTALL} ${ROOT}/lib/defines.h

${ROOT}/lib/sparcv9/${TARGET}: ${ROOT}/lib/sparcv9
	cp sparcv9/${TARGET} ${ROOT}/lib/sparcv9

${ROOT}/lib/${TARGET}: ${ROOT}/lib
	cp sparc/${TARGET} ${ROOT}/lib

${ROOT}/lib/defines.h:
	cp -f defines.h ${ROOT}/lib

${ROOT}/lib/sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparc:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

${CFILES}: ${HDRS}

sparcv9/%.o: %.c
	$(CC64) $(CFLAGS64) $(CFLAGS) -c $< -o $@

sparc/%.o: %.c
	$(CC32) $(CFLAGS32) $(CFLAGS) -c $< -o $@


sparcv9/${TARGET}: $(OBJS_sparcv9)
	$(AR) -r $@ $(OBJS_sparcv9) ${LDFLAGS}

sparc/${TARGET}: $(OBJS_sparc)
	$(AR) -r $@ $(OBJS_sparc) ${LDFLAGS}

clean:
	-@rm -f *% *.ln *.BAK $(OBJS_sparc) $(OBJS_sparcv9)
	-@rm -f sparc/${TARGET} sparcv9/${TARGET} 
	-@rm -f ${ROOT}/lib/sparcv9/${TARGET} ${ROOT}/lib/${TARGET}
