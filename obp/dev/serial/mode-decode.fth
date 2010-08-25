\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mode-decode.fth
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
\ id: @(#)mode-decode.fth 1.4 00/03/15
\ purpose: 
\ copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved
\
\ common serial line driver code to cope with serial configuration
\
hex
headerless

\ The normal routines that print
: (.tty-bad-baud) ( str,len -- 0 flag ) ." Bad baud rate: " type cr 0 true ;
: (.tty-bad-field) ( flag thing adr,len -- flag thing )
  type ."  '" emit ascii ' emit cr drop true 0
;

\ The silent routines that return status
: (tty-bad-field) ( flag thing adr,len -- flag thing ) 2drop 2drop true 0 ;
: (tty-bad-baud) ( str,len -- 0 flag ) 2drop 0 true ;

instance defer .tty-bad-baud
instance defer .tty-bad-field

: silent-parse ( -- )
   ['] (tty-bad-baud)   is .tty-bad-baud
   ['] (tty-bad-field)	is .tty-bad-field
;
: normal-parse ( -- )
   ['] (.tty-bad-baud)	is .tty-bad-baud
   ['] (.tty-bad-field)	is .tty-bad-field
;

: $dnumber ( adr,len -- number,false|true )
  base @ >r				( adr,len )
  d# 10 base ! $number			( number,false|true )
  r> base !				( number,false|true )
;

: get-baudrate ( adr,len -- reg-data error? )
  2dup $dnumber 0= if			( adr,len baud )
    dup min-baud max-baud		( adr,len baud baud min max )
    between if				( adr,len baud )
      nip nip false exit		( baud false )
    then				( adr,len baud )
    drop				( adr,len )
  then					( adr,len )
  .tty-bad-baud				( 0 error )
;

\
\ Convert Handshake into standard 'integer' form
\
: check-field ( adr,len nlen -- error? char )
  > swap c@				( flag char )
;

: get-handshake ( adr,len -- reg-data,0 | error? )
  1 check-field case			( false )
    ascii - of  hs.none  endof		\ none
    ascii h of  hs.hw    endof		\ hardware
    ascii s of  hs.sw    endof		\ software
    ( ?? ) " bad handshake" .tty-bad-field
  endcase swap				( code error? )
;

: get-stopbits ( adr,len -- reg-data,0 | error? )
  1 check-field case			( false )
    ascii 1 of  h# 01  endof		\ 1 stop bit
    ascii 2 of  h# 02  endof		\ 2 stop bits
    ( ?? ) " bad stopbits" .tty-bad-field
  endcase swap				( code error? )
;

: get-parity ( adr,len -- reg-data,0 | error? )
  1 check-field case			( false )
    ascii m of  p.mark   endof		\ mark
    ascii e of  p.even   endof		\ even
    ascii o of  p.odd    endof		\ odd
    ascii n of  p.none   endof		\ none
    ascii s of  p.space  endof		\ space
    ( ?? ) " bad parity" .tty-bad-field
  endcase swap				( code error? )
;

: get-databits ( adr,len -- reg-data,0 | error? )
  1 check-field case			( false )
    ascii 5 of  h# 05  endof
    ascii 6 of  h# 06  endof
    ascii 7 of  h# 07  endof
    ascii 8 of  h# 08  endof
    ( ?? ) " bad databits" .tty-bad-field
  endcase				( flag bits )
  1 over lshift 1- is mask-#data	( flag bits )
  swap					( bits flag )
;

: $= ( adr,len adr,len -- flag )
   rot tuck = if			( adr1 adr2 len )
      comp 0=				( flag )
   else					( adr1 adr2 len )
      3drop false			( false )
   then					( flag )
;

: 6reverse ( a b c d e f -- f e d c b a )
  swap 2swap swap 2rot swap
;

0 instance value /mode-remains
0 instance value mode-remains
0 instance value /mode$
0 instance value mode-str

: >mode$ ( str,len -- ) is /mode$ is mode-str ;

: mode$ ( -- str,len ) mode-str /mode$ ;

: mode-remains$ ( -- str,len ) mode-remains /mode-remains ;
  
: >mode-remains$ ( str,len -- ) is /mode-remains is mode-remains ;

: bail? ( data flag -- )
  if true throw else mode-remains$ >mode$ then
;

: get-field ( -- field,len )
  mode$ ascii , left-parse-string
  2swap >mode-remains$
;

instance defer (config-serial)

: mode-cleanup ( hs stp prty dbits baud rts-dtr mode -- )
  3drop 3drop drop			( )
;

\
\ scan the current line looking for ,
\ the format of the line is fixed so if I have too many or too few
\ we just bail. No device state is changed unless all the arguments
\ look reasonable and all the decode routines don't throw.
\
\ general format is: "baud,databits,parity,stopbits,handshake"
\
\ this is converted into a standard numeric format and if we are not
\ verifying we call config-serial
\ uses device specific routine
\   config-serial ( hs stp prty dbits baud -- )
\
\

: (parse-mode) ( adr len --  )
   >mode$				( )
   dtr-rts-on?				( rts? )
   get-field get-baudrate  bail?	( rts? baud )
   get-field get-databits  bail?	( rts? baud dbits )
   get-field get-parity    bail?	( rts? baud dbits prty )
   get-field get-stopbits  bail?	( rts? baud dbits prty stp )
   get-field get-handshake bail?	( rts? baud dbits prty stop hs ) 
   rs-mode-decode			( rts? baud dbits prty stop hs mode )
   >r 6reverse r> (config-serial)	( )
;

: (do-catch) ( adr,len acf -- str,len false|true )
   catch if			( adr,len )
     2drop mode$ false		( adr,len false )
   else				( )
     mode$ true			( str,len true )
   then
;

\ Now protect the stack
\ If scan? is set we still return pass/fail but with a
\ good scan we also return the remainder string
\ so the stack comments are a little misleading.
\
headers
: parse-mode ( str,len scan? -- ok? )
   dup if				( adr,len flag )
     ['] mode-cleanup			( adr,len flag set-acf )
     silent-parse			( adr,len flag set-acf )
   else					( adr,len flag )
     ['] config-serial			( adr,len flag set-acf )
     normal-parse			( adr,len flag set-acf )
   then					( adr,len flag set-acf )
   is (config-serial)			( adr,len flag )
   ['] (parse-mode) swap if		( adr,len acf )
     (do-catch)				( adr,len valid? )
   else
     (do-catch)				( adr,len valid? )
     nip nip				( valid? )
   then
;
headerless
