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
# id: @(#)depend.mk 1.10 01/10/17
# purpose: 
# copyright: Copyright 1997-1999, 2001 Sun Microsystems, Inc.  All Rights Reserved

usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/options.fth
usbkbds.dat: ${BP}/pkg/keyboard/headers.fth
usbkbds.dat: ${BP}/pkg/keyboard/keycodes.fth
usbkbds.dat: ${BP}/pkg/keyboard/keytable.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/keycodes.fth
usbkbds.dat: ${BP}/pkg/keyboard/install.fth
usbkbds.dat: ${BP}/pkg/keyboard/tableutil.fth
usbkbds.dat: ${BP}/pkg/keyboard/debug.fth
usbkbds.dat: ${BP}/pkg/keyboard/tablecode.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-us.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-spanish.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-arabic.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-belgium.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-danish.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-finnish.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-french.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-german.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-italian.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-netherlands.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-norwegian.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-portuguese.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-swedish.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-swiss-french.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-swiss-german.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-turkeyf.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-turkeyq.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/usb-uk.fth
usbkbds.dat: ${BP}/pkg/keyboard/tables/usb/aliases.fth
