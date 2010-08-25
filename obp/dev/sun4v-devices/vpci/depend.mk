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
# id: @(#)depend.mk  1.2  06/04/13
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
# This is a machine generated file
# DO NOT EDIT IT BY HAND

vpci.fc: ${BP}/dev/pci/cfgio.fth
vpci.fc: ${BP}/dev/pci/compatible-prop.fth
vpci.fc: ${BP}/dev/pci/debug.fth
vpci.fc: ${BP}/dev/pci/device-props.fth
vpci.fc: ${BP}/dev/pci/fcode-rom.fth
vpci.fc: ${BP}/dev/pci/generic-names.fth
vpci.fc: ${BP}/dev/pci/make-device.fth
vpci.fc: ${BP}/dev/pci/make-path.fth
vpci.fc: ${BP}/dev/pci/map.fth
vpci.fc: ${BP}/dev/pci/memstack.fth
vpci.fc: ${BP}/dev/pci/pcibus.fth
vpci.fc: ${BP}/dev/pci/preprober.fth
vpci.fc: ${BP}/dev/pci/probe-reg.fth
vpci.fc: ${BP}/dev/pci/unit.fth
vpci.fc: ${BP}/dev/psycho/memdebug.fth
vpci.fc: ${BP}/dev/sun4v-devices/iommu/iommu.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/bus-ops.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/common.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/hv-iface.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/methods.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/msi-props.fth
vpci.fc: ${BP}/dev/utilities/cif.fth
vpci.fc: ${BP}/dev/utilities/memlist.fth
vpci.fc: ${BP}/dev/utilities/memlistdebug.fth
vpci.fc: ${BP}/dev/utilities/misc.fth
vpci.fc: ${BP}/dev/utilities/shifter.fth
vpci.fc: ${BP}/dev/utilities/swapped-access.fth
vpci.fc: ${BP}/pkg/asr/pci-prober-support.fth
vpci.fc: ${BP}/pkg/asr/prober-support.fth
vpci.fc: ${BP}/dev/sun4v-devices/vpci/vpci.tok
