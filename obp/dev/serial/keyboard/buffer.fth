\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: buffer.fth
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
\ id: @(#)buffer.fth 1.2 97/01/20
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

\ Keyboard buffer definitions
\  keybuf which is defined below is scanned
\  by the refresh routine, and the keyboard-driver.  Then later
\  the keys are picked up by the monitor busywait keyboard routine, or
\  by Unix or other application programs directly.
\
\  Note that each keystroke, if typed slowly (by computer standards)
\  takes 3 bytes: a key-down, a key-up, and a keyboard-idle.  so allocate
\  three times as much room as you want to be able to type ahead.
\  typeahead won't echo immediately in the monitor, but will echo in
\  its proper place in the i/o transcript.

headerless

d# 90   constant keybufsize
keybufsize buffer: keybuf
0 	value  getptr
0 	value  putptr
0 	value  endptr

: initkeybuf ( -- )
   keybuf  is  getptr
   keybuf  is  putptr
   keybuf keybufsize + is endptr
;

\ put key into keybord buffer, ignoring overun
: bput	( key -- )	\ put key into buffer
   putptr endptr >= if
      keybuf is putptr
   then
   putptr c! putptr 1+ is putptr
;

\ clear the keyboard buffer for put task
: bputclr  ( -- )
   getptr is putptr
;

\ return the next key
: bget	( -- key )	\ Fetch a key from buffer
   getptr endptr >= if
      keybuf is getptr
   then
   getptr c@ getptr 1+ is getptr
;

\ return TRUE if keybuf is empty.
: keybuf-empty? 	( -- flag ) \ True if keybuf is empty.
   getptr putptr =
;
