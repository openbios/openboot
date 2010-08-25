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
# id: @(#)depend.mk 1.5 02/10/09
# purpose: 
# copyright: Copyright 2000-2002 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

gen-seeprom.o: gen-seeprom.c gen-seeprom.h prototypes.h
gen-seeprom-debug.o: gen-seeprom.c gen-seeprom.h prototypes.h
	@${RM} $@
	${CC} -c -DDEBUG gen-seeprom.c -o gen-seeprom-debug.o
cpu-seeprom.o: cpu-seeprom.c cpu-seeprom.h gen-seeprom.h
sys-seeprom.o: sys-seeprom.c common.c sys-seeprom.h gen-seeprom.h
env-seeprom.o: env-seeprom.c common.c gen-seeprom.h env-seeprom.h 
mem-seeprom.o: mem-seeprom.c common.c gen-seeprom.h mem-seeprom.h

gen-seeprom: gen-seeprom.o cpu-seeprom.o sys-seeprom.o env-seeprom.o \
	mem-seeprom.o common.o
	@${RM} $@
	${CC} gen-seeprom.o cpu-seeprom.o sys-seeprom.o \
	env-seeprom.o mem-seeprom.o common.o -o gen-seeprom

debug: gen-seeprom-debug.o cpu-seeprom.o sys-seeprom.o env-seeprom.o \
	mem-seeprom.o common.o
	@${RM} $@
	${CC} gen-seeprom-debug.o cpu-seeprom.o sys-seeprom.o \
	env-seeprom.o mem-seeprom.o common.o -o gen-seeprom.debug
