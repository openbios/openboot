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
# id: @(#)depend.mk  1.2  05/11/21
# purpose: 
# copyright: Copyright 2005 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
# This is a machine generated file
# DO NOT EDIT IT BY HAND

southusb.fc: ${BP}/dev/pci/compatible-prop.fth
southusb.fc: ${BP}/dev/pci/compatible.fth
southusb.fc: ${BP}/dev/pci/config-access.fth
southusb.fc: ${BP}/dev/southbridge/usb/southroot.fth
southusb.fc: ${BP}/dev/southbridge/usb/usbload.fth
southusb.fc: ${BP}/dev/usb/allocator.fth
southusb.fc: ${BP}/dev/usb/bad-dev.fth
southusb.fc: ${BP}/dev/usb/chipmap.fth
southusb.fc: ${BP}/dev/usb/common.fth
southusb.fc: ${BP}/dev/usb/distributor.fth
southusb.fc: ${BP}/dev/usb/dq.fth
southusb.fc: ${BP}/dev/usb/endpointmap.fth
southusb.fc: ${BP}/dev/usb/finder.fth
southusb.fc: ${BP}/dev/usb/gen.fth
southusb.fc: ${BP}/dev/usb/nq.fth
southusb.fc: ${BP}/dev/usb/ohci.fth
southusb.fc: ${BP}/dev/usb/packets.fth
southusb.fc: ${BP}/dev/usb/power-on.fth
southusb.fc: ${BP}/dev/usb/probe.fth
southusb.fc: ${BP}/dev/usb/requests.fth
southusb.fc: ${BP}/dev/usb/required.fth
southusb.fc: ${BP}/dev/usb/sync.fth
southusb.fc: ${BP}/dev/usb/transfermap.fth
southusb.fc: ${BP}/dev/usb/usb.fth
southusb.fc: ${BP}/dev/southbridge/usb/southusb.tok
