\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: methods.fth
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
id: @(#)methods.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

headerless

alias ubreak?  hyperbreak?
alias (ukey?)  hyperkey?
alias (ukey)   hyperkey
alias uemit    hyperemit

d# 90  constant	 ubufsize
ubufsize buffer: ubuf
0	value  getptr
0	value  putptr
0	value  endptr

variable ttylock

: initubuf ( -- )
   ubuf	  dup  is getptr
	  dup  is putptr
   ubufsize +  is endptr
;

: ubuf-empty? ( -- flag )  getptr putptr = ;

\ Read a key into the buffer, ignoring overrun
: bput ( key -- )
   putptr endptr >=  if	 ubuf is putptr	 then
   putptr c!  putptr 1+ is putptr
;

\ Clear the buffer
: bputclr ( -- )  getptr is putptr ;

\ Read a key from the buffer
: bget ( -- key )
   getptr endptr >=  if	 ubuf is getptr	 then
   getptr c@  getptr 1+ is getptr
;

: uread ( -- )
   ttylock on
   begin  (ukey?)  while  (ukey) bput  repeat
   ttylock off
;

: ukey? ( -- flag )  uread  ubuf-empty? 0=  ;
: ukey	( -- char )  begin  ukey?  until  bget ;


: clear-break ( -- )
   ukey? drop bputclr  false to ubreak?
;

: poll-tty  ( -- )
   ttylock @ if  exit  then
   ubreak?  if  clear-break  user-abort  then
   \ Give lower levels chance to work.
   ukey? drop
;

h# 7f constant mask-#data

: /string  ( adr len cnt -- adr+cnt len-cnt )  tuck 2swap +  -rot -  ;

external

: open ( -- ok? ) initubuf  ttylock off  true ;

: close ( -- )  ;

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
   tuck  bounds  ?do	( len )
      i c@  uemit	( len )
   loop			( len )
;

: install-abort  ( -- )  ['] poll-tty d# 10 alarm  ;

: remove-abort   ( -- )  ['] poll-tty     0 alarm  ;

: restore ( -- ) ;

: ring-bell  ( -- )  ;

headerless
