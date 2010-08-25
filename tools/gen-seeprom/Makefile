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
# id: @(#)Makefile 1.4 03/03/14
# purpose: 
# copyright: Copyright 2001-2003 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

ROOT    = ../..
BP      = ${ROOT}/obp

COMPILED:sh =   date -u +"KK%S,KK%M,KK%H,KK%d,KK%m-1,%Y-19XX,%w," | \
                sed -e 's/KK0//g' | sed -e 's/KK//g' | sed -e 's/XX/00/'

TIMEFLAGS =     -DACTIVE_TIME="8*7*24*60*60"
TIMEFLAGS +=    -DCOMPILE_TIME=${COMPILED}
CPPFLAGS +=     ${DFLAGS} ${TIMEFLAGS}

include ${ROOT}/default.mk

SEEPROMS	= .

all: gen-seeprom
	cp gen-seeprom ${TOOLS}

depend:

clean:
	${RM} *.o gen-seeprom

clobber:
	${SCCS} clean

include depend.mk

