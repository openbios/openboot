\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 2.28 03/12/11 09:22:43
purpose: The basic FCode byte code interpreter loop
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\  The basic FCode byte code interpreter loop


\ "Generic" byte code interpreter.  These words are used to interpret
\ byte code streams.  The action to be performed for each byte code
\ in the stream is defined externally, so the interpreter code in this
\ file may be used by several programs, such as the byte code recompiler
\ in the CPU boot PROM and the byte code display program.


headers

nuser interpreter-pointer	\ Points to next byte code in stream
nuser fcode-verbose?		\ Print out fcodes as they are encountered

headerless

[ifnexist] chdump
   also hidden
      : chdump ( addr len -- )  push-hex ['] c@ to dc@ d.2 pop-base ;
   previous
[then]

[ifnexist] char?
   : char?  ( byte -- flag )
      dup bl h# 7e between		( byte printable?)
      over carret = rot linefeed =	( printable? cr? nl?)
      or or				( printable?)
   ;
[then]


nuser more-bytes?		\ True when stream is not exhausted
\ nuser table#			\ Remembers table # of last code encountered
\ nuser code#			\ Remembers code # of last code encountered
nuser fc-spread			\ The distance between successive bytes in
				\ the code stream.  If the bytes are stored
				\ in an 8-bit PROM connected to one of the
				\ byte lanes of a 32-bit bus, spread is 4.
nuser offset16?			\ Are offsets 16 bits long?

\ Get the next byte code from the byte code stream
: get-byte  ( -- byte-code )
   interpreter-pointer @ c@  fc-spread @ interpreter-pointer +!  ( byte-code )
\  h# 100 0 do loop  \ Debug ONLY
;

d# 16 constant #token-tables		\ Maximum number of token tables

h# 100 constant tokens/table
tokens/table  /token *  constant /token-area
tokens/table  8 /       constant /immed-area   \ 1 bit for each token

/token-area /immed-area +  constant /token-table

\ 0 value token-table0
\ #token-tables /token-table *  buffer: token-table0

\ /stringbuf buffer: string-buf	\ buffer for collecting strings
d# 258 buffer: string-buf	\ buffer for collecting strings

variable token-tables-ptr	\ Token ptr to array of pointers to token tables
: token-tables  ( -- tables-pointer )  token-tables-ptr token@  ;

  8 constant local-table#	\ First table # for local codes


\ Terminate interpretation of the byte code stream.  This is invoked
\ by byte codes 0 and ff, so that the byte code interpreter will exit
\ when an unprogrammed section of the PROM is encountered.
headers
: end0  ( -- )  more-bytes? off  ;  immediate   \ For end value 0
: end1  ( -- )  [compile] end0   ;  immediate   \ For end value ff
: ferror  ( -- )
   ." Unimplemented FCode token before address " interpreter-pointer @ .h cr
   [compile] end0
;
: obsolete-fcode ( -- )  ferror  ;

headerless

: ttbl-align  ( -- )	\ like acf-align without 'lastacf side-effect
   begin  here #acf-align 1- and
   while  0 c,
   repeat
;

: init-tables  ( -- )
   ttbl-align  here
   #token-tables /token *  allot
   ( here )   token-tables-ptr token!
   token-tables   #token-tables /token *  bounds
   ?do  i !null-token  /token +loop
;

\ Return the address of the numbered token table.  If space for that
\ table hasn't yet been allocated, allocate it.
: >token-table  ( table# -- table-adr )
   token-tables  over ta+ get-token?  if      ( table# table-adr )
      nip                                     ( table-adr )
   else                                       ( table# )
      ttbl-align  here                        ( table# table-adr )
      /token-area /immed-area +   allot       ( table# table-adr )
      tokens/table 0  do                      ( table# table-adr )
         dup i ta+  ['] ferror  swap token!   ( table# table-adr )
      loop                                    ( table# table-adr )
      tuck  token-tables  rot ta+  token!     ( table-adr )
      dup /token-area +  /immed-area note-string erase    ( table-adr )
   then                                       ( table-adr )
;

\  Immediate bits for each token are at the end of the table,
\  starting at (table-addr + /token-area).  The bits are
\  addressed individually, without regard for their numeric
\  value within a byte, word, long or extended-cell.  This
\  means that the bit for token#0 is the highest-order bit
\  in the array.  This is not as confusing to implement as
\  it is to explain; the  bitset  bitclear  and  bittest 
\  functions handle the mechanics of it all.  This means
\  that the pair ( N array-addr ) points to the same bit
\  as ( {N mod 8}  {array-addr + N/8} )
\
\  While this is a change from previous versions, it has
\  no impact on compatibility:  the token-tables and their
\  associated "immediate" bits are local to a consolidation.
\     
: >offset  ( code# table-addr -- bitoffset byteaddr )
   /token-area +
;

: set-immed  ( code# table-addr -- )
    >offset  bitset
;

: clear-immed  ( code# table-addr -- )
    >offset  bitclear
;

: immed?  ( code# table-addr -- flag )
   >offset bittest
;

\ Gets a signed offset from the byte code stream.
: get-offset  ( -- n )
   fcode-verbose? @  if  interpreter-pointer @  then	( [? iptr ?] )
   get-byte
   offset16? @  if
      8 <<  get-byte +   d# 16
   else
      d# 24
   then 			( [? iptr ?] raw-offset shift-amount )
   tuck <<  l->n  swap >>a	( [? iptr ?] offset )

   \  For Verbose-mode, print the amount of the offset and the (target).
   fcode-verbose? @  if 				( iptr offset )
      push-hex tuck				 ( offset iptr offset )
      dup s. fc-spread @ * + fake-name .id	 ( offset )
      pop-base
   then
;

\ Gets a 16-bit word from the byte code stream.
: get-word  ( -- 16bit ) get-byte 8 <<  get-byte +  ;

\ Gets a longword from the byte code stream.
: get-long  ( -- long )  get-word  d# 16 <<  get-word +
   fcode-verbose? @  if dup .h then
;

\  Allow text strings only.  Not composites, and no null-byte separators.

: all-text?  ( adr len -- flag )
   false -rot  bounds ?do  drop			( -- )
      i c@ char? dup 0= ?leave
   loop 			   ( all-characters-printable? )
;

\  Types a string as bytes if it is not legitimately text.
: protected-type ( $addr,len -- )
   2dup all-text? if   type
   else       2dup
	    ." ""( "   chdump    ." )"""
      dup if  2dup
	    ."    \  "
	   [ also hidden ] emit.ln  [ previous ]
     then     2drop
   then
;

\ Gets a string from the byte code stream.
: get-bstring  ( -- adr len )
   get-byte  ( len )  dup string-buf  c!  ( len )
   string-buf 1+  swap  bounds  ?do  get-byte i c!  loop
   string-buf  count
   fcode-verbose? @  if  ??cr 8 to-column 2dup protected-type cr then
;

: token\immed  ( code# table-addr -- xt immediate? )
   2dup immed?  >r                                 ( code# table-addr )
   swap ta+  token@   r>
;
headers
\ Don't change fcode-find to return -1|0|1 like find, because
\ some people use it to "rehead" definitions.  If we need a function
\ that returns -1|0|1, give it a different name.
: fcode-find  ( code# table# -- xt immediate? )
   >token-table                                    ( code# table-addr )
   token\immed                                     ( xt immediate? )
;
headerless
\ Gets the address of a Forth word from the byte code stream.
\ The byte code stream contains a byte code.  The address of the
\ Forth word corresponding to that byte code is found and returned.

defer get-token-hook ' noop is get-token-hook

: next-fc-token  ( -- xt immediate? )
   fcode-verbose? @  if
      ??cr  interpreter-pointer @  u. ascii : emit 3 spaces
   then
   get-byte
   dup  #token-tables >=  over 0= or   ( byte table0? )
   if  0  else  get-byte swap  then    ( code# table# )
   fcode-verbose? @  if
      push-hex
      dup [ also hidden ] .2 over .2 [ previous ]
      pop-base
   then
   get-token-hook
   fcode-find                          ( xt immediate? )
   fcode-verbose? @  if
      over .name  dup if ['] immediate .name then
   then
;
headers
: get-token  ( fcode# -- xt immediate? )  wbsplit fcode-find  ;

: set-token  ( xt immediate? fcode# -- )
   wbsplit  >token-table             ( xt immediate? code# table-addr )
   rot  if			     ( xt immediate? code# table-addr )  
      2dup set-immed                 ( xt code# table-addr )   
   else                              ( xt code# table-addr )  
      2dup clear-immed               ( xt code# table-addr )  
   then                              ( xt code# table-addr )
   swap ta+ token!
;

headerless
\ The action performed for each token in the byte code stream.  Before
\ executing byte-interpret, an action routine must be installed in
\ do-byte-compile.
defer do-byte-compile  ( xt immediate? -- )
: verify-fcode-prom-checksum ( -- )
   get-byte  3  <  if				 (  )
      get-word drop   \ Checksum                 (  )
      get-long drop   \ Length                   (  )
   else                                          (  )
      get-word                                   ( cksum )
      0  get-long                                ( cksum 0 length )
      interpreter-pointer @ >r                   ( cksum 0 length ) ( r: ip )
      8 - 0 ?do  get-byte + loop                 ( cksum cksum' )   ( r: ip )
      r> interpreter-pointer !                   ( cksum cksum' )
      lwsplit + lwsplit +  h# 0ffff and  <>  if  (  )
	 ." Incorrect FCode PROM checksum "      (  )
      then                                       (  )
   then                                          (  )
;
headers
variable fcode-checksum?  fcode-checksum?  off
: version1  ( -- )
   offset16? off
   fcode-checksum? @  if
      verify-fcode-prom-checksum
   else
      get-byte drop    \ Pad byte
      get-word drop    \ Checksum,
      get-long drop    \ Length
   then
;
: offset16  ( -- )  offset16? on  ;
headerless
: (version2)  ( spread -- )
   fc-spread @ negate  interpreter-pointer +!      \ Undo previous increment
   fc-spread !
   fc-spread @        interpreter-pointer +!      \ Do new increment
   offset16
   fcode-checksum? @  fc-spread @  and  if
      verify-fcode-prom-checksum
   else
      get-byte drop   \ Pad byte
      get-word drop   \ Checksum,
      get-long drop   \ Length
   then
;
headers
: start0  ( -- )  0 (version2)  ;
: start1  ( -- )  1 (version2)  ;
: start2  ( -- )  2 (version2)  ;
: start4  ( -- )  4 (version2)  ;
headerless
\ The byte code interpreter loop.  adr is the starting address of
\ the byte code stream, and spread is the distance between successive
\ bytes in the stream.
: byte-interpret  ( adr spread -- )
   warning @ >r  warning off
   fc-spread @ >r  interpreter-pointer @ >r  more-bytes? @ >r  offset16? @ >r

   fc-spread !   interpreter-pointer !   more-bytes? on

   begin
      more-bytes? @
   while
      next-fc-token do-byte-compile
   repeat

   r> offset16? !  r> more-bytes? !  r> interpreter-pointer !  r> fc-spread !
   r> warning !
;
headers
