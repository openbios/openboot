# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: default.mk
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
# id: @(#)default.mk 1.28 04/10/18
# purpose: 
# copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

.PARALLEL:

.SCCS_GET:
	?sccs $(SCCSFLAGS) get $(SCCSGETFLAGS) $@ -G$@ ; echo Getting $@

SPRO_HOME	=	$(SUN_STUDIO)
SPRO_PATH	=	${SPRO_HOME}/bin

CC5	=	${SPRO_PATH}/cc
CC4 	=	/usr/bin

CCS5	=	/usr/ccs/bin
CCS4 	=	/usr/bin

CCSHOME:sh = /bin/uname -r | /bin/awk -F. '{ if ( $1 == 4 ) \
	{printf "${CCS4}"} else {printf "${CCS5}"} }'

CCHOME:sh = /bin/uname -r | /bin/awk -F. '{ if ( $1 == 4 ) \
	{printf "${CC4}"} else {printf "${CC5}"} }'

OSVERS:sh = /bin/uname -r | /bin/awk -F. '{ if ( $1 == 4 ) \
	{printf "BSD"} else {printf "SYS5"} }'

HOSTARCH:sh = /bin/uname -m

USRUCB-BSD	= /usr/ucb
USRUCB-SYS5	= /usr/bin

CCSLIB-BSD	= /usr/lib
CCSLIB-SYS5	= /usr/ccs/lib
CCSLIB		= ${CCSLIB-${OSVERS}}

CC		= ${SPRO_PATH}/cc

PERL		= /pkg/gnu/bin/perl5.6.0

AS		= ${CCSHOME}/as
AR		= ${CCSHOME}/ar
LD	        = ${CCSHOME}/ld
SIZE	        = ${CCSHOME}/size
# MAKE	        = dmake -m parallel
MAKE		= ${CCSHOME}/make
NM		= ${CCSHOME}/nm -n
STRIP	        = ${CCSHOME}/strip
MCS		= ${CCSHOME}/mcs

ADB		= /bin/adb
AWK		= /usr/bin/nawk
CAT		= /bin/cat
CD		= cd
CHMOD	        = /bin/chmod
CMP		= /bin/cmp -l
COMM		= /bin/comm
COMPRESS        = ${USRUCB-${OSVERS}}/compress
CP	        = cp -p
CPP	        = ${CCSLIB}/cpp -undef -D${CPU} -Dsun
DATE		= /bin/date
DD	        = /bin/dd
ECHO	        = /bin/echo
EXPR	        = /bin/expr
EGREP	        = /bin/egrep
GREP	        = /bin/grep
HEAD		= /bin/head
LN	        = /bin/ln -s
MV	        = /bin/mv -f
PRS	        = /usr/sccs/prs
RANLIB		= /bin/ranlib
RM	        = /bin/rm -f

SCCS-BSD	= /usr/ucb/sccs
SCCS-SYS5	= ${CCSHOME}/sccs
SCCS	        = ${SCCS-${OSVERS}}
WHAT		= ${CCSHOME}/what

SED	        = /bin/sed
SHAR	        = /usr/local/bin/shar
SORT	        = /bin/sort
TAIL	        = /usr/ucb/tail
TAR	        = /bin/tar
TOUCH	        = /bin/touch
UNCOMPRESS        = ${USRUCB-${OSVERS}}/uncompress
UNIQ	        = /bin/uniq

TOOLS		= ${ROOT}/bin
TOOLDIR		= ${ROOT}/tools
ROMBO		= ${TOOLS}/rombo
MAKEOBJ		= ${TOOLS}/makeobj
FROMVFONT	= ${TOOLS}/fromvfon
BIN2OBJ		= ${TOOLS}/bin2obj
ELF2BIN		= ${TOOLS}/elf2bin
MAKEPROM	= ${TOOLS}/makeprom
DIDEPEND	= ${TOOLS}/didepend

MAKEARRAY	= ${ROOT}/obp/pkg/tokenizr/sparc/makearray

KERNELFLAGS = -xO2 -DSYS5 -DUNIX  -DSCCS -DDLOPEN -DDEF_DICT="(512*1024L)"

