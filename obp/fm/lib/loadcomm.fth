id: @(#)loadcomm.fth 1.13 03/12/11 09:22:50
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Use is subject to license terms.

transient fload ${BP}/fm/lib/xref.fth resident
fload ${BP}/fm/lib/th.fth

transient fload ${BP}/fm/lib/filetool.fth resident
			\ needed for dispose, savefort.fth
transient fload ${BP}/fm/lib/dispose.fth resident

transient fload ${BP}/fm/lib/showspac.fth resident

\

fload ${BP}/fm/lib/chains.fth

fload ${BP}/fm/lib/patch.fth
\ fload ${BP}/fm/kernel/hashcach.fth

headers transient   alias  headerless0  headers   resident

fload ${BP}/fm/lib/ansiterm.fth

fload ${BP}/fm/lib/strings.fth

fload ${BP}/fm/lib/fastspac.fth

fload ${BP}/fm/lib/cirstack.fth		\ Circular stack
fload ${BP}/fm/lib/pseudors.fth		\ Interpretable >r and r>

fload ${BP}/fm/lib/headtool.fth

transient  fload ${BP}/fm/lib/needs.fth  resident

fload ${BP}/fm/lib/suspend.fth

fload ${BP}/fm/lib/util.fth
fload ${BP}/fm/lib/format.fth

fload ${BP}/fm/lib/stringar.fth

fload ${BP}/fm/lib/parses1.fth	\ String parsing

fload ${BP}/fm/lib/split.fth

fload ${BP}/fm/lib/dump.fth
fload ${BP}/fm/lib/words.fth
fload ${BP}/fm/lib/decomp.fth

\ Uses  over-vocabulary  from words.fth
transient fload ${BP}/fm/lib/dumphead.fth  resident

fload ${BP}/fm/lib/seechain.fth

fload ${BP}/fm/lib/loadedit.fth		\ Command line editor module

fload ${BP}/fm/lib/caller.fth

fload ${BP}/fm/lib/callfind.fth
fload ${BP}/fm/lib/substrin.fth
fload ${BP}/fm/lib/sift.fth

fload ${BP}/fm/lib/array.fth

fload ${BP}/fm/lib/linklist.fth		\ Linked list routines

fload ${BP}/fm/lib/initsave.fth		\ Common code for save-forth et al
