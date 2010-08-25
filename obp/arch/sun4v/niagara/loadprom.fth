\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadprom.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)loadprom.fth 1.6 06/05/23
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

decimal
warning off
caps on

\ Niagara Load File
transient

\ Variables controlling inclusion of optional packages.

[define] assembler?

fload debug.fth

resident

fload ${BP}/os/unix/simforth/findnext.fth

fload ${BP}/fm/lib/loadcomm.fth	\ Generic CPU-independent Forth tools
fload ${BP}/os/sun/sparc/loadmach.fth	\ CPU and OS-specific extensions
fload ${BP}/os/sun/sparc/loadfw.fth	\ Platform-independent Open Firmware

fload ${BP}/arch/sun4v/hfcodes.fth
fload ${BP}/arch/sun4v/mdscan.fth
fload ${BP}/pkg/fcode/vfcodes/sun4v.fth

\ ===========================================================================
\ Up to this point, we haven't loaded any machine-dependent code

fload ${BP}/arch/sun4v/niagara/sysinfo.fth

d# 256 1meg * constant 256meg
d# 128 1meg * constant 128meg
d#  64 1meg * constant  64meg
d#  16 1meg * constant  16meg
d#   8 1meg * constant   8meg
d#   4 1meg * constant   4meg
d#   2 1meg * constant   2meg

h# 8.0000 constant ROMsize

alias obmem 0
alias obio 0

fload ${BP}/cpu/sparc/ultra4v/loadultra.fth

fload ${BP}/arch/sun4v/hyperconsole.fth

fload ${BP}/arch/sun4v/niagara/virtaddrs.fth
fload ${BP}/os/bootprom/loadlist.fth	\ S Virtual, physical memory allocators
fload ${BP}/os/bootprom/availmem.fth
fload ${BP}/arch/sun4v/ramforth.fth	\ S Ramforth
fload ${BP}/os/bootprom/allocmor.fth
fload ${BP}/os/bootprom/msgbuf.fth

fload ${BP}/arch/sun4v/api-group-id.fth
fload ${BP}/arch/sun4v/niagara/hv-apis.fth
fload ${BP}/arch/sun4v/api-version.fth

fload ${BP}/arch/sun4v/mdload.fth
fload ${BP}/arch/sun4v/devalias.fth	\ S PD devalias import

fload ${BP}/arch/sun4s/reentry-table.fth
fload ${BP}/arch/sun4v/cpustruct.fth	\ S Allocate cpu structs

stand-init: Extract cpu config bits from PD
   " cpu" pd-rootnode pdfind-node >r
   " mmu-max-#tsbs" 2dup -1 r@ pdget-prop ?dup if
      r> ['] max-#tsb-entries pdget-required-property
   else
      2drop " max-#tsb-entries" r> ['] max-#tsb-entries pdget-required-property
   then
;

fload ${BP}/cpu/sparc/ultra4v/savecpu.fth

fload ${BP}/arch/sun4u/asmmacros.fth
fload ${BP}/arch/sun4v/catchexc.fth	\ S pssave and rssave
fload ${BP}/arch/sun4v/mmumiss.fth

fload ${BP}/arch/sun4v/mapdi.fth	\ Mapping for drop-in drivers
fload ${BP}/os/bootprom/dropin.fth	\ Drop-in driver support
fload ${BP}/pkg/decompressor/dropin.fth

fload ${BP}/arch/sun4u/trans.fth
fload ${BP}/arch/sun4u/traptable.fth
fload ${BP}/arch/sun4u/fieldberr.fth    \ Bus error handler for probing

fload ${BP}/os/bootprom/pdump.fth	\ physical dump

fload ${BP}/os/stand/sysuart.fth

fload ${BP}/cpu/sparc/ultra4v/tlbasm.fth
fload ${BP}/arch/sun4v/niagara/tlbsetup.fth
fload ${BP}/arch/sun4v/fastfill.fth

fload ${BP}/arch/sun4u/arcbpsup.fth	\ S Arch-dependent breakpoint support
fload ${BP}/arch/sun4u/reenter.fth	\ S Getting back to Forth from Unix

fload ${BP}/arch/sun/model.fth		\ /openprom model and version props.

fload ${BP}/arch/sun4s/msloop.fth		\ Delays of n milliseconds
fload ${BP}/arch/sun4v/machine-init.fth
fload ${BP}/arch/sun4v/forthint.fth		\ S alarm trap handler

fload ${BP}/arch/sun4u/slavecpu.fth

fload ${BP}/arch/sun4v/hslave.fth

fload ${BP}/arch/sun4v/niagara/boot.fth	\ SI startup code

fload ${BP}/arch/sun4v/xcall.fth

fload ${BP}/arch/sun4u/startcpu.fth
fload ${BP}/arch/sun4u/switchcpu.fth

fload ${BP}/arch/sun4u/quark/le-access.fth	\ little endian access code.
fload ${BP}/dev/builtin.fth

fload ${BP}/arch/sun4v/mondo.fth

stand-init: Loading Support Packages
   diagnostic-mode? if
      ." Loading Support Packages: "
   then
   " support-pkg" do-drop-in
   diagnostic-mode? if  cr  then
;

stand-init: Loading Builtin Devices
   " onboard-devices" ['] builtin-drivers-package find-method if
      execute
   then
;

fload ${BP}/arch/sun4v/niagara/loadconfig.fth
' diag-switch? is diagnostic-mode?

stand-init: Track firmware verbosity
   " verbosity" ['] options search-wordlist if
      get to fw-verbosity
   then
;

fload ${BP}/arch/sun4v/memprobe.fth		\ S memory sizer

fload ${BP}/os/bootprom/scrubmem.fth

fload ${BP}/arch/sun/idprom.fth                 \ IDPROM layout
fload ${BP}/arch/sun/keystore.fth               \ Security keystore

headers

: get-board-part# ( -- adr,len )
   " root" 0 pdfind-node drop
   " board-part#" PROP_STR -1 pdget-prop ?dup if
      pdentry-data@
   else
      ." WARNING: missing board-part# from PD" cr
      " 000-000-000"
   then
;
: bzero-region  ( va len -- ) 2drop  ;
: btouch-region ( va len -- ) 2drop  ;

fload ${BP}/pkg/keyboard/usb/support.fth

fload ${BP}/arch/sun4j/nvram-personality.fth

\ Force a map of the drop-in ROM
stand-init: direct-open-drop-in
   direct-open-drop-in drop
;

stand-init: cpu-devices-
   " cpu-devices-" do-drop-in
;

fload ${BP}/pkg/fcode/obsfcode.fth

fload ${BP}/arch/sun4u/retained.fth             \ S retained memory allocator

fload ${BP}/arch/sun4v/rootnexus.fth

fload ${BP}/dev/pci/knownprops.fth

stand-init: cpu-devices+
   " cpu-devices+" do-drop-in
;

0 value xir-reset?			\ XXXX

fload ${BP}/cpu/sparc/init-c9.fth	\ S Init. C Stack Pointer

fload ${BP}/arch/sun4u/starthacks.fth	\ XXXX

fload ${BP}/arch/sun4u/unixmap.fth	\ MMU initialization

fload ${BP}/arch/sun4u/reboot.fth	\ S Reboot Info
fload ${BP}/arch/sun4u/power-off.fth	\ S Power-off client service
fload ${BP}/arch/sun4u/consredir.fth

\ Packages
fload ${BP}/pkg/loadpkg.fth
fload ${BP}/pkg/dropins/loadpkg.fth

fload ${BP}/pkg/selftest/selftest.fth

\ modify banner to display available rather than installed memory
: .memory-available ( -- ) ."  memory available" ;
' .memory-available is .memory-install-msg

fload ${BP}/arch/sun4v/niagara/probeall.fth

fload ${BP}/dev/scsi/probescsi.fth      \ probe-scsi
fload ${BP}/pkg/inet/watchnet.fth	\ watch-net
fload ${BP}/dev/ide/probe.fth		\ probe-ide

fload builtin.fth

true value system-test-ok?
alias post-ok? true
alias system-tests noop

fload ${BP}/arch/sun4u/startup.fth \ S misc. startup stuff
\ Create slot-names properties.
[ifdef] Ontario
[ifdef] Pelton
   \ Pelton slot-names
   fload ${BP}/arch/sun4v/pelton/slot-names-props.fth
[else]
   \ Ontario slot-names here
[then]
[then]

fload ${BP}/arch/sun4v/auto-boot-on-error.fth
fload ${BP}/arch/sun4v/niagara/bootscript.fth

headers

fload ${BP}/arch/sun4v/console-tty.fth
depend-load Erie ${BP}/arch/sun4v/erie/local-mac-addr.fth

depend-load Erie ${BP}/arch/sun4v/erie/intrmap.fth

headerless
fload ${BP}/arch/sun4v/niagara/cleanup.fth
