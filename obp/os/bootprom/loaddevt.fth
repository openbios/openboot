\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loaddevt.fth
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
id: @(#)loaddevt.fth 2.41 05/01/04 22:54:42
purpose:  
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

fload ${BP}/os/bootprom/diagmode.fth	\ Verbosity-controlled output
fload ${BP}/os/bootprom/standini.fth	\ S The first definition of stand-init

headers

\ Create the options vocabulary.  Later, it will become the property
\ list of "options" node in the device tree.

vocabulary options

\ Make the options vocabulary a permanent part of the search order.

only forth also hidden also root also definitions
: fw-search-order  ( -- )  root also re-heads also options also forth also  ;
' fw-search-order to minimum-search-order
only forth hidden also forth also definitions

fload ${BP}/os/bootprom/propenc.fth	\ Property encoding primitive
fload ${BP}/os/bootprom/sparc/instance.fth
fload ${BP}/os/bootprom/devtree.fth	\ Device node creation

fload ${BP}/os/bootprom/breadth.fth	\ Device tree search primitives

fload ${BP}/os/bootprom/finddev.fth	\ Device tree path lookup

fload ${BP}/os/bootprom/devpaths.fth	\ Device tree path extraction

fload ${BP}/os/bootprom/testdevt.fth	\ Device tree browsing
fload ${BP}/os/bootprom/showlocation.fth \ show-fru-location command
fload ${BP}/os/bootprom/relinkdt.fth	\ Devtree hooks for "dispose"

fload ${BP}/os/bootprom/instance.fth	\ Package ops

fload ${BP}/os/bootprom/comprop.fth	\ "Prepackaged" property words

fload ${BP}/os/bootprom/finddisp.fth	\ Locate first "display" device

fload ${BP}/os/bootprom/sysnodes.fth	\ Standard system nodes

fload ${BP}/os/bootprom/console.fth	\ Forth I/O through package routines

fload ${BP}/os/bootprom/trace.fth	\ Package tracing tool

fload ${BP}/os/bootprom/execall.fth	\ execute-all-methods command

fload ${BP}/os/bootprom/siftdevs.fth	\ Sifting through the device tree

fload ${BP}/os/bootprom/eject.fth	\ Generic EJECT command

fload ${BP}/os/bootprom/showdisk.fth	\ Generic show-disks show-nets etc. commands.

fload ${BP}/os/bootprom/malloc.fth	\ Heap memory allocator
fload ${BP}/os/bootprom/instmall.fth	\ SI Hack installation

fload ${BP}/os/bootprom/alarm.fth	\ Alarm interrupt mechanism

fload ${BP}/os/bootprom/deladdr.fth	\ Remove "address" property
fload ${BP}/os/bootprom/mapdev.fth	\ Map from devtree node
fload ${BP}/os/bootprom/fwfileop.fth	\ Forth file access through device tree

only forth also definitions

hex

fload ${BP}/os/bootprom/execbuf.fth	\ execute-buffer

fload ${BP}/os/stand/probe.fth          \ Probe, peek, poke
