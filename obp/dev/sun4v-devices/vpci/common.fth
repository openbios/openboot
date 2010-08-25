\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 1.1 06/02/16 
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

fload ${BP}/dev/utilities/swapped-access.fth
fload ${BP}/dev/utilities/misc.fth
fload ${BP}/dev/utilities/shifter.fth
fload ${BP}/dev/utilities/cif.fth

h# 2000                 value pagesize
alias mmu-pagesize pagesize
pagesize invert 1+      value page#mask
h# d                    value pageshift
d# 43                   value #pabits   \ Number of physical address bits
1 #pabits lshift 1-     value pa-mask
h# 100000               constant 1meg
variable pci-memlist    pci-memlist off
variable pci-io-list    pci-io-list off
0 value  bar-struct-addr

fload ${BP}/dev/utilities/memlist.fth
depend-load DEBUGGING? ${BP}/dev/utilities/memlistdebug.fth
fload ${BP}/dev/pci/debug.fth
fload ${BP}/dev/pci/cfgio.fth
fload ${BP}/dev/pci/memstack.fth

depend-load DEBUGGING? ${BP}/dev/psycho/memdebug.fth

\ Where we find the bootprom driver resources.
: builtin-drivers " SUNW,builtin-drivers" ;

defer claim	0 " claim" do-cif is claim
defer release	0 " release" do-cif is release
