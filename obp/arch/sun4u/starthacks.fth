\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: starthacks.fth
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
id: @(#)starthacks.fth 1.11 05/04/08
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

also hidden also

headerless
: monitor-interrupt-state  ( -- )
   \ I bet we get an interrupt right now
   restartable? @  0=  if
      h# 0d pil! ]unlock
   then
;
: client-interrupt-state  ( -- )
;

\ Actions to perform in order to recover from an error reset
defer error-reset-cleanup ' noop is error-reset-cleanup

: safe-execute  ( method-name ihandle -- )
   ?dup  if                       ( method$ ihandle )
      ['] $call-method catch  if  ( method$ ihandle )
	 3drop                    (  )
      then                        (  )
   else                           ( method$ )
      2drop
   then
;

\ This turns on the screen in case the screen went blank as the result
\ of an error reset.  Some SBus frame buffers tend to do that.
: ?reset-video  ( -- )
   " reset-screen" stdout @  safe-execute
;

headers
defer debugger-vocabulary-hook
' noop is debugger-vocabulary-hook
headerless
: "restore" " restore" ;
: enter-forth  ( -- )
   init-c-stack
   monitor-interrupt-state
   clear-keyboard

   \ Just In case we were in the device tree.
   device-end

   \ Allow for custom search orders
   debugger-vocabulary-hook

   ?reset-video
   error-reset-trap -1 = if
      "restore" stdout @ safe-execute
      "restore" stdin @ safe-execute
      error-reset-cleanup
   then
   (handle-breakpoint
;

: exit-forth  ( -- )  reset-interrupts  (restart  ;

\ set the default state, and also force it in stand-init
' enter-forth is handle-breakpoint
' exit-forth  is restart

stand-init: Installing enter/exit handlers
   ['] enter-forth is handle-breakpoint
   ['] exit-forth  is restart
   ?mp-prompt
;
previous previous
headers
