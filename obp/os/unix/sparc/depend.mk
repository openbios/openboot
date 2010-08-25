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
# id: @(#)depend.mk 1.4 03/08/20
# purpose: 
# copyright: Copyright 1999-2003 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

${BP}/os/unix/sparc/forth:= LFLAGS += -ldl -ltermcap
${BP}/os/unix/sparc/forth:= LFLAGS += -L ${ROOT}/lib -lxref -ldef
${BP}/os/unix/sparc/forth: ${ROOT}/lib/libxref.a
${BP}/os/unix/sparc/forth: ${ROOT}/lib/libdef.a
${BP}/os/unix/sparc/forth: ${BP}/os/unix/sparc/wrapper.o
${BP}/os/unix/sparc/forth: ${BP}/os/unix/sparc/termcap.o
${BP}/os/unix/sparc/forth: ${BP}/os/unix/sparc/fsys.o
	$(CC) -o $@  ${BP}/os/unix/sparc/termcap.o \
	${BP}/os/unix/sparc/wrapper.o \
	${BP}/os/unix/sparc/fsys.o \
	${LFLAGS}

${BP}/os/unix/sparc/wrapper.o:= CFLAGS += ${KERNELFLAGS} -I ${ROOT}/lib
${BP}/os/unix/sparc/wrapper.o: ${ROOT}/lib/xref.h
${BP}/os/unix/sparc/wrapper.o: ${ROOT}/lib/xref_support.h
${BP}/os/unix/sparc/wrapper.o: ${ROOT}/lib/defines.h
${BP}/os/unix/sparc/wrapper.o: ${BP}/os/unix/wrapper.c
${BP}/os/unix/sparc/wrapper.o: ${BP}/os/unix/wrapper.h
	$(CC) $(CFLAGS) -c ${BP}/os/unix/wrapper.c -o $@

${BP}/os/unix/sparc/fsys.o:= CFLAGS += ${KERNELFLAGS} -I ${ROOT}/lib
${BP}/os/unix/sparc/fsys.o: ${ROOT}/lib/xref.h
${BP}/os/unix/sparc/fsys.o: ${ROOT}/lib/xref_support.h
${BP}/os/unix/sparc/fsys.o: ${ROOT}/lib/defines.h
${BP}/os/unix/sparc/fsys.o: ${BP}/os/unix/wrapper.h
${BP}/os/unix/sparc/fsys.o: ${BP}/os/unix/fsys.c
	$(CC) $(CFLAGS) -c ${BP}/os/unix/fsys.c -o $@

${BP}/os/unix/sparc/termcap.o:= CFLAGS += ${KERNELFLAGS} -I ${ROOT}/lib
${BP}/os/unix/sparc/termcap.o: ${BP}/os/unix/termcap.c
	$(CC) $(CFLAGS) -c ${BP}/os/unix/termcap.c -o $@
