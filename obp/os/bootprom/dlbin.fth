\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dlbin.fth
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
id: @(#)dlbin.fth 2.14 97/08/11
purpose: 
copyright: Copyright 1990-1995 Sun Microsystems, Inc.  All Rights Reserved

\ Download a.out files over a serial line to a stand-alone Forth system.

decimal

headerless
headers

\ Move all these out of the way.
vocabulary dloader also dloader definitions

variable charbuf
variable dl.break
variable dl.read
variable dl.handle

: dl-call ( xxx -- xxx ) dl.handle @ call-package ;

: getbyte  ( -- char )
   begin dl.break @ dl-call charbuf 1 dl.read @ dl-call 0> until
   charbuf c@
;
: getbytes  ( adr len -- adr+len )
   over + tuck swap ?do  getbyte i c!  loop
;

: .cantfind ( adr,len -- true )
  ." Unable find " type ."  method" cr true
;

: setup-dload ( -- )
  0 0 ttya expand-alias drop		( 0 0 str,len )
  $open-package ?dup 0= if		( ihandle )
    ." ttya didn't open" cr		( -- )
    true exit				( -- )
  then dl.handle !			( ihandle )
  " read" 2dup				( str,len str,len )
  dl.handle @ ihandle>phandle		( str,len str,len phandle )
  find-method if			( str,len acf )
    dl.read !				( str,len )
    2drop " poll-tty" 2dup		( str,len str,len )
    dl.handle @ ihandle>phandle		( str,len str,len phandle )
    find-method if			( str,len acf )
      dl.break !			( str,len )
      2drop false exit			( false )
    then				( adr,len )
  then					( str,len )
  .cantfind				( -- true )
;

\ Throw out junk until we see the start of the header
: consume  ( -- )  begin  getbyte  1 =  until  ;

: gettext  ( adr len -- adr actual )
   bounds 2dup  ?do                  ( end start )
      getbyte  dup control D =  if   ( end start  char )
         drop  nip  i swap  leave    ( end' start )
      then                           ( end start  char )
      i c!
   loop                              ( end' start )
   tuck -                            ( adr actual )
;

previous definitions
also dloader
headers

: dlbin  ( -- )
   cleanup  setup-dload if exit then
   ." Ready for download.  Send binary file." cr
   consume
   1 a.out-header c!                    \ consume ate the first header byte
   a.out-header 1+  /a.out-header 1-  getbytes drop	\ Read the header

   \ Verify the magic number; if it's wrong, then you have to abort with
   \ a break character.
   a.out-header a_magic w@  h# 107 <>  if  begin getbyte drop  again  then

   entry-adr	      ( tadr )		\ Read the file segments
   /text   getbytes   ( dadr )
   /data   getbytes   ( radr )
   /reloc  l->n -1 <>  if  /reloc getbytes  then  ( sadr )
   /syms   getbytes   ( stradr )

   /syms  if                   ( string-table-adr )
      4  getbytes              ( rest-of-string-table-adr )
      dup 4 - @ 4 -  getbytes  ( string-table-end-adr )
   then                        ( end-adr )
   (init-program)              ( end-adr )
   entry-adr set-pc            ( end-adr )
   entry-adr /a.out-header -  tuck -  initsyms    ( )
   entry-adr /text + /data +  /bss  erase         ( )
;
 
: sload  ( -- )
   cleanup  setup-dload if exit then
   ." Ready for download.  Send file then type ^D"  cr
   load-base h# 20000
   \ Turn off interrupts for now because the interrupt handler takes too long
   \ and we lose characters.
   lock[  ['] gettext  catch  ]unlock  ?dup  if  throw  then  ( adr len )
   file-size !  drop
;
: dl  ( -- )  sload  load-base  file-size @  interpret-string  ;

previous

