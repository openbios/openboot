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
# id: @(#)depend.mk 1.7 06/02/16
# copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

${TOKENIZEDIC}: ${FORTH} ${FORTHDIC}
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/${CPU}/loadtok.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/tokenize.fth
${TOKENIZEDIC}: ${BP}/fm/lib/split.fth
${TOKENIZEDIC}: ${BP}/fm/lib/message.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/primlist.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/primlist.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/sysprims.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/regcodes.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/sysprm64.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/vendorfcodes.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/obsfcode.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/obsfcod0.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/obsfcod1.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/obsfcod2.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/vfcodes/obdiag.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/vfcodes/cmn-msg.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/vfcodes/sun4v.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/crosslis.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/detokeni.fth
${TOKENIZEDIC}: ${BP}/pkg/fcode/common.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/obsfcdtk.fth
${TOKENIZEDIC}: ${BP}/pkg/tokenizr/obsfdtk0.fth
	(BP=${BP}; export BP; \
	${COMPILER} ${FFLAGS} ${BP}/pkg/tokenizr/${CPU}/loadtok.fth)

