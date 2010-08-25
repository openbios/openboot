\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probe.fth
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
id: @(#)probe.fth 1.4 98/10/14
purpose: Package methods for Sun keyboard
copyright: Copyright 1990-1997 Sun Microsystems, Inc.  All Rights Reserved

\ About the only thing that currently isn't commented-out in this file
\ is a stub for aborted? which currently just returns false.  The USB
\ keyboard can't be "probed" at reset time the way the Sun keyboard was,
\ so if we have to wait until the first record is returned then we might
\ as well look for the L1-X sequences later during the "regular" key
\ processing sequence!

\ headerless

\ d# 128 8 / constant /downkeys
\ /downkeys instance buffer: downkeys

\
\ WARNING: This routine returns to its callers parent, with rval
\ on the data stack, but only if the key corresponding to scancode was down.
\
\ : keypressed? ( scancode rval -- flag )
\   swap downkeys 			( rval bit addr )
\   bittest if				( rval )
\    r> drop				( rval )  \ XX magic!!
\   else					( rval )
\    drop					( -- )
\   then					( -- )
\ ;

\ We may in fact need a wait-reset word, but that remains to be seen.
\ We definitely don't need one that monitors the Sun kbd reset sequence.
\ : wait-reset ( ?? -- ?? )
\ ;

\ : wait-reset  ( -- bailed? )
   \ Wait for the reset sequence, discarding all prior keys
\    kbd-reset-wait get-msecs + true	( ms more? )
\    begin				( ms more? )
\      over time-reached? 0=		( ms more? flag )
\      over and				( ms more? flag' )
\    while				( ms more? )
\       d# 100 key-timeout? 0= if		( ms more? )
\          kbd-holding c@ resetkey = if	( ms more? )
\             resetkey bput		( ms more? )
\             nextkey  keybid !		( ms more? )
\             ['] normal is keypress	( ms more? )
\             drop false			( ms false )
\          then				( ms more? )
\       then				( ms more? )
\    repeat nip				( timeout? )
\ ;


\  do-probe resets the keyboard to determine if it is present.
\  If the keyboard is not present (i.e. it does not respond to the reset
\  command within a certain time), 0 is returned.
\  Otherwise, the address of a bitmap showing which keys were depressed
\  at the time of the reset is returned.
\
\ Its unclear that USB will send back keys that are down at the time
\ or a reset.  And since the L1-X sequences will come late in the game
\ it's also uncertain if that information will be worth anything, so
\ the do-probe word has been commented out for now.
\ : do-probe ( click -- present? )
\    begin   \ Discard prior received characters
\       nextkey  nokey =
\    until
\ 
\    reset 0= if 0 exit then	\ Nothing there
\ 
   \ See which keys are down.
\    downkeys  /downkeys erase
\    0					( dummy-key# )
\    begin
\       drop				( )
\       nextkey	  	     		( key# )
\       -1 over <> Idle 2 pick <> and	( key# flag )
\    while				( key# )
\       released over and invert  if	( key# )
\         dup downkeys bitset		( key# )
\       then				( key# )
\    repeat				( key# )
\    drop					( )
\    true
\ ;

\ headers			\ XXX for debugging
external

: abort?  ( -- flag )
  false
;
\ Called from the support layer to cope with special keyboard
\ L1 sequences.
\
\ : abort?  ( -- flag )
\    1 downkeys bittest if	( -- )		\ L1 was down
\      d#  80 ascii F keypressed?	( -- F )	\ L1-F
\      d# 105 ascii N keypressed?	( -- N )	\ L1-N
\      d#  79 ascii D keypressed?	( -- D )	\ L1-D
\    then
\    false			( false )
\ ;

\ headerless			\ XXX keep heads for debugging
