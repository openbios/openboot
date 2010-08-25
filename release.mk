# ========== Copyright Header Begin ==========================================
# 
# Hypervisor Software File: release.mk
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
# id: @(#)release.mk 1.3 03/01/09
# purpose: 
# copyright: Copyright 2003 Sun Microsystems, Inc.  All Rights Reserved
# copyright: Use is subject to license terms.

# Gatekeepers/Release Engineers:
#	touch ${ROOT}/RELEASE to build a release image.
#
# Developers:
# put short comments in ${ROOT}/COMMENT if the workspace name is not sufficient

RELEASE	= `if [ -f ${ROOT}/RELEASE ]; then /bin/echo -D RELEASE; fi`

SUBREL = ( \
	  Rootdir=`cd ${ROOT}; pwd`; \
	  Wspace=`/bin/basename $$Rootdir`; \
	  Uid=`/bin/logname`; \
	  Comment=`if [ -f ${ROOT}/COMMENT ]; then cat ${ROOT}/COMMENT; fi`; \
	  if [ ! -f revlevel ]; then echo 0 > revlevel; fi; \
	  Revlevel=`if [ -f revlevel ]; then cat revlevel; fi`; \
	  Build=`if [ -f revlevel ]; then /bin/echo \#$$Revlevel; fi`; \
	  if [ -f ${ROOT}/RELEASE ]; \
	  then	/bin/echo; \
	  elif [ -f ${ROOT}/COMMENT ]; \
	  then	/bin/echo "[$$Uid $$Wspace $$Comment $$Build]"; \
	  else	/bin/echo "[$$Uid $$Wspace $$Build]"; fi; \
	  exit 0; \
	)

SUBREL-FILES = if [ -f ${ROOT}/COMMENT ]; \
		then /bin/echo "${ROOT}/COMMENT"; \
		else /bin/echo; fi

SUB-RELEASE = ${SUBREL:sh}
