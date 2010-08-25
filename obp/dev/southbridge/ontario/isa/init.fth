\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: init.fth
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
id: @(#)init.fth 1.1 06/02/16 
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

fload ${BP}/dev/southbridge/isa/registers.fth
fload ${BP}/dev/southbridge/isa-devices/superio/registers.fth

headerless

h# 0600  constant smb-base
h# 0800  constant acpi-base

\ This used to be done in Fiesta's Reset, now it's done here...

\ Extract Southbridge's bus number for back-door access to PMU and IDE config space
my-space h# ff0000 and h#  800 or constant pmu-config-base
my-space h# ff0000 and h# 4000 or constant ide-config-base

: sbr! swap my-space        or config-b! ;  \ Initialize ISA
: pmu! swap pmu-config-base or config-b! ;  \ Initialize PMU, Device 1
: ide! swap ide-config-base or config-b! ;  \ Initialize IDE, Device 8

: init-sb ( -- )
   h# 40  h# 11	sbr!		\ DMA line buffer enable, Passive release enable
   h# 58  h# 00	sbr!		\ IDE disable - WORKAROUND is RESET IDE
   h# 4a  h# 00	sbr!		\ Disable USB2 - WORKAROUND
   h# 7e  h# 01	sbr!		\ Disable USB2, Audio > 2GB WORKAROUND
   h# 53  h# 40	sbr!		\ Disable USB1 - WORKAROUND
   h# 42  h# 4b	sbr!		\ 32-bit DMA addressing; ISA SYSCLK = PCICLK/4 (apnote5)
   h# 44  h# 83	sbr!		\ Primary IDE IRQ[10]
   h# 45  h# 08 sbr!            \ Parity check disable; Enable discard timer timeout
   h# 48  h# 00	sbr!		\ PCI Interrupt routing table 1 (PIRT1)
   h# 49  h# 00	sbr!		\ PIRT2
   h# 4a  h# 06	sbr!		\ USB2 [IRQ 7] in APIC mode (see apnote 7)
   h# 4b  h# 00	sbr!		\ PIRT4; Audio interrupt DISABLE
   h# 50  h# 00	sbr!		\ Parity check control (low)
   h# 51  h# 00	sbr!		\ Parity check control (high)
   h# 52  h# 00 sbr!		\ USB control (low)
   h# 53  h# 20	sbr!		\ USB1 enable; RTC port read enable
   h# 58  h# 64	sbr!		\ IDE enable; IDSEL=A24; keep secondary IDE tri-state
   h# 5f  h# 08	sbr!		\ Unlock bits[9:4] of M1535D command register (0x4)
   h# 6c  h# 80	sbr!		\ Enable "discreet interrupt" mode (NEW. Was h# 80)
   h# 6d  h# 20	sbr!		\ Release PCI bus on ISA/DMA Master cycle retry
   h# 72  h# 0a	sbr!		\ PMU IDSEL=A17; USB IDSEL=A21
   h# 74  h# 47	sbr!		\ USB1 [IRQ 6]
   h# 76  h# 00	sbr!		\ ACPI Intterupt routing table
   h# 77  h# 48	sbr!		\ Audio disabled, Modem disabled
   h# 7d  h# 80 sbr!		\ USB2 IDSEL=A22
   h# 7e  h# 80 sbr!		\ USB2 Enable

   h# 79  h# 02	sbr!		\ Multifunction pin select 2 (CHECK THIS)
   h# 7a  h# 00	sbr!		\ Multifunction pin select 2 (CHECK THIS)
   h# 7b  h# 04	sbr!		\ Multifunction pin select 2 (CHECK THIS)
   h# 7c  h# 00	sbr!		\ Multifunction pin select 3 (CHECK THIS)

;

: init-pmu ( -- )
   h# e0  acpi-base h# ff and pmu!
   h# e1  acpi-base 8 >> h# ff and pmu!	\ ACPI @ PCI I/O 0500

   h# e2  smb-base h# ff and pmu!
   h# e3  smb-base 8 >> h# ff and pmu!	\ SMB  @ PCI I/0 0600

   h# d1  h# 06 pmu!		\ Enable SMB & ACPI address spaces
   h# f0  h# 41 pmu!		\ Enable SMB Host controller
   h# f0  h# 05 pmu!		\ Enable SMB Host controller, I2C mode
   h# f2  h# 20 pmu!		\ SMB clock
   h# f2  h# 88 pmu!		\ SMB clock XXXX

   h# bb  h# 03	pmu!		\ GPO 36 & 37
   h# ba  h# 00	pmu!		\ GPO36 = 0 (flash WE)

   h# 6c  h# 00 pmu!		\ System events
   h# 6d  h# 00 pmu!		\ System events
   h# 6e  h# 40 pmu!		\ Floppy event on grover (CHECK THIS)
   h# 6f  h# 01 pmu!		\ Floppy event on grover (CHECK THIS)

   h# 70  h# 0f pmu!		\ Positive Decoding ranges (CHECK THIS) 
   h# 71  h# 11 pmu!		\ (CHECK THIS)

   h# 77  h# 08 pmu!		\ Enable SMI
   h# b1  h# 40 pmu!		\ Enable emergency OFF
   h# b3  h# 04	pmu!		\ LED on (SPLED drives lo), pwr btn overide disable
   h# b2  h# 40 pmu!		\ Enable Beep


   h# 89  h# 02 pmu!		\ RMC_RST (GPO39) output
   h# 9a  h# 0f	pmu!		\ RMC_HRT_BT (GPO0), SB_PROM_A20 (GPO1), 
				\ FLASH_UPDATE (GPO2), FAN_BLAST_N (GPO3)
;

: init-ide ( -- )
   h# 09  h# ff ide!
   h# 10  h# 00 ide!
   h# 11  h# 00 ide!
   h# 12  h# 00 ide!
   h# 13  h# 00 ide!
   h# 14  h# 00 ide!
   h# 15  h# 00 ide!
   h# 16  h# 00 ide!
   h# 17  h# 00 ide!
   h# 18  h# 00 ide!
   h# 19  h# 00 ide!
   h# 1a  h# 00 ide!
   h# 1b  h# 00 ide!
   h# 1c  h# 00 ide!
   h# 1d  h# 00 ide!
   h# 1e  h# 00 ide!
   h# 1f  h# 00 ide!
   h# 20  h# 00 ide!
   h# 21  h# 00 ide!
   h# 22  h# 00 ide!
   h# 23  h# 00 ide!
   h# 43  h# 7f ide!
   h# 4a  h# 03 ide!
   h# 4b  h# c0 ide!
   h# 4d  h# 80 ide!
   h# 50  h# 03 ide!
   h# 53  h# 81 ide!
   h# 54  h# 55 ide!
   h# 55  h# 55 ide!
   h# 56  h# 44 ide!
   h# 57  h# 44 ide!
   h# 58  h# 03 ide!
   h# 5c  h# 03 ide!
   h# 72  h# 00 ide!
   h# 7a  h# 00 ide!
   h# 79  h# 02 ide!
;

: init-superio  ( -- )
   enter-cfg-mode
 
   0 devsel
   h# 0  h# 30  sio!                    \ Disable FDC by default
[ifdef] use-floppy?
   0 devsel                             \ FDC
   h# 1 h# 30 sio!                      \ Enable FDC
   h# 6 h# 70 sio!                      \ IRQ 6
   h# 2 h# 74 sio!                      \ DMA channel 2
   h# a h# f0 sio!                      \ AT mode; Non-burst DMA mode
[then]   

   3 devsel
   h# 0  h# 30  sio!                    \ Disable parallel port by default
[ifdef] use-parallel-port?
   3 devsel                             \ Parallel port
   h# 1 h# 30 sio!                      \ Enable parallel port
   h# 7 h# 70 sio!                      \ IRQ 7
   h# 1 h# 74 sio!                      \ DMA channel 1
   h# 8a h# f0 sio!                     \ IRQ active low; ECP; FIFO threshold = 1
[then]   

   4 devsel                             \ UART 1
   h# 3 h# 60 sio!                      \ I/O base address high
   h# f8 h# 61 sio!                     \ I/O base address low

   \ On the Ontario OIO board, the interrupt for UART 1 device in the Southbridge 
   \ was wired to use IRQ 3 on P0.1b and older systems. On P0.2, P1, and forward, 
   \ it is wired to use IRQ1. These are also the boards with the swapped device 
   \ positioning, so we can key off of what 'my-space' value the Southbridge comes 
   \ up as. This is hack code which can be removed when we decomission support of P0.1 
   \ systems.
   my-space h# 51000 = if
      h# 1 h# 70 sio!                   \ IRQ 1
   else
      h# 3 h# 70 sio!                   \ IRQ 3
   then

   h# 1 h# 30 sio!                      \ Enable UART 1
   h# 2 h# f0  sio!                     \ High speed mode

   5 devsel                             \ UART 2
   h# 0 h# 30 sio!                      \ Disable UART 2

   7 devsel                             \ Keyboard
   h# 0 h# 30 sio!                      \ Disable Keyboard

   h# b devsel                          \ UART 3
   h# 0 h# 30 sio!                      \ Disable

   h# 0c devsel                         \ Hotkey
   h# 0 h# 30 sio!                      \ Disable

   exit-cfg-mode
;

: init-dma ( -- )
   h# 07  h# 0d pcio!		\ Write Master Clear Reg.
   h# 07  h# 0e pcio!		\ Clear Mask Reg

   \ Mask controller 1
   h# 04  h# 0a pcio!		\ Mask Set/Reset Register
   h# 05  h# 0a pcio!
   h# 06  h# 0a pcio!
   h# 07  h# 0a pcio!
   h# 08  h# 08 pcio!
   \ Enable and set mode for DMA channel 4
   h#  0  h# d4 pcio!		\ Mask  Set/Reset Reg.
   h# c0  h# d6 pcio!		\ Mode Reg.
;

: init-acpi ( -- )
   h# ffff  acpi-base isa-base +         rw!
[ifdef] no-power-smi?
   h# 0400  acpi-base isa-base + h#  2 + rw!
[else]
   h# 0500  acpi-base isa-base + h#  2 + rw!
[then]
;

alias pic! pcio!
hex

init-sb init-pmu init-ide                \ Init southbridge, pmu, ide

map-regs
 init-dma init-acpi init-superio         \ Init dma, acpi, superio
unmap-regs 

