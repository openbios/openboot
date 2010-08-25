\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ttydriver.fth
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
\ id: @(#)ttydriver.fth 3.21 02/10/24
\ purpose: 
\ copyright: Copyright 1996-2002 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

headerless

\ The high level serial driver interface.
\ provides all the standard routines and relies upon underlying
\
\   usea, useb			- to switch interfaces
\   inituart			- init current uart
\   ukey?			- can read?
\   ukey			- read single char
\   uemit?			- can transmit?
\   uemit			- write char
\   ubreak?			- break detected?
\   clear-break			- Cleanup after a BREAK
\

: map-in ( offset len -- vaddr )	" map-in" $call-parent ;
: map-out ( vaddr len -- )		" map-out" $call-parent ;

: select-channel ( channel -- )
  \ Point to the correct property name.  Since the property is boolean,
  \ the information is conveyed by its presence, not its value.
  #channels 1 = if
    \ Grover or fiesta platforms
    " rts-dtr-off"
  else
    \ Excal or other sun4s platforms
    dup if  " port-b-rts-dtr-off"  else  " port-a-rts-dtr-off"  then
  then                                  ( channel name$ )
  get-my-property dup 0= if             ( channel prop$ false | channel true )
    nip nip                             ( channel false )
  then                                  ( channel flag )
  is dtr-rts-on?                        ( channel )

  \ Initialize channel
  if useb h# 02 else usea h# 01 then	( mask )
  dup channel-init and			( mask set? )
  if					( mask )
    drop				(  )
  else					( mask )
    channel-init or is channel-init	(  )
    inituart				(  )
  then
;

: (open)   ( arg$ -- okay? )
   \ First time we are opened then we set uartbase and init serial line.
   uartbase 0= if			( arg$ )
     tty-base my-space tty-size map-in	( arg$ va )
     dup is uartbase  0=  if		( arg$ )
       2drop false exit			( 0 )
     then				( arg$ )
   then

   >r >r				(  )
   0 select-channel			(  )
   default-ttya-mode 			( mode$ )
   r> r>				( mode$ arg$ )
   #channels 1- if			( mode$ arg$ )
     ascii ,  left-parse-string  if	( mode$ rem$ adr )
       c@  ascii b  =  if		( mode$ rem$ )
         >r >r				( mode$ )
         2drop			        (  )
         1 select-channel		(  )
         default-ttyb-mode		( mode$ )
         r> r>				( mode$ rem$ )
       then				( mode$ rem$ )
     else				( mode$ rem$ adr )
       drop				( mode$ rem$ )
     then				( mode$ rem$ )
   then					( mode$ rem$ )
   dup if  2swap  then  2drop		( mode$' )

   0 parse-mode ?dup 0= if		(  )
       default-tty-mode 0 parse-mode	( flag )
   then					( flag )
   dup if				( flag )
     opencount 1+ is opencount		(  )
   then
;

headers
external

: open ( -- flag )  my-args (open)  ;

: close  ( -- )
   opencount ?dup if 1- is opencount then
   opencount if exit then		(  )
   uartbase tty-size map-out		(  )
   false to channel-init		(  )
   false to uartbase			(  )
;

: read   ( adr len -- #read )
   ukey? 0=  if  2drop -2  exit  then		( adr len )
   tuck						( len adr len )
   begin  dup 0<>   ukey? 0<>  and  while	( len adr len )
     over  ukey mask-#data and swap c!		( len adr len )
     1 /string					( len adr' len' )
   repeat					( len adr' len' )
   nip -					( #read )
;

: write  ( adr len -- #written )
   tuck  bounds  ?do				( len )
      i c@  uemit				( len )
   loop						( len )
   begin  uemit?  until				( len )
;

: poll-tty  ( -- )
   ttylock @ if  exit  then
   ubreak?  if  clear-break  user-abort  then
   \ Give lower levels chance to work.
   ukey? drop
;

: install-abort  ( -- )  ['] poll-tty d# 10 alarm  ;

: remove-abort   ( -- )  ['] poll-tty     0 alarm  ;

: restore ( -- ) ;
