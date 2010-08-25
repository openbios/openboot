\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: kbdutils.fth
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
id: @(#)kbdutils.fth 1.36 98/01/22
purpose: Converts Sun keyboard events to ASCII characters
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

\
\ The USB keyboard sends "down" keycodes (key #s) which are immediately
\ converted into ASCII characters (keyvalues) and enqueued.   The keycodes
\ are extracted from USB "interrupt" reports (meaning that the device is
\ polled periodically) which is initiated by the poll-usb word.
\ poll-usb also checks for "abort" ("Stop" key and "a" key down
\ simultaneously).  When a program wants a character from the keyboard
\ it calls getkey.  getkey merely removes a keyvalue from the queue
\ and returns it, or -1 if the queue is empty.


: time-reached?  ( when -- flag )  get-msecs -  0<  ;


\ headerless			\ XXX keep heads for debugging
external

\ Keyboard-specific information
h#  de	constant kb-unknown	\ Random unlikely to be seen
\ d#  120	constant Abortkey1	\ First key of abort seq - L1 (USB)
\ d#  4   constant Abortkey2	\ Second key of abort seq - "a" (USB)


\ Keymaps
\ 0 	constant  K-Normalmap
\ 1 	constant  K-Shiftmap
\ 2 	constant  K-Altgmap

\ headers			\ XXX for debugging
\ Returns a keyboard keyvalue (an ascii value which was obtained from
\ the keycode which was returned by the USB report).  First check for a
\ key arriving from USB, if no key then check to see if there may already
\ be one in the queue.  Implement auto-repeat if the same key hass been
\ down for the specified length of time.  If there are no keys available
\ then -1 is returned.
\
\ headers			\ XXX for debugging
external
: getkey  ( -- keyvalue )
   mutex-enter if
      nokey   exit			( no-key )
   then

   poll-usb if
      \ Got a Stop-A.
      clear-keyboard nokey
      mutex-exit user-abort		( no-key )
   then

   keybuf-empty? if			( )
   \ There were no new keys enqueued, check to see if we should return
   \ the repeat key.
      curr-repeat-key if		( )
         key-repeat-time time-reached?	( flag )
      else
         false
      then

      if   \ Repeating?
         \ Yes, we have a repeat key and the repeat timer has expired.
         get-msecs d# 52 + to key-repeat-time
         \ Reinit the timer for next time around.
         curr-repeat-key 		( keycode-repeat )
      else
         nokey				( no-key-dn )
      then
   else
	\ Queue is not empty - get a char.
      bget				( new-keyvalue )
   then
   mutex-exit exit			( keyvalue )
;

: read-bytes  ( addr len -- #bytes-read )
  dup 0= if		\ check for possible 0 len read
     nip exit
  then

  0  begin		( addr' len #bytes-read' )
     getkey		( addr' len #bytes-read' byte|-1 )
     dup -1 = if	( addr' len #bytes-read' byte|-1 )
        2swap 2drop	( #bytes-read until-flag )
     else   \ write the byte, incr addr, incr count, check for max len
        3 pick c!	( addr' len #bytes-read' ) \ write the byte
        1+ 2dup = if	( addr' len #bytes-read' ) \ incr cnt, chk for max
           nip nip true	( #bytes-read until-flag )
        else		( addr' len #bytes-read' )
           rot 1+ -rot	( addr' len #bytes-read' ) \ incr addr
	   false	( addr' len #bytes-read' until-flag )
        then
     then
  until			( #bytes-read )
;

\ headerless				\ XXX keep heads for debugging
