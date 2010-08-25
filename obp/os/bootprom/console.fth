\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: console.fth
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
id: @(#)console.fth 1.8 01/05/30
purpose: Implements console character I/O
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Input and output selection mechanism

headers
nuser stdin   0 stdin !
nuser stdout  0 stdout !

headerless
0 value copy-down$
nuser pending-char
nuser char-pending?

: "read"   ( -- adr len )  " read"   ;	\ Space savings
: "write"  ( -- adr len )  " write"  ;	\ Space savings
: stdin-getchar  ( -- okay? )
   pending-char 1  "read" stdin @ $call-method  1 =
;
: console-key?  ( -- flag )
   char-pending? @  if
      true
   else
      stdin-getchar dup  if  char-pending? on  then  ( flag )
   then
;
: console-key  ( -- char )
   char-pending? @  if
      pending-char c@  char-pending? off
   else
      begin  stdin-getchar  until
      pending-char c@
   then
;
nuser temp-char

stand-init: Allocate some space for string relocation
   d# 82  alloc-mem is copy-down$
;

: (copy-down$) ( str,len -- str',len )
   over d# 32 >> over d# 81 < and if		( str,len )
      \ Sigh, we got a string we cant just send to FCODE.
      copy-down$ tuck over			( str,adr,len adr,len )
      2>r move 2r>				( adr,len )
   then						( str,len )
;

\ break a write into 80 char chunks.
: console-type  ( adr len -- )
   begin
      dup while						( adr,len )
         2dup d# 80 min					( adr,len adr,len' )
         (copy-down$) "write" stdout @ $call-method >r  ( adr,len )
         r@ - swap r> + swap				( adr',len' )
   repeat						( adr,len )
   2drop						( )
;
: console-emit  ( char -- )  temp-char c!  temp-char 1 console-type  ;

\ close the device if it is not the stdout device.
: ?close  ( ihandle|0 -- )
   ?dup  if
      stdout @  over  <>  if  close-dev  else  drop  then
   then
;
: has-method?  ( method-adr,len phandle -- flag )
   find-method  dup  if  nip  then  ( flag )
;
: .missing  ( routine-adr,len type-adr,len -- )
   ." The selected " type ."  device has no " type  ."  routine" cr
;

: pihandle=  ( phandle ihandle -- flag )
   dup  if  ihandle>phandle =  else  2drop false  then
;
\ : already-opened?  ( phandle -- flag )  stdout @ pihandle=  ;

headers
: input  ( pathname-adr,len -- )
   2dup locate-device  if
      type ."  not found." cr  exit
   else				      ( pathname-adr,len phandle )
      \ Exit if already selected.
      dup stdin @ pihandle=  if
         3drop exit
      then
      "read" rot has-method?  if      ( pathname-adr,len )
	 open-dev ?dup  if				( ihandle )
	    stdin @  swap stdin !			( old-ihandle )

	    " install-abort" stdin @ $call-method	( old-ihandle )
	    ?dup  if 					( old-ihandle )
	       " remove-abort" 2 pick $call-method	( old-ihandle )
	       close-dev
	    then
	 else
	    ." Can't open input device." cr  exit
	 then
      else			      ( pathname-adr,len )
	 2drop  "read" " input" .missing  exit
      then
   then
;

variable stdout-#lines		\ For communication with client program
' stdout-#lines		" stdout-#lines" chosen-variable
' stdin			" stdin" chosen-variable
' stdout		" stdout" chosen-variable

variable termemu-#lines		\ For communication with terminal emulator

headerless

\ Set #lines in /chosen node for client programs to read
: report-#lines  ( -- )
   termemu-#lines @ -1 <>  if   ( #lines )
      \ The terminal emulator package set termemu-#lines
      termemu-#lines @		( #lines )
   else                         ( #lines )

      \ termemu-#lines was not set, so check for a "#lines" property
      \ in the output device's package.

      " #lines"  stdout @ ihandle>phandle  get-package-property  if  ( )
         \ No "#lines" property; report "unknown"
         -1			( unknown-#lines )
      else			( adr len )
         \ Report the value of the "#lines" property
         get-encoded-int	( #lines )
      then                      ( #lines )
   then                         ( #lines )
   stdout-#lines  !
;

headers
: output  ( pathname-adr,len -- )
   2dup locate-device  if               ( pathname-adr,len )
      type ."  not found." cr  exit
   else					( pathname-adr,len phandle )
      \ Exit if already selected.
      dup stdout @ pihandle= if
         3drop exit
      then
      "write" rot has-method?  if	( pathname-adr,len )
         -1 termemu-#lines !	\ Set value for terminal emulator to change
	 open-dev ?dup  if		( ihandle )
	    stdout @  swap stdout !	( old-ihandle )
	    ?close
            report-#lines
	 else
	    ." Can't open output device." cr  exit
	 then
      else                             ( pathname-adr,len )
	 2drop  "write" " output" .missing  exit
      then
   then
;

: keyboard   ( -- adr len )  " keyboard"  ;
: screen     ( -- adr len )  " screen"  ;
: ttya       ( -- adr len )  " ttya"  ;
: ttyb       ( -- adr len )  " ttyb"  ;

: io  ( pathname-adr,len -- )
   2dup 2>r                                ( path$ ) ( r: path$ )
   2r@ screen $=  2r> keyboard $=  or  if  ( path$ )
      2drop  screen output  keyboard input  exit
   then  2dup  input  output               ( path$ )
;

: console-io  ( -- )
   stdin  @ 0<>
   stdout @ 0<>  and  if
      char-pending? off
      ['] console-key?  is key?
      ['] console-key   is (key
      ['] console-emit  is (emit
      ['] console-type  is (type
   then
;

headers
