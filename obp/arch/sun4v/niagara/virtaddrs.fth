\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: virtaddrs.fth
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
id: @(#)virtaddrs.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headers
transient
alias low-base 0
alias low-size 0
resident

headerless
h#  fff.0000       constant monvirtsize  \ Size of monitor's virtual memory
h# F000.0000       constant monvirtbase  \ Base of monitor's virtual memory

monvirtbase 2meg + constant ROMbase
ROMbase ROMsize +  constant ROMtop

\ Heap size includes the temporary RS/DS stacks used before we can alloc
\ the per-cpu stacks.
h#    8.0000	   constant RAMsize		\ Increase RAMsize to 512K
h#    1.0000	   constant RAMsize-start	\ Initial RAM for heap/user
h#      8000	   constant HEAPsize		\ Initial Heap size

monvirtbase monvirtsize +
                   constant RAMtop	\ top of RAM
RAMtop  RAMsize -  constant RAMbase

1 #vabits 1- <<    constant hole-start
hole-start negate  constant hole-end

1meg d# 16 * dup 1meg - 	constant mondvmasize	\ Size of DVMA space
monvirtbase monvirtsize + swap round-down constant mondvmabase	\ DVMAbase

\ The value of ROM-dictionary-size will be patched later
\ It must have a header, because it's needed by (cold-hook after dispose
headers
0 constant ROM-dictionary-size
0 constant text-end

headerless
ROMbase  constant trap-table	\ trap vectors

RAMbase HEAPsize + constant prom-main-task

: RAM-dictionary-base  ( -- adr )  ROM-dictionary-size origin+  ;
: initial-limit  ( -- adr )  4meg origin+  ;

\t32 8meg constant /dictionary-max
\t16 h#  1.0000 tshift << constant /dictionary-max

\ Assuming user-area > origin
: dictionary-top  ( -- adr )  /dictionary-max origin+  up0 @  umin  ;

0 constant di-offset	\ Drop-in offset

headers
nuser hi-memory-base hi-memory-base  off
nuser hi-memory-size hi-memory-size  off

headers
