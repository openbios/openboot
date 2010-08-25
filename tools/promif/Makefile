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
# purpose:
# copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

ROOT		=	../..

include	${ROOT}/default.mk

INSTALLDIR      =	${ROOT}/lib
TARGET          =	libsa.a
TARGETDIR       =	${INSTALLDIR}/
PROMIF		=	${ROOT}/tools/promif

CC32    	=	${CC5}
CFLAGS32	=	

CC64    	=	${CC5}
CFLAGS64	=	-xarch=v9

ASFLAGS32      	= 	-I/usr/include -I/usr/include/v9

ASFLAGS64      	= 	-D__sparcv9 -I/usr/include/v9

CCSBIN		=	/usr/ccs/bin	
AR		=	${CCSBIN}/ar
ARFLAGS		=	cr
LORDER		=	${CCSBIN}/lorder
TSORT		=	${CCSBIN}/tsort

INCS		=	-I${PROMIF}/include -I${PROMIF}/include/sun4u \
			-I${PROMIF}/include/v9 -I/usr/include

CFLAGS		= 	${INCS}

LIBRARY_sparc	=	$(TARGETDIR)libsa.a
LIBRARY_sparcv9	=	$(TARGETDIR)sparcv9/libsa.a

.KEEP_STATE:
.PARALLEL:
.SILENT:

MKDIR   = 	mkdir -p

SFILES	=	crt0.s

CFILES	=	common/prom_2path.c		\
		common/prom_boot.c		\
		common/prom_console.c		\
		common/prom_enter.c		\
		common/prom_exit.c		\
		common/prom_findnode.c		\
		common/prom_gettime.c		\
		common/prom_handler.c		\
		common/prom_interp.c		\
		common/prom_io.c		\
		common/prom_node.c		\
		common/prom_panic.c		\
		common/prom_path.c		\
		common/prom_phandle.c		\
		common/prom_printf.c		\
		common/prom_prop.c		\
		common/prom_propnames.c		\
		common/prom_reboot.c		\
		common/prom_string.c		\
		common/prom_sysnodes.c		\
		common/prom_test.c		\
		sun4u/prom_alloc.c		\
		sun4u/prom_cpuctl.c		\
		sun4u/prom_heartbeat.c		\
		sun4u/prom_init.c		\
		sun4u/prom_mem.c		\
		sun4u/prom_mmu.c		\
		sun4u/prom_power_off.c		\
		sun4u/prom_retain.c		\
		sun4u/prom_set_traptable.c	\
		sun4u/prom_sparc.c		\
		common/prom_file.c		\
		common/prom_mapin.c		\
		common/prom_ioctl.c		\
		prom_glue.c			\
		memz.c

HDRS =		include/sys/obpdefs.h		\
		include/sys/promif.h		\
		include/sys/promimpl.h		\
		include/sun4u/sys/prom_plat.h	\
		include/v9/sys/prom_isa.h

OBJS = $(CFILES:%.c=%.o) $(SFILES:%.s=%.o)

OBJS_sparcv9 = $(OBJS:%=sparcv9/%)

OBJS_sparc = $(OBJS:%=sparc/%)

TARGETS:sh	= echo "sparc \${TARGETDIR}\${TARGET} " ; \
		if [ -x /usr/bin/isalist ]; \
		then if [ ! -z "`/usr/bin/isalist | grep v9`" ]; \
		then echo "sparcv9 \${TARGETDIR}sparcv9/\${TARGET}"; fi; fi;

OBPDEFS		= ${ROOT}/include/sys/obpdefs.h

all:	sparcv9 ${TARGETDIR}sparcv9 ${LIBRARY_sparcv9} ${OBPDEFS}

${ROOT}/include/sys:
	${MKDIR} ${ROOT}/include/sys

${ROOT}/include/sys/obpdefs.h: ${PROMIF}/include/sys/obpdefs.h
${ROOT}/include/sys/obpdefs.h: ${ROOT}/include/sys
	cp -f ${PROMIF}/include/sys/obpdefs.h ${ROOT}/include/sys

# Not building 32-bit promif library because crt0.s
# file doesn't support it yet
# all:	${TARGETS}

sparc:
	if [ ! -x $@ ]; then ${MKDIR} $@; ${MKDIR} $@/common; \
	${MKDIR} $@/sun4u ; fi

sparc/%.o:	%.c
	$(CC32) $(CFLAGS32) $(CFLAGS) -c $< -o $@

sparc/%.o:	%.s
	$(AS) $(ASFLAGS32) -P -D_ASM -xarch=v8plus $< -o $@

AROBJS_sparc	=	`${LORDER} ${OBJS_sparc} | ${TSORT}`

${LIBRARY_sparc}:	${OBJS_sparc}
	${AR} ${ARFLAGS} $@ ${AROBJS_sparc} 

${TARGETDIR}sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; fi

sparcv9:
	if [ ! -x $@ ]; then ${MKDIR} $@; ${MKDIR} $@/common; \
	${MKDIR} $@/sun4u ; fi

sparcv9/%.o:	%.c
	$(CC64) $(CFLAGS64) $(CFLAGS) -c $< -o $@

sparcv9/%.o:	%.s
	$(AS) $(ASFLAGS64) -P -D_ASM -xarch=v9 $< -o $@

AROBJS_sparcv9	=	`${LORDER} ${OBJS_sparcv9} | ${TSORT}`

${OBJS_sparcv9}: ${HDRS}

${LIBRARY_sparcv9}:	${OBJS_sparcv9}
	${AR} ${ARFLAGS} $@ ${AROBJS_sparcv9} 

clean:
	/bin/rm -f ${OBJS_sparcv9} ${LIBRARY_sparcv9} ${OBPDEFS}

clobber:
	${SCCS} clean

