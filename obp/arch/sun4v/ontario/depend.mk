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
# id: @(#)depend.mk  1.4  06/05/10
# purpose: 
# copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
# copyright: Use is subject to license terms.
# This is a machine generated file
# DO NOT EDIT IT BY HAND
bootprom.bin: ${BP}/arch/preload.fth
bootprom.bin: ${BP}/arch/sun/auto-field.fth
bootprom.bin: ${BP}/arch/sun/cmn-msg-format.fth
bootprom.bin: ${BP}/arch/sun/dynamic-user.fth
bootprom.bin: ${BP}/arch/sun/forthinit.fth
bootprom.bin: ${BP}/arch/sun/idprom.fth
bootprom.bin: ${BP}/arch/sun/keystore.fth
bootprom.bin: ${BP}/arch/sun/model.fth
bootprom.bin: ${BP}/arch/sun4j/nvram-personality.fth
bootprom.bin: ${BP}/arch/sun4s/msloop.fth
bootprom.bin: ${BP}/arch/sun4s/reentry-table.fth
bootprom.bin: ${BP}/arch/sun4u/arcbpsup.fth
bootprom.bin: ${BP}/arch/sun4u/asmmacros.fth
bootprom.bin: ${BP}/arch/sun4u/config/banner.fth
bootprom.bin: ${BP}/arch/sun4u/config/console.fth
bootprom.bin: ${BP}/arch/sun4u/config/nvramrc.fth
bootprom.bin: ${BP}/arch/sun4u/config/reset-recovery.fth
bootprom.bin: ${BP}/arch/sun4u/config/scsi-id.fth
bootprom.bin: ${BP}/arch/sun4u/config/termemu.fth
bootprom.bin: ${BP}/arch/sun4u/consredir.fth
bootprom.bin: ${BP}/arch/sun4u/fieldberr.fth
bootprom.bin: ${BP}/arch/sun4u/go.fth
bootprom.bin: ${BP}/arch/sun4u/help.fth
bootprom.bin: ${BP}/arch/sun4u/power-off.fth
bootprom.bin: ${BP}/arch/sun4u/quark/le-access.fth
bootprom.bin: ${BP}/arch/sun4u/reboot.fth
bootprom.bin: ${BP}/arch/sun4u/reenter.fth
bootprom.bin: ${BP}/arch/sun4u/retained.fth
bootprom.bin: ${BP}/arch/sun4u/slavecpu.fth
bootprom.bin: ${BP}/arch/sun4u/startcpu.fth
bootprom.bin: ${BP}/arch/sun4u/starthacks.fth
bootprom.bin: ${BP}/arch/sun4u/startup.fth
bootprom.bin: ${BP}/arch/sun4u/switchcpu.fth
bootprom.bin: ${BP}/arch/sun4u/trans.fth
bootprom.bin: ${BP}/arch/sun4u/traptable.fth
bootprom.bin: ${BP}/arch/sun4u/unixmap.fth
bootprom.bin: ${BP}/arch/sun4v/api-group-id.fth
bootprom.bin: ${BP}/arch/sun4v/api-version.fth
bootprom.bin: ${BP}/arch/sun4v/auto-boot-on-error.fth
bootprom.bin: ${BP}/arch/sun4v/catchexc.fth
bootprom.bin: ${BP}/arch/sun4v/console-tty.fth
bootprom.bin: ${BP}/arch/sun4v/cpu.fth
bootprom.bin: ${BP}/arch/sun4v/cpustruct.fth
bootprom.bin: ${BP}/arch/sun4v/devalias.fth
bootprom.bin: ${BP}/arch/sun4v/erie/intrmap.fth
bootprom.bin: ${BP}/arch/sun4v/erie/local-mac-addr.fth
bootprom.bin: ${BP}/arch/sun4v/fastfill.fth
bootprom.bin: ${BP}/arch/sun4v/forthint.fth
bootprom.bin: ${BP}/arch/sun4v/hfcodes.fth
bootprom.bin: ${BP}/arch/sun4v/hslave.fth
bootprom.bin: ${BP}/arch/sun4v/hv-errcode.fth
bootprom.bin: ${BP}/arch/sun4v/hyperconsole.fth
bootprom.bin: ${BP}/arch/sun4v/machine-init.fth
bootprom.bin: ${BP}/arch/sun4v/mapdi.fth
bootprom.bin: ${BP}/arch/sun4v/mdload.fth
bootprom.bin: ${BP}/arch/sun4v/mdscan.fth
bootprom.bin: ${BP}/arch/sun4v/memprobe.fth
bootprom.bin: ${BP}/arch/sun4v/mmumiss.fth
bootprom.bin: ${BP}/arch/sun4v/mondo.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/boot.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/bootscript.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/cleanup.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/fixed.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/hv-apis.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/loadconfig.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/loadprom.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/probeall.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/sysinfo.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/tlbsetup.fth
bootprom.bin: ${BP}/arch/sun4v/niagara/virtaddrs.fth
bootprom.bin: ${BP}/arch/sun4v/ramforth.fth
bootprom.bin: ${BP}/arch/sun4v/root-prober.fth
bootprom.bin: ${BP}/arch/sun4v/rootnexus.fth
bootprom.bin: ${BP}/arch/sun4v/xcall.fth
bootprom.bin: ${BP}/cpu/sparc/acall.fth
bootprom.bin: ${BP}/cpu/sparc/asi9.fth
bootprom.bin: ${BP}/cpu/sparc/asmmacro.fth
bootprom.bin: ${BP}/cpu/sparc/assem.fth
bootprom.bin: ${BP}/cpu/sparc/call.fth
bootprom.bin: ${BP}/cpu/sparc/call32.fth
bootprom.bin: ${BP}/cpu/sparc/ccall.fth
bootprom.bin: ${BP}/cpu/sparc/ccalls.fth
bootprom.bin: ${BP}/cpu/sparc/code.fth
bootprom.bin: ${BP}/cpu/sparc/cpustate.fth
bootprom.bin: ${BP}/cpu/sparc/disforw.fth
bootprom.bin: ${BP}/cpu/sparc/doccall.fth
bootprom.bin: ${BP}/cpu/sparc/fentry9.fth
bootprom.bin: ${BP}/cpu/sparc/fpu9.fth
bootprom.bin: ${BP}/cpu/sparc/init-c9.fth
bootprom.bin: ${BP}/cpu/sparc/memtest.fth
bootprom.bin: ${BP}/cpu/sparc/mutex.fth
bootprom.bin: ${BP}/cpu/sparc/register9.fth
bootprom.bin: ${BP}/cpu/sparc/traps9.fth
bootprom.bin: ${BP}/cpu/sparc/ultra/implasm.fth
bootprom.bin: ${BP}/cpu/sparc/ultra/impldis.fth
bootprom.bin: ${BP}/cpu/sparc/ultra/mmu-policy/8k-pages.fth
bootprom.bin: ${BP}/cpu/sparc/ultra/mmu.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/asmmacro.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/hypermmu.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/hypervisor.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/implasm.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/loadultra.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/map.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/mmuregs.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/savecpu.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/tlb.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/tlbasm.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/tte-lookup.fth
bootprom.bin: ${BP}/cpu/sparc/ultra4v/tte.fth
bootprom.bin: ${BP}/dev/builtin.fth
bootprom.bin: ${BP}/dev/deblock.fth
bootprom.bin: ${BP}/dev/ide/probe.fth
bootprom.bin: ${BP}/dev/pci/knownprops.fth
bootprom.bin: ${BP}/dev/scsi/probescsi.fth
bootprom.bin: ${BP}/fm/cwrapper/binhdr.fth
bootprom.bin: ${BP}/fm/cwrapper/sparc/savefort.fth
bootprom.bin: ${BP}/fm/kernel/sparc/k64t32.fth
bootprom.bin: ${BP}/fm/kernel/sparc/loadsyms.fth
bootprom.bin: ${BP}/fm/lib/action-primitives.fth
bootprom.bin: ${BP}/fm/lib/ansiterm.fth
bootprom.bin: ${BP}/fm/lib/array.fth
bootprom.bin: ${BP}/fm/lib/brackif.fth
bootprom.bin: ${BP}/fm/lib/breakpt.fth
bootprom.bin: ${BP}/fm/lib/caller.fth
bootprom.bin: ${BP}/fm/lib/callfind.fth
bootprom.bin: ${BP}/fm/lib/chains.fth
bootprom.bin: ${BP}/fm/lib/cirstack.fth
bootprom.bin: ${BP}/fm/lib/cmdcpl.fth
bootprom.bin: ${BP}/fm/lib/copyrigh.fth
bootprom.bin: ${BP}/fm/lib/debug.fth
bootprom.bin: ${BP}/fm/lib/decomp.fth
bootprom.bin: ${BP}/fm/lib/dispose.fth
bootprom.bin: ${BP}/fm/lib/dump.fth
bootprom.bin: ${BP}/fm/lib/dumphead.fth
bootprom.bin: ${BP}/fm/lib/editcmd.fth
bootprom.bin: ${BP}/fm/lib/fastspac.fth
bootprom.bin: ${BP}/fm/lib/fcmdcpl.fth
bootprom.bin: ${BP}/fm/lib/fileed.fth
bootprom.bin: ${BP}/fm/lib/filetool.fth
bootprom.bin: ${BP}/fm/lib/format.fth
bootprom.bin: ${BP}/fm/lib/headless.fth
bootprom.bin: ${BP}/fm/lib/headtool.fth
bootprom.bin: ${BP}/fm/lib/initsave.fth
bootprom.bin: ${BP}/fm/lib/instdis.fth
bootprom.bin: ${BP}/fm/lib/linklist.fth
bootprom.bin: ${BP}/fm/lib/loadcomm.fth
bootprom.bin: ${BP}/fm/lib/loadedit.fth
bootprom.bin: ${BP}/fm/lib/loclabel.fth
bootprom.bin: ${BP}/fm/lib/message.fth
bootprom.bin: ${BP}/fm/lib/needs.fth
bootprom.bin: ${BP}/fm/lib/objects.fth
bootprom.bin: ${BP}/fm/lib/parses1.fth
bootprom.bin: ${BP}/fm/lib/patch.fth
bootprom.bin: ${BP}/fm/lib/pseudors.fth
bootprom.bin: ${BP}/fm/lib/rstrace.fth
bootprom.bin: ${BP}/fm/lib/savedstk.fth
bootprom.bin: ${BP}/fm/lib/seechain.fth
bootprom.bin: ${BP}/fm/lib/showspac.fth
bootprom.bin: ${BP}/fm/lib/sift.fth
bootprom.bin: ${BP}/fm/lib/sparc/bitops.fth
bootprom.bin: ${BP}/fm/lib/sparc/cpubpsup.fth
bootprom.bin: ${BP}/fm/lib/sparc/ctrace9.fth
bootprom.bin: ${BP}/fm/lib/sparc/debugm.fth
bootprom.bin: ${BP}/fm/lib/sparc/decompm.fth
bootprom.bin: ${BP}/fm/lib/sparc/dfill.fth
bootprom.bin: ${BP}/fm/lib/sparc/external.fth
bootprom.bin: ${BP}/fm/lib/sparc/ftrace.fth
bootprom.bin: ${BP}/fm/lib/sparc/lmove.fth
bootprom.bin: ${BP}/fm/lib/sparc/objsup.fth
bootprom.bin: ${BP}/fm/lib/split.fth
bootprom.bin: ${BP}/fm/lib/stringar.fth
bootprom.bin: ${BP}/fm/lib/strings.fth
bootprom.bin: ${BP}/fm/lib/substrin.fth
bootprom.bin: ${BP}/fm/lib/suspend.fth
bootprom.bin: ${BP}/fm/lib/th.fth
bootprom.bin: ${BP}/fm/lib/transien.fth
bootprom.bin: ${BP}/fm/lib/unixedit.fth
bootprom.bin: ${BP}/fm/lib/util.fth
bootprom.bin: ${BP}/fm/lib/words.fth
bootprom.bin: ${BP}/fm/lib/xref.fth
bootprom.bin: ${BP}/os/bootprom/alarm.fth
bootprom.bin: ${BP}/os/bootprom/allocmor.fth
bootprom.bin: ${BP}/os/bootprom/allocph.fth
bootprom.bin: ${BP}/os/bootprom/allocsym.fth
bootprom.bin: ${BP}/os/bootprom/allocvir.fth
bootprom.bin: ${BP}/os/bootprom/availmem.fth
bootprom.bin: ${BP}/os/bootprom/breadth.fth
bootprom.bin: ${BP}/os/bootprom/callback.fth
bootprom.bin: ${BP}/os/bootprom/canon.fth
bootprom.bin: ${BP}/os/bootprom/clientif.fth
bootprom.bin: ${BP}/os/bootprom/clntmem.fth
bootprom.bin: ${BP}/os/bootprom/comprop.fth
bootprom.bin: ${BP}/os/bootprom/console.fth
bootprom.bin: ${BP}/os/bootprom/contigph.fth
bootprom.bin: ${BP}/os/bootprom/deladdr.fth
bootprom.bin: ${BP}/os/bootprom/devpaths.fth
bootprom.bin: ${BP}/os/bootprom/devtree.fth
bootprom.bin: ${BP}/os/bootprom/diagmode.fth
bootprom.bin: ${BP}/os/bootprom/dlbin.fth
bootprom.bin: ${BP}/os/bootprom/dload.fth
bootprom.bin: ${BP}/os/bootprom/dropin.fth
bootprom.bin: ${BP}/os/bootprom/eject.fth
bootprom.bin: ${BP}/os/bootprom/execall.fth
bootprom.bin: ${BP}/os/bootprom/execbuf.fth
bootprom.bin: ${BP}/os/bootprom/finddev.fth
bootprom.bin: ${BP}/os/bootprom/finddisp.fth
bootprom.bin: ${BP}/os/bootprom/fwfileop.fth
bootprom.bin: ${BP}/os/bootprom/initdict.fth
bootprom.bin: ${BP}/os/bootprom/instance.fth
bootprom.bin: ${BP}/os/bootprom/instmall.fth
bootprom.bin: ${BP}/os/bootprom/loaddevt.fth
bootprom.bin: ${BP}/os/bootprom/loadlist.fth
bootprom.bin: ${BP}/os/bootprom/malloc.fth
bootprom.bin: ${BP}/os/bootprom/mapdev.fth
bootprom.bin: ${BP}/os/bootprom/memlist.fth
bootprom.bin: ${BP}/os/bootprom/memmap.fth
bootprom.bin: ${BP}/os/bootprom/msgbuf.fth
bootprom.bin: ${BP}/os/bootprom/pdump.fth
bootprom.bin: ${BP}/os/bootprom/propenc.fth
bootprom.bin: ${BP}/os/bootprom/regwords.fth
bootprom.bin: ${BP}/os/bootprom/release.fth
bootprom.bin: ${BP}/os/bootprom/relinkdt.fth
bootprom.bin: ${BP}/os/bootprom/scrubmem.fth
bootprom.bin: ${BP}/os/bootprom/showdisk.fth
bootprom.bin: ${BP}/os/bootprom/showlocation.fth
bootprom.bin: ${BP}/os/bootprom/showvers.fth
bootprom.bin: ${BP}/os/bootprom/siftdevs.fth
bootprom.bin: ${BP}/os/bootprom/sparc/instance.fth
bootprom.bin: ${BP}/os/bootprom/standini.fth
bootprom.bin: ${BP}/os/bootprom/sysintf.fth
bootprom.bin: ${BP}/os/bootprom/sysnodes.fth
bootprom.bin: ${BP}/os/bootprom/testdevt.fth
bootprom.bin: ${BP}/os/bootprom/trace.fth
bootprom.bin: ${BP}/os/stand/probe.fth
bootprom.bin: ${BP}/os/stand/sparc/notmeta.fth
bootprom.bin: ${BP}/os/stand/sysuart.fth
bootprom.bin: ${BP}/os/sun/aout.fth
bootprom.bin: ${BP}/os/sun/elf.fth
bootprom.bin: ${BP}/os/sun/elf64.fth
bootprom.bin: ${BP}/os/sun/elfdbg64.fth
bootprom.bin: ${BP}/os/sun/elfdebug.fth
bootprom.bin: ${BP}/os/sun/elfsym.fth
bootprom.bin: ${BP}/os/sun/exports.fth
bootprom.bin: ${BP}/os/sun/nlist.fth
bootprom.bin: ${BP}/os/sun/sparc/elf.fth
bootprom.bin: ${BP}/os/sun/sparc/loadfw.fth
bootprom.bin: ${BP}/os/sun/sparc/loadmach.fth
bootprom.bin: ${BP}/os/sun/sparc/makecent9.fth
bootprom.bin: ${BP}/os/sun/sparc/reloc.fth
bootprom.bin: ${BP}/os/sun/symcif.fth
bootprom.bin: ${BP}/os/sun/symdebug.fth
bootprom.bin: ${BP}/os/unix/simforth/findnext.fth
bootprom.bin: ${BP}/pkg/boot/bootparm.fth
bootprom.bin: ${BP}/pkg/boot/sunlabel.fth
bootprom.bin: ${BP}/pkg/confvar/access.fth
bootprom.bin: ${BP}/pkg/confvar/accesstypes.fth
bootprom.bin: ${BP}/pkg/confvar/attach.fth
bootprom.bin: ${BP}/pkg/confvar/confact.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/byte.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/bytes.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/confvoc/boolean.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/confvoc/recovery-types-voc.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/confvoc/verbosity-types-voc.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/fixed-byte.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/fixed-int.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/fixed-string.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/fixedvocab.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/int.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/longstring.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/nvramrc.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/reboot.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/security.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/standard.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/string.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/vocab-util.fth
bootprom.bin: ${BP}/pkg/confvar/definitions/vocab.fth
bootprom.bin: ${BP}/pkg/confvar/fixed-access.fth
bootprom.bin: ${BP}/pkg/confvar/hashdevice.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/nvalias.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/nvramrc.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/security.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/standard.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/ui-cvars.fth
bootprom.bin: ${BP}/pkg/confvar/interfaces/user-vars.fth
bootprom.bin: ${BP}/pkg/confvar/loadcvar.fth
bootprom.bin: ${BP}/pkg/confvar/nvdevice.fth
bootprom.bin: ${BP}/pkg/console/banner.fth
bootprom.bin: ${BP}/pkg/console/instcons.fth
bootprom.bin: ${BP}/pkg/console/sysconfig.fth
bootprom.bin: ${BP}/pkg/decompressor/data.fth
bootprom.bin: ${BP}/pkg/decompressor/decompress.fth
bootprom.bin: ${BP}/pkg/decompressor/dropin.fth
bootprom.bin: ${BP}/pkg/decompressor/sparc/decomp.fth
bootprom.bin: ${BP}/pkg/dhcp/macaddr.fth
bootprom.bin: ${BP}/pkg/dropins/finder.fth
bootprom.bin: ${BP}/pkg/dropins/loadpkg.fth
bootprom.bin: ${BP}/pkg/dropins/methods.fth
bootprom.bin: ${BP}/pkg/fcode/applcode.fth
bootprom.bin: ${BP}/pkg/fcode/byteload.fth
bootprom.bin: ${BP}/pkg/fcode/chkfcod.fth
bootprom.bin: ${BP}/pkg/fcode/common.fth
bootprom.bin: ${BP}/pkg/fcode/comptokt.fth
bootprom.bin: ${BP}/pkg/fcode/fb-fcodes.fth
bootprom.bin: ${BP}/pkg/fcode/loadfcod.fth
bootprom.bin: ${BP}/pkg/fcode/memtest.fth
bootprom.bin: ${BP}/pkg/fcode/obsfcod0.fth
bootprom.bin: ${BP}/pkg/fcode/obsfcod1.fth
bootprom.bin: ${BP}/pkg/fcode/obsfcod2.fth
bootprom.bin: ${BP}/pkg/fcode/obsfcode.fth
bootprom.bin: ${BP}/pkg/fcode/primlist.fth
bootprom.bin: ${BP}/pkg/fcode/probepkg.fth
bootprom.bin: ${BP}/pkg/fcode/regcodes.fth
bootprom.bin: ${BP}/pkg/fcode/sparc/fcode32.fth
bootprom.bin: ${BP}/pkg/fcode/spectok.fth
bootprom.bin: ${BP}/pkg/fcode/sysprims-nofb.fth
bootprom.bin: ${BP}/pkg/fcode/sysprims.fth
bootprom.bin: ${BP}/pkg/fcode/sysprm64.fth
bootprom.bin: ${BP}/pkg/fcode/vfcodes.fth
bootprom.bin: ${BP}/pkg/fcode/vfcodes/cmn-msg.fth
bootprom.bin: ${BP}/pkg/fcode/vfcodes/sun4v.fth
bootprom.bin: ${BP}/pkg/inet/watchnet.fth
bootprom.bin: ${BP}/pkg/keyboard/usb/support.fth
bootprom.bin: ${BP}/pkg/loadpkg.fth
bootprom.bin: ${BP}/pkg/selftest/selftest.fth
bootprom.bin: ${BP}/pkg/selftest/test.fth
bootprom.bin: ${BP}/pkg/sun4v-asr/attach.fth
bootprom.bin: ${BP}/pkg/sunlogo/logo.fth
bootprom.bin: ${BP}/pkg/termemu/datatype.fth
bootprom.bin: ${BP}/pkg/termemu/fb8.fth
bootprom.bin: ${BP}/pkg/termemu/font.fth
bootprom.bin: ${BP}/pkg/termemu/fontdi.fth
bootprom.bin: ${BP}/pkg/termemu/framebuf.fth
bootprom.bin: ${BP}/pkg/termemu/fwritstr.fth
bootprom.bin: ${BP}/pkg/termemu/install.fth
bootprom.bin: ${BP}/pkg/termemu/loadfb.fth
bootprom.bin: ${BP}/pkg/termemu/sparc/fb8-ops.fth
bootprom.bin: builtin.fth
bootprom.bin: debug.fth
