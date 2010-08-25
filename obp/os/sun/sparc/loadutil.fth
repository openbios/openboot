\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadutil.fth
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
\ id: @(#)loadutil.fth 2.30 03/12/11 09:22:53
\ purpose: to make forth.exe
\ copyright: Copyright 1991-2003 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

warning off

only forth also definitions

decimal

true value command-completion?

fload ${BP}/fm/lib/copyrigh.fth

fload ${BP}/fm/lib/transien.fth
decimal limit origin- 5 / aligned  1000 set-transize

fload ${BP}/fm/lib/headless.fth
fload ${BP}/fm/lib/brackif.fth

transient fload ${BP}/fm/kernel/sparc/loadsyms.fth resident


\ \dtc 64\ fload ${BP}/os/unix/simforth/findnext.fth

transient fload ${BP}/fm/lib/stubs.fth  resident
			\ for filetool.fth and alias.fth

fload ${BP}/fm/lib/filetool.fth
			\ needed for dispose, savefort.fth

transient fload ${BP}/fm/lib/dispose.fth  resident
transient fload ${BP}/fm/lib/showspac.fth resident
fload ${BP}/fm/lib/chains.fth
: headerless0 headers ;

headers

fload ${BP}/fm/lib/th.fth
fload ${BP}/fm/lib/patch.fth
\ fload ${BP}/fm/kernel/hashcach.fth		\ FIND CACHE
fload ${BP}/fm/lib/strings.fth
fload ${BP}/fm/lib/suspend.fth
fload ${BP}/fm/lib/util.fth
fload ${BP}/fm/lib/format.fth

fload ${BP}/fm/lib/cirstack.fth
fload ${BP}/fm/lib/pseudors.fth
fload ${BP}/fm/lib/headtool.fth
fload ${BP}/fm/lib/needs.fth
fload ${BP}/fm/lib/stringar.fth

fload ${BP}/fm/lib/split.fth

fload ${BP}/fm/lib/dump.fth
fload ${BP}/fm/lib/words.fth
fload ${BP}/fm/lib/decomp.fth

fload ${BP}/fm/lib/seechain.fth
fload ${BP}/fm/lib/loadedit.fth

fload ${BP}/fm/lib/caller.fth
fload ${BP}/fm/lib/callfind.fth
fload ${BP}/fm/lib/substrin.fth
fload ${BP}/fm/lib/sift.fth

fload ${BP}/fm/lib/array.fth
fload ${BP}/fm/lib/linklist.fth
fload ${BP}/fm/lib/initsave.fth

fload ${BP}/cpu/sparc/assem.fth
fload ${BP}/cpu/sparc/code.fth
fload ${BP}/cpu/sparc/asmmacro.fth
fload ${BP}/fm/lib/loclabel.fth
fload ${BP}/cpu/sparc/disforw.fth
fload ${BP}/cpu/sparc/ultra/impldis.fth
fload ${BP}/fm/lib/instdis.fth
fload ${BP}/fm/lib/sparc/decompm.fth
fload ${BP}/os/stand/sparc/notmeta.fth
fload ${BP}/fm/lib/sparc/bitops.fth

fload ${BP}/fm/cwrapper/binhdr.fth
fload ${BP}/fm/cwrapper/sparc/savefort.fth
fload ${BP}/cpu/sparc/doccall.fth

\t16 fload ${BP}/fm/lib/sparc/debugm16.fth
\t32 fload ${BP}/fm/lib/sparc/debugm.fth

fload ${BP}/fm/lib/debug.fth

32\ fload ${BP}/cpu/sparc/traps.fth
64\ fload ${BP}/cpu/sparc/traps9.fth

fload ${BP}/fm/lib/sparc/objsup.fth
fload ${BP}/fm/lib/objects.fth
fload ${BP}/cpu/sparc/cpustate.fth

32\ fload ${BP}/cpu/sparc/register.fth
64\ fload ${BP}/cpu/sparc/register9.fth


fload ${BP}/fm/lib/savedstk.fth
fload ${BP}/fm/lib/rstrace.fth
fload ${BP}/fm/lib/sparc/ftrace.fth

32\ fload ${BP}/fm/lib/sparc/ctrace.fth
64\ fload ${BP}/fm/lib/sparc/ctrace9.fth

fload ${BP}/fm/lib/sparc/cpubpsup.fth
fload ${BP}/fm/lib/breakpt.fth

fload ${BP}/cpu/sparc/call.fth

headerless
alias lretval retval
fload ${BP}/os/sun/sparc/signal.fth
fload ${BP}/os/sun/sparc/catchexc.fth
fload ${BP}/os/unix/sparc/arcbpsup.fth

fload ${BP}/fm/lib/version.fth

headers
alias lvariable variable
: unix-init-io ( -- )  unix-init-io  ;
: unix-init    ( -- )  unix-init  ;
: init ( -- )  init  ;

dispose 0 0 set-transize

[ifndef] dic-file-name
-1 abort" ERROR: dic-file-name is not defined, Can't save"
[then]
[defined] dic-file-name dup 1+ alloc-mem pack save-forth
