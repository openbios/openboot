\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: startup.fth
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
id: @(#)startup.fth 1.25 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ The latter part of the initialization sequence.

headers
alias  cd  dev
overload: probe-all  ( -- )
   " probe-" do-drop-in
   probe-all
   " probe+" do-drop-in
;

headerless
: delete-fb-prop ( -- )
   root-device
      " fb" 2dup get-property 0=  if
	 2swap delete-property
      then  2drop
   device-end
;

: setup-memory  ( -- )
   ecc-off  ce-off
   " scrub-memory" memory-node @  ['] $call-method  catch drop
   ecc-on   ce-on
   map-for-unix
;

: ?cleanup  ( -- )
   \ If the selftest code was interrupted,
   \ the interrupt registers could
   \ be in the wrong state
   \ (i.e. pil=9, interrupt-enable=21).

   monitor-interrupt-state

   %o6@ c-stack <>  if  init-c-stack  then
   setup-memory
;
' ?cleanup is cleanup

variable banner-done?  banner-done? off

\ Service brk char only if diag-switch?=true or OBP banner is up
: (startup-abort)  ( -- )
   diagnostic-mode? banner-done? @ or  if
     (user-abort)
   then
;
' (startup-abort) is user-abort

stand-init: Executing NVRAMRC
   execute-nvramrc
   auto-banner?  if
      probe-all install-console
      output-device fallback-device $=  0=  if
	 \ show tty msgs only if console <> ttya
         show-tty-msgs
      then
      ?banner
   then
   banner-done? on
   delete-fb-prop
;

headerless
\ Be carefull, this chain is supposed to return a flag!
\ by the time your first token runs someone else has already left the
\ current state on the stack for you to consider.
chain: don't-boot?  ( flag -- flag' )
   idprom-valid? system-test-ok? and
   post-ok? and  0= or
;

defer pre-boot-hook  ' noop is pre-boot-hook

: startup  ( -- )
   hex
   warning on
   only forth also definitions

   startup-hook

   #line off

   \ Perform OBDiag tests if this is a power-on
   \ and not a reboot
   reboot? 0=  if
      system-tests
   then

   check-machine-chain ?cr
   setup-memory

[ifdef] DakASR?				\ Daktari-style ASR/Diag-status handling
   restore-obd-fail-status              \ Populate device tree with diag status
   restore-asr-disable-status           \ Populate device tree with ASR status
[then]

   false to init-incomplete?		\ OK to [try to] boot

   pre-boot-hook
   auto-boot
;

headerless
: ok> ( -- ) ." ok> " ;

chain: unix-init ( -- )
   hex  ['] ok> is (ok)
   \ Running stand.exe
   ." # " obp-release ". space sub-release ".  space .compile-date  cr
   ['] false to idprom-valid?  ['] 2drop to do-drop-in
;
headers
