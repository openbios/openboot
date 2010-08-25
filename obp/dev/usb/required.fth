\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: required.fth
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
id: @(#)required.fth 1.22 06/02/01
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

create bad-number			\ "Bad number syntax"
   d# 17 c,
   ascii B c,  ascii a c,  ascii d c,  bl c,  ascii n c,
   ascii u c,  ascii m c,  ascii b c,  ascii e c,  ascii r c,
   bl c,  ascii s c,  ascii y c,  ascii n c,  ascii t c,
   ascii a c,  ascii x c,  0 c,

: $>number  ( adr len -- n )  $number  if  bad-number throw  then  ;

0 value saved-self		\ used by fcode-finder -- probe-time only; global ok

0 value open-count			\ must be global

10 buffer: unit-address		\ must be global; used when no instance active.

defer bless-done-q		\ switching between polled and 10ms tick

external

: decode-unit  ( adr len -- port )
   base @ >r  hex
   dup if  $>number  else  2drop 0  then
   r> base !
;

: encode-unit  ( port -- adr len )
   unit-address 10 erase
   base @ >r  hex
   <# u#s u#>
   dup >r
   unit-address swap move
   unit-address r>
   r> base !
;

\ XXX control list left enabled by probe.
\ XXX keyboard signals resume -- port status word.
: open  ( -- ok? )
   open-count 0= if		\ do stuff that happens only on first open
      get-mem new-mem-table
      map-regs
      make-structs set-regs if
         dump-structs unmap-regs
         false exit
      then
      usb-resume
      usb-operational
      ['] quit-take-done-q to bless-done-q	\ XXX who cares about it when closing?
      ['] alarm-take-done-q 1 alarm
   then
   open-count 1+ to open-count
\   my-self to saved-self		\ instance for published method if needed.
\   d# 64 to max-packet			\ default -- read dev descriptor for good value
   true
;

\ XXX on last close, close should check over the q's to find out if there
\ are any endpoints and transfers left hanging.  There shouldn't be any.
\ close should toss them with a warning in diag-mode.
: close  ( -- )
   open-count 1- to open-count
   open-count 0= if		\ do stuff that happens only on last close
      ['] alarm-take-done-q 0 alarm
\ toss transfer-d's and endpoint-d's (except dummies).  Should only need to
\ look through index.
      toss-controller give-mem
   then
;

: reset  ( -- )  ;

headers
