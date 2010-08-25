# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: common.mk
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
# id: @(#)common.mk 1.22 06/02/16
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

include ${ROOT}/default.mk
include	${ROOT}/tools/depend.mk
include ${BP}/forth.mk
include ${ROOT}/release.mk

# Include the platform specific flags for building
FFLAGS	+= ${PLATFLAGS}

# MAGIC files:
#   When you build do a touch <thing> and you get more information
#	VERBOSE		  = show the filenames as they load
#	EXTERNAL	  = force all fcode symbols to be external
#	NOTIFY		  = make the Tokenizing message appear
#	WARNING 	  = enable the tokenizer warning messages
#	HEADERS		  = include the 'headers' dropin for added symbols
#	FCODE-HEADERS	  = force non-external fcode symbols to have headers
#	FCODE-HEADERLESS  = force non-external fcode symbols to be headerless

#DECOMPSIZ = 	${SIZE} -f decomp.o | \
#		${AWK} -F+ '{ print $$1 $$2 }' |\
#		${AWK} -F\( ' { print $$2, $$1 }' |\
#		${AWK} '{ print $$2+($$3+3)-(($$3+3) % 4) }'
DECOMPSIZ = 	${SIZE} -f decomp.o | \
		${SED} -e 's/+/ /g' -e 's/(./ /g' -e 's/)//g' |\
		${AWK} -f getsz.awk

DECOMPSIZE =	${DECOMPSIZ:sh}

# Dont define NormalMAP or CompressMAP; If you want to specify a mapfile
# just define MAPFILE.
GetMAP		= if [ -z "${MAPFILE}" ]; \
		  then /bin/echo ${SUN4U}/openboot${ROMSIZE}.map; \
		  else /bin/echo ${MAPFILE}; \
		  fi

NormalMAP	= ${GetMAP:sh}

VERBOSE:sh	= if [ -f VERBOSE ]; \
		then /bin/echo '-v'; \
		elif [ -f ../../VERBOSE ]; \
		then /bin/echo '-v'; \
		else /bin/echo ; fi ;

COMPILER64:sh	= if [ \( -f /usr/bin/optisa -a  \
		"`/usr/bin/optisa sparcv9`" = "sparcv9" \) ]; \
		then /bin/echo '${BP}/os/unix/sparcv9/forth' ;\
		else /bin/echo '${BP}/os/unix/simforth/sparc/simforth' ; fi ;

FORTH64		= ${COMPILER64}

NOTIFY:sh	= if [ -f NOTIFY ]; \
		  then /bin/echo "/bin/echo"; \
		  else /bin/echo "/bin/true"; fi;

WARNINGS:sh	= if [ -f WARNING ];\
		  then /bin/echo "off"; \
		  else /bin/echo "on"; fi ;

EXTERNAL:sh	= if [ -f EXTERNAL ];\
		  then /bin/echo "force-external? on"; fi

FCODE-HEADERS:sh	= if [ -f FCODE-HEADERS ];\
		  then /bin/echo "force-headers? on"; fi

FCODE-HEADERLESS:sh	= if [ -f FCODE-HEADERLESS ];\
		  then /bin/echo "force-headerless? on"; fi


FTHFLAGS	= 

TOKFLAGS	= aout-header? off\
		  silent ${WARNINGS}\
		  ${EXTERNAL} ${FCODE-HEADERS} ${FCODE-HEADERLESS}

HDEBUG:sh	= if [ -f HEADERS ]; \
		  then echo headers.di; fi

FORTHDI		= ${HDEBUG}

# .SUFFIXES: .fc .tok ${SUFFIXES}

etags:	${TOOLS}/fscope fscope.idx FORCE
	( BP=${BP}; export BP; \
	  ${TOOLS}/fscope -a -e -o etags -m etag -f fscope.idx; )

tags:	${TOOLS}/fscope fscope.idx FORCE
	( BP=${BP}; export BP; \
	  ${TOOLS}/fscope -a -e -o tags -m tag -f fscope.idx; )

decomp.o: ${TOOLDIR}/decomp.c
	${ECHO} Compiling $@
	${RM} $@
	${CC} -DSTANDALONE -fast -c ${TOOLDIR}/decomp.c -o decomp.o

# Provide mechanisms to reuse loadprom, config and dropins files from other
# platforms
# 
DROPIN_SRC =	if [ -z "${DROPINSRC}" ]; \
		then	/bin/echo ${PLATFORM}/release/dropins.src; \
		else	/bin/echo ${DROPINSRC}; fi

LOADPROM =	if [ -z "${LOADFILE}" ]; \
		then	/bin/echo ${PLATFORM}/loadprom.fth; \
		else	/bin/echo ${LOADFILE}; fi

CONFIGLOAD =	if [ -z "${CONFIG}" ]; \
		then	if [ -f ${PLATFORM}/setup/configload.fth -o \
			     -f ${PLATFORM}/setup/SCCS/s.configload.fth ]; \
			then /bin/echo ${PLATFORM}/setup/configload.fth; \
			else /bin/echo ; fi \
		else /bin/echo ${CONFIG}; fi

# If the makefile variable or the file MINI_T32 exists then we don't build
# t16 kernels.
MINI_T =	if [ -z "${MINI_T32}" -a ! -f "MINI_T32" ]; \
		then /bin/echo "-t16"; \
		else /bin/echo; fi

MINIFORTH = ${BP}/fm/kernel/sparc/k64mini${MINI_T:sh}

config.bin: ../config.mk ${CONFIGLOAD:sh}
config.bin: ${FORTH64} ${MINIFORTH}.dic
	${NOTIFY} "Building config.bin (${MINI_T:sh})"
	( BP=${BP}; export BP; ${FORTH64} -e 800 \
		-d ${MINIFORTH}.dic \
		${VERBOSE} ${RELEASE} ${FFLAGS} \
		-D kernel-hdr-file=${MINIFORTH}.fth \
		-D LOADFILE=${CONFIGLOAD:sh} \
		-D SAVEFILE=config.bin \
		-D MINIFORTH \
		${BP}/arch/preload.fth )
	${TOUCH} headers
	${SORT} +1 headers > config.headers

config.idx: ${PLATFORM}/setup/configload.fth
config.idx: ${FORTH64} ${MINIFORTH}-xref.dic
	${NOTIFY} Building config.idx
	( BP=${BP}; export BP; ${FORTH64} -e 800 \
		-D MINIFORTH ${RELEASE} -D XREF -x config.idx \
		-d ${MINIFORTH}-xref.dic ${FFLAGS} \
		-D XREF-PRELOAD=${MINIFORTH}-xref.dic.idx \
		-D kernel-hdr-file=${MINIFORTH}-xref.fth \
		-D LOADFILE=${PLATFORM}/setup/configload.fth \
		${BP}/arch/preload.fth )

reset.o: ../reset.mk stand.dic
reset.o: ${FORTH64} ${RESET} ${BP}/arch/preload.fth
	${NOTIFY} Building reset.o
	${GREP} headerless acfheaders > headerless
	${RM} $@
	( BP=${BP}; export BP; ${COMPILER64} \
		-D dropin-mode -D TARGET-FILE=$@ \
		-D RESET -D LOADFILE=${RESET} \
		-e 900 -d stand.dic ${VERBOSE} ${FFLAGS} \
		-s "d# ${DECOMPSIZE} constant decomp-size" \
		-s " warning off"  headerless	\
		${BP}/arch/preload.fth )
	${RM} headerless

reset.bin: decomp.o reset.o ${NormalMAP} ${ELF2BIN}
	${LD} -dn -e reset -M ${NormalMAP} reset.o decomp.o -o reset.elf
	${ELF2BIN} reset.elf reset.bin
	${RM} reset.elf

openboot.bin: builtin.di ${MAKEPROM} reset.bin
	${NOTIFY} Building $@
	${MAKEPROM} ${MAKEPROM-FLAGS} -o openboot.bin -n reset.bin builtin.di

clean::
	${RM} config.bin bootprom.bin reset.bin obp.bin
	${RM} config.di bootprom.di resetdi.o *.idx

DATEFMT='+td %M td %H bwjoin td %d td %m bwjoin wljoin td %Y lxjoin'

stand.dic: bootprom.bin

forth.o: bootprom.bin
	${ECHO} REMOVE THIS TARGET $@

FIRMWAREREL = cat ${BP}/firmware.rel

bootprom.bin: ${RESET}
bootprom.bin: ${BP}/firmware.rel ${CONFIGLOAD:sh} ${SUBREL-FILES:sh}
bootprom.bin: ${LOADPROM:sh} ${BP}/arch/preload.fth
bootprom.bin: ${FORTH64} ${KERNEL.DIC} builtin.fth
	${NOTIFY} "Building Openboot forth image (bootprom.bin)"
	${RM} $@ stand.dic sub-release headers
	if [ ! -f revlevel ]; then echo 0 > revlevel; fi
	${ECHO} "headerless" > version.fth
	${ECHO} `date ${DATEFMT}` >> version.fth
	${ECHO} "constant compile-signature" >> version.fth
	${ECHO} "create (sub-release ,\" ${SUB-RELEASE}\"" >> version.fth
	${ECHO} "create (obp-release ,\" ${FIRMWAREREL:sh}\"" >> version.fth
	${ECHO} "' (sub-release is sub-release" >> version.fth
	${ECHO} "' (obp-release is obp-release" >> version.fth
	${ECHO} "headers" >> version.fth
	${EXPR} `cat revlevel` + 1 > revlevel
	( BP=${BP}; export BP; ${FORTH64} -e 800 \
		-d ${KERNEL.DIC} ${VERBOSE} ${FFLAGS} ${RELEASE} \
		-D kernel-hdr-file=${KERNEL}.fth \
		-D LOADFILE=${LOADPROM:sh} \
		-D SAVEFILE=bootprom.bin \
		${BP}/arch/preload.fth )
	${TOUCH} headers
	${SORT} +1 headers > acfheaders

fscope.idx: ${FORTH64} ${KERNEL}-xref.dic bootprom.bin
	${NOTIFY} Creating $@
	( BP=${BP}; export BP; ${FORTH64} -e 800 \
		-d ${KERNEL}-xref.dic ${FFLAGS} ${RELEASE} \
		-D kernel-hdr-file=${KERNEL}-xref.fth \
		-D XREF-PRELOAD=${KERNEL}-xref.dic.idx \
		-D XREF -x fscope.idx \
		-D LOADFILE=${LOADPROM:sh} \
		${BP}/arch/preload.fth )

clean:: ${DIDEPEND} ${DROPIN_SRC:sh}
	${RM} dropins.mk builtin.fth
	${RM} forth.bin openboot.bin
	${RM} forth.bin0 openboot.bin0
	${RM} forth.out openboot.prom
	${RM} reset.o decomp.o forth.o cforth.o
	${RM} version.fth lastversion.fth stand.dic
	${RM} kbdtrans.fc sun-logo.dat usbkbds.dat builtin.di
	${RM} acfheaders headers revlevel-
	${RM} openboot.img
	${RM} `${DIDEPEND} ${PLATFLAGS} -t ${DROPIN_SRC:sh}`
	${RM} `${DIDEPEND} ${PLATFLAGS} -s ${DROPIN_SRC:sh}`
	${RM} *.idx *.fc *.di *.o
	${RM} core HEADERS

TOKENRULE = \
	( fname=".XX.YY.XX"; for i in $(?D); do \
		if [ -f $$i/*.tok ]; then fname=`${ECHO} $$i/*.tok`; fi; \
	done; \
	if [ -f $$fname ]; then \
		${NOTIFY} "Tokenizing $$fname"; \
		BP=${BP}; export BP; \
		${TOKENIZE} ${VERBOSE} ${RELEASE} -x $*.idx \
		-s "${FTHFLAGS}" \
		-s "${TOKFLAGS} tokenize $$fname $*.fc"; \
	else \
		${RM} $*.fc; \
		${MAKE} $*.fc; \
	fi )

%.fc:
	${TOKENRULE}

install: backup
	@${WHAT} openboot.bin
	if [ -f RTARGET ]; then \
		/bin/echo Installing `cat RTARGET`/openboot.bin ;\
		rcp -p openboot.bin `cat RTARGET`;\
		if [ -f forth.flash ]; then \
			/bin/echo Installing `cat RTARGET`/forth.flash ;\
			rcp -p forth.flash `cat RTARGET`;\
		fi;\
	fi ;\
	if [ -f TARGET ]; then \
		/bin/echo Installing `cat TARGET` ;\
		cp -p openboot.bin `cat TARGET`;\
	fi

DEPEND.MK	= ../depend.mk
DEPEND.MK1	= depend.new
# As of 2004, the convention is just the current year, not a range of years.
CDATE:sh = /bin/date '+Copyright %Y Sun Microsystems, Inc.'
# depend := FFLAGS += -v
depend:: ${DEPEND.MK} ${TOOLS}/move-if-changed builtin.fth stand.dic FORCE
	${RM} ${DEPEND.MK1}
	${ECHO} "# id: ""%""Z""%""%""M""%" " %""I""%" " %""E""%">${DEPEND.MK1}
	${ECHO} "# purpose: ""%""Y""%" >>${DEPEND.MK1}
	${ECHO} "# copyright: ${CDATE} All Rights Reserved" >>${DEPEND.MK1}
	${ECHO} "# copyright: Use is subject to license terms." >>${DEPEND.MK1}
	${ECHO} "# This is a machine generated file" >>${DEPEND.MK1}
	${ECHO} "# DO NOT EDIT IT BY HAND" >>${DEPEND.MK1}
	( BP=${BP}; export BP; ${FORTH64} -e 800 -d ${KERNEL.DIC} \
		-D DEPEND -D kernel-hdr-file=${KERNEL}.fth ${FFLAGS} -u -v \
		-D LOADFILE=${LOADPROM:sh} \
		${BP}/arch/preload.fth ) |\
		${GREP} File: |\
		${EGREP} -v "(version.fth| headers| loadprom.fth)" |\
		${SED} -e 's/File: /bootprom.bin: /'|\
		${SED} -e 's:${BP}:$${BP}:' |\
		${SORT}|${UNIQ} >>${DEPEND.MK1}
	${TOOLS}/move-if-changed ${DEPEND.MK} ${DEPEND.MK1}

depend:: ${DEPEND.MK} ${TOOLS}/move-if-changed builtin.fth stand.dic FORCE
	( BP=${BP}; export BP; \
	if [ ! -z "${CONFIGLOAD:sh}" ]; then \
	${RM} ${DEPEND.MK1}; \
	${ECHO} "# id: ""%""Z""%""%""M""% %""I""%" " %""E""%">${DEPEND.MK1}; \
	${ECHO} "# purpose: ""%""Y""%" >>${DEPEND.MK1}; \
	${ECHO} "# copyright: ${CDATE} All Rights Reserved" >>${DEPEND.MK1}; \
	${ECHO} "# copyright: Use is subject to license terms." >>${DEPEND.MK1}; \
	${ECHO} "# This is a machine generated file" >>${DEPEND.MK1}; \
	${ECHO} "# DO NOT EDIT IT BY HAND" >>${DEPEND.MK1}; \
	( ${FORTH64} -e 800 -d ${KERNEL.DIC} \
		-D MINIFORTH -D DEPEND ${RELEASE} \
		-D kernel-hdr-file=${KERNEL}.fth ${FFLAGS} -u -v \
		-D LOADFILE=${CONFIGLOAD:sh} \
		${BP}/arch/preload.fth ) |\
		${GREP} File: | \
		${EGREP} -v "(version.fth| headers)" |\
		${SED} -e 's/File: /config.bin: /'|\
		${SED} -e 's:${BP}:$${BP}:'|\
		${SORT}|${UNIQ} >>${DEPEND.MK1}; \
	${TOOLS}/move-if-changed ../config.mk ${DEPEND.MK1}; \
	else \
		exit 0; \
	fi; )

depend:: ../reset.mk stand.dic decomp.o ${TOOLS}/move-if-changed FORCE
	${GREP} headerless acfheaders > headerless
	${RM} reset.o
	${RM} ${DEPEND.MK1}
	${ECHO} "# id: ""%""Z""%""%""M""%" " %""I""%" " %""E""%">${DEPEND.MK1}
	${ECHO} "# purpose: ""%""Y""%" >>${DEPEND.MK1}
	${ECHO} "# copyright: ${CDATE} All Rights Reserved" >>${DEPEND.MK1}
	${ECHO} "# copyright: Use is subject to license terms." >>${DEPEND.MK1}
	${ECHO} "# This is a machine generated file" >>${DEPEND.MK1}
	${ECHO} "# DO NOT EDIT IT BY HAND" >>${DEPEND.MK1}
	( BP=${BP}; export BP; ${COMPILER64} \
		-D RESET -D DEPEND ${RELEASE} -D LOADFILE=${RESET} \
		-e 900 -d stand.dic ${FFLAGS} -v -u \
		-s "d# ${DECOMPSIZE} constant decomp-size" \
		-s " warning off"  headerless	\
		${BP}/arch/preload.fth ) |\
		${GREP} File: |\
		${EGREP} -v "(headerless| reset.fth)" |\
		${SED} -e 's/File: /reset.o: /'|\
		${SED} -e 's:${BP}:$${BP}:'|\
		${SORT}|${UNIQ} >>${DEPEND.MK1}
	${TOOLS}/move-if-changed ../reset.mk ${DEPEND.MK1}
	${RM} headerless

backup: all ${MAKEPROM}
	${RM} forth.flash
	if [ -f openboot.ok ]; then \
		${MAKEPROM} -o forth.flash openboot.bin openboot.ok ;\
	fi

clobber::
	${SCCS} clean

builtin.fth: ${DIDEPEND} ${DROPIN_SRC:sh}
	${DIDEPEND} ${PLATFLAGS} -c ${DROPIN_SRC:sh} > builtin.fth

dropins.mk: ${DIDEPEND} ${DROPIN_SRC:sh}
	${DIDEPEND} ${PLATFLAGS} -d ${DROPIN_SRC:sh} > dropins.mk
	${ECHO} >> dropins.mk
	${ECHO} "builtin.di: `${DIDEPEND} ${PLATFLAGS} -t ${DROPIN_SRC:sh}`" >> dropins.mk

headers.di: ${TOOLS}/makedi headers
	${ECHO} "\\\ Forth Comment" > headers.dat
	${CAT} headers >> headers.dat
	${MAKEDI} headers.dat headers
	${RM} headers.dat

# Get the dropins that make an image.

DIFCODE = 	if [ ! -f ${DROPIN_SRC:sh} ]; then \
		( cd `dirname ${DROPIN_SRC:sh}`; sccs get dropins.src; ) fi; \
		${DIDEPEND} ${PLATFLAGS} -s ${DROPIN_SRC:sh} | \
		sed -e 's/config.bin//' -e 's/bootprom.bin//'

DITARGETS = 	${DIDEPEND} ${PLATFLAGS} -t ${DROPIN_SRC:sh}

builtin.di: ${FORTH} ${TOKENIZEDIC}
builtin.di: ${DROPIN_SRC:sh} ${TOOLS}/makedi ${FORTHDI} ${DIDEPEND}
	cat ${FORTHDI} ${DITARGETS:sh} > builtin.di

include dropins.mk
