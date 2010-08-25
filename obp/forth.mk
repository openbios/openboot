# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: forth.mk
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
# id: @(#)forth.mk 1.6 02/05/02
# purpose: 
# copyright: Copyright 1996-2002 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

CPU		= sparc
FORTHDIR	= ${BP}/os/unix/sparc
FORTH		= ${FORTHDIR}/forth
MAKEDI		= ${TOOLS}/makedi -c

# These are the absolute paths to the various forth engines
FMKERNEL	= ${BP}/fm/kernel/${CPU}
BOOTSTRAPKERNEL	= ${FMKERNEL}/kernel
K32T32		= ${FMKERNEL}/k32t32
K32T16S2	= ${FMKERNEL}/k32t16s2
K32T16S4	= ${FMKERNEL}/k32t16s4
K64T32		= ${FMKERNEL}/k64t32
K64T16S2	= ${FMKERNEL}/k64t16s2
K64T16S4	= ${FMKERNEL}/k64t16s4
K64MINI		= ${FMKERNEL}/k64mini

# These are the absolute paths to the various forth engines
BOOTSTRAPFORTH	= ${BP}/os/sun/sparc/forth32
F32T32		= ${BP}/os/sun/sparc/f32t32
F32T16S2	= ${BP}/os/sun/sparc/f32t16s2
F32T16S4	= ${BP}/os/sun/sparc/f32t16s4
F64T32		= ${BP}/os/sun/sparc/f64t32
F64T16S2	= ${BP}/os/sun/sparc/f64t16s2
F64T16S4	= ${BP}/os/sun/sparc/f64t16s4

# Which forth engine the tokenizer and tools should use.
FORTHDIC	= ${F32T32}.dic

COMPILER	= ${FORTH} -d ${FORTHDIC}
FORTHTOOL	= ${COMPILER} ${FFLAGS} -s "${FTHFLAGS}"
TOKENIZER	= ${BP}/pkg/tokenizr
TOKENIZEDIC	= ${TOKENIZER}/sparc/tokenize.dic
TOKENIZE	= ${FORTH} -d ${TOKENIZEDIC} -D tokenizer? ${FFLAGS}

# MAGIC files:
#   When you build do a touch <thing> and you get more uinformation
#	VERBOSE		= show the filenames as they load
#	NOTIFY		= make compile echo lines show up.
#
NOTIFY:sh	= if [ -f NOTIFY ]; \
		  then /bin/echo "/bin/echo"; \
		  else /bin/echo "/bin/true"; fi;

VERBOSE:sh	= if [ -f VERBOSE ];\
		  then /bin/echo "-v" ;\
		  else /bin/echo ; fi ;

FTHFLAGS	= 

include ${ROOT}/lib/depend.mk
include ${ROOT}/bin/depend.mk
include ${BP}/os/unix/sparc/depend.mk		# Native 32 compile
include ${BP}/os/unix/sparcv9/depend.mk		# Native 64 compile
include ${BP}/os/unix/simforth/sparc/depend.mk	# simforth wrapper
include ${BP}/fm/kernel/${CPU}/depend.mk	# all the forth Kernels
include ${BP}/os/sun/sparc/depend.mk		# Forth engines
include ${TOKENIZER}/${CPU}/depend.mk		# Tokenizer
