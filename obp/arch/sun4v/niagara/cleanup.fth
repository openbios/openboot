\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cleanup.fth
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
id: @(#)cleanup.fth 1.2 06/05/10
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

[ifdef] trace-errors
: xbp
   [ also hidden ]
   .registers cr
   ftrace cr
   hex
   (handle-breakpoint
;
' xbp is handle-breakpoint
: real-bp  ( -- )
   [ also hidden ]  ['] (handle-breakpoint is handle-breakpoint  [ previous ]
;
[then]

' (cold-hook is cold-hook

\ This stand-init-io has a header, in case the previous one does not.
chain: finalize-chain ( -- )  here fence a! ;
overload: execute-buffer ( adr,len -- )  execute-buffer  ;
overload: stand-init    ( -- )
   stand-init finalize-chain
   ['] startup catch ?dup if .error  then
;
overload: stand-init-io ( -- )  stand-init-io  ;
overload: unix-init     ( -- )  unix-init  ;
overload: unix-init-io  ( -- )  unix-init-io  ;
overload: init          ( -- )  init  ;

\ Make sure these words are available at the ok prompt
\ Unfortunately, wanboot ramdisk depends on them.
overload: headers ;
overload: headerless ;
overload: external ;

\ Install the various boot chains
' check-machine-state is check-machine-chain
' don't-boot? is interrupt-auto-boot?
' client-starting is client-starting-chain
' client-exited is client-exited-chain

\ Install the entry/exit/reset chains now
' enterforth-chain is enterforth-hook
' go-chain	   is go-hook

origin " origin" $export-procedure

hidden definitions
: voc-unlink ( acf -- )
   >r  voc-link  begin  dup another-link?  while  ( prev next )
      dup  r@ =  if               ( prev next )
	 >voc-link link@ swap link!  r> drop exit
      else                        ( prev next )
	 nip                      ( next )
      then  >voc-link             ( next-voc )
   repeat  r> drop                (  )
;
previous definitions

[ifndef] assembler?
also hidden
\ Turn off the assembler; it is about to be disposed
' noop is do-entercode
' noop is do-exitcode
' noop is do-label-hook
' nulldis is disassemble
previous
[then]
resident

\ Align dp to 16 bytes .
here h# 10 round-up here - 0 ?do h# ff c, loop
\ Align the User Area size to 16 bytes
#user @ h# 10 round-up #user !

dictionary-size               to ROM-dictionary-size
ROMbase ROM-dictionary-size + to text-end
warning on

\ Supress file notification warnings for dup defs for runtime.
patch noop where duplicate-notification

\ remove the forth->system error interface
patch 2drop fsyscall (compile-time-error)
patch 2drop fsyscall (compile-time-warning)

dispose 0 0 set-transize

also hidden also forth
' boolean-voc voc-unlink
' recovery-types voc-unlink
' security-mode-voc voc-unlink
' hidden voc-unlink
' trap-types voc-unlink
' keys-forth voc-unlink
' disassembler voc-unlink
' command-completion voc-unlink
' allocator voc-unlink
' bug voc-unlink
' aliases voc-unlink
' options voc-unlink
forth

' noop is title         \ Turn off the Bradley Forthware copyright message

\ XREF does not generate a stand.dic, this magic takes care of it.
\ If SAVEFILE is not [define]'d then we dont save an image.
\ 
" SAVEFILE" d# 55 d# 45 fsyscall dup 0= if  2drop  else
   "" stand.dic save-forth
   patchboot
   #user @		origin h# 10 + x!
   here origin-		origin h# 18 + x!
   text-end		origin h# 20 + x!
   " stand-init-io"	$find-name is init-io
   " stand-init"	init-save
   up@          #user @	2swap			( up,len file$ )
   origin	here	over -	2swap		( up,len dic,len file$ )
   d# 45 d# 45 fsyscall				( )
then

warning off

fload ${BP}/pkg/fcode/chkfcod.fth
