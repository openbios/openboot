\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: security.fth
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
id: @(#)security.fth 1.13 01/04/06
purpose: Implements Open Boot security feature (passwords)
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

\ The security variables are placed at a fixed location to
\ prevent them from being changed when a new PROM is released.
\ An area near the start of EEPROM is reserved for them.

unexported-words
: legal-passwd-char?   ( char -- flag )  bl  h# 7e  between  ;

8 buffer: pwbuf0
8 buffer: pwbuf1
: get-password  ( adr -- adr len )
   0  begin                    ( adr len )
      key dup  linefeed <>  over carret <>  and
   while                       ( adr len char )
      2dup  legal-passwd-char?  swap 8 <  and  if     ( adr len char )
         >r 2dup + r> swap c!  ( adr len )
         1+                    ( adr len )
      else                     ( adr len char )
         drop beep             ( adr len )
      then                     ( adr len )
   repeat                      ( adr len char )
   drop   cr
;

exported-headerless
\ used by the keyboard support package
: security-on?  ( -- flag )         \ flag true if command or full security
   security-mode 1 2 between		( on? )
   security-password dup 0<> -rot	( ok? )
   bounds ?do i c@ legal-passwd-char? and loop
   and					( flag )
;

\ the bootparam package requires this.

: password-okay?  ( -- good-pw? )
   security-on?  if
      ??cr ." Firmware Password: "
      pwbuf0 get-password security-password  ( adr,len1 adr,len2 )
      compare  0=  if  true  exit  then      ( )
      ." Sorry.  Waiting 10 seconds." cr
      security-#badlogins 1+ to security-#badlogins
      lock[  d# 10.000 ms  ]unlock
      false  exit
   then  true
;

exported-headers
\ Required to make sure users know that set-defaults doesn't change
\ security settings.
overload: set-defaults  ( -- )
   security-on?  if
      ." Note: set-defaults does not change the security fields." cr
   then
   set-defaults
;

: password  ( -- )
   ." New password (8 characters max) "   pwbuf0 get-password    ( adr len )

   ." Retype new password: "    pwbuf1 get-password      ( adr len adr len )

   2over $= if			  	( adr len )
      ['] security-password 		( adr len apf )
      3dup encode 			( adr len apf true|adr len false )
      if
         3drop				( )
         ." Invalid string - password unchanged" cr
      else
         2drop set			( )
      then
   else
      2drop				( )
      ." Mismatch - password unchanged" cr
   then
;

unexported-words

: (?permitted)  ( adr len -- adr len )
   source-id  if  exit  then	\ Apply security only to interaction
   2dup  " go"   $=  if  exit  then
   2dup  " boot" $=  if  exit  then
   password-okay? 0=  abort" "
;

unexported-words
: first-prompt  ( -- )   help-msg  ['] (prompt) is prompt do-prompt  ;

: secure-help-msg  ( -- )
   ??cr ." Type boot , go (continue), or login (command mode)" cr
;

: secure-prompt ( -- )  ??cr ." > "  ;

: first-secure-prompt ( -- )
   secure-help-msg  ['] secure-prompt  is prompt  do-prompt
;

: secure  ( -- )
   ['] first-secure-prompt is prompt
   ['] (?permitted) is ?permitted
   [ also hidden ]  true is deny-history?  [ previous ]
;

: unsecure  ( -- )
   ['] prompt behavior  ['] (prompt)  <>  if
      ['] first-prompt is prompt
   then
   ['] noop is ?permitted
   [ also hidden ]  false is deny-history?  [ previous ]
;

exported-headerless

: (?secure) ( -- )  security-on?  if  secure  else  unsecure  then  ;

' (?secure) to ?secure

exported-headers

alias login  unsecure
alias logout ?secure

unexported-words
