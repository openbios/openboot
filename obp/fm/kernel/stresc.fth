id: @(#)stresc.fth 1.17 02/05/02
purpose:
copyright: Copyright 1991-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Copyright 1985-1990 Bradley Forthware

\ These words use the string-scanning routines to get strings out of
\ the input stream.

\ ",  --> given string, emplace the string at here and allot space
\ ,"  --> accept a "-terminated string and emplace it.
\ "   --> accept a "-terminated string and leave addr len on the stack
\ ""  --> accept a blank delimited string and leave it's address on the stac
\ [""]--> accept a blank delimited string and emplace it.
\         At run time, leave it's address on the stack

\  The improvements allow control characters and 8-bit binary numbers to
\  be embedded into string literals.  This is similar in principle to the
\  "\n" convention in C, but syntactically tuned for Forth.
\
\  The escape character is '"'.  Here is the list of escapes:
\
\     ""	"
\     "n	newline
\     "r	carret
\     "t	tab
\     "f	formfeed
\     "l	linefeed
\     "b	backspace
\     "!	bell
\     "^x	control x, where x is any printable character
\     "(HhHh)   Sequence of bytes, one byte for each pair of hex digits Hh
\               Non-hex characters will be ignored
\
\     "<whitespace> terminates the string, as usual
\
\     " followed by any other printable character not mentioned above is
\          equivalent to that character.
\
\  This new syntax is completely backwards compatible with old code, since
\  the only legal previous usage was "<whitespace>
\
\  Contrived example:
\
\  	" This is "(01,328e)"nA test xyzzy "!"! abcdefg""hijk"^bl"
\
\                   ^^^^^^  ^              ^ ^         ^     ^
\                  3 bytes  newline      2 bells       "     control b
\
\  The "(HhHhHhHh) should come in particularly handy.
\
\  Note: "n (newline) happens to be the same as "l (linefeed) under Unix,
\  but this is not true for all operating systems.


[ifndef] run-time
headerless
nuser stringbuf
nuser "select
nuser '"temp

\ Packed strings are 255 bytes + 1 NULL + 1 Paranoia.
h# 258 constant /stringbuf

\ Alloc an 4K buffer for string use
chain: init  ( -- )
   h# 1000 alloc-mem dup stringbuf !  '"temp !
   0 "select !
;

\ Each string temp buffer is 512 bytes long.
\ Note this is longer than a packed string can deal with - this is intentional
headers
: "temp  ( -- adr )
   "select dup @ tuck 1+ 7 and swap !	( n )
   d# 9 << '"temp @ + 0 over c!		( n )
;

: $save  ( adr1 len1 adr2 -- adr2 len1 )  pack count  ;

: $add ( src,len dest,len -- dest,len' )
   2 pick over + >r over >r		( src,len dest,len )
   +					( str,len dest' )
   swap cmove				( )
   r> r>				( dest,len' )
;

: $cat  ( adr len  pstr -- )  \ Append adr len to the end of pstr
   >r r@ count nip   ( addr len len' )   ( r: pstr )     
   d# 255 swap - min ( addr len' )       ( r: pstr )
   r@ count +        ( adr len end-adr ) ( r: pstr )
   swap dup >r       ( adr endadr len )  ( r: pstr len )
   cmove r> r>       ( len pstr )
   dup c@ rot + swap c!
;

headerless
: add-char  ( buffer char -- )
   over count + c!
   dup c@ ca1+
   swap c!
;

: nextchar  ( adr len -- false | adr' len' char true )
   dup  0=  if  nip exit  then	( adr len )
   over c@ >r  1 /string  r>	( adr' len' char )
   caps @  if lcc  then  true
;

: nexthex  ( adr len -- false | adr' len' digit true )
   begin
      nextchar  if         ( adr' len' char )
	 d# 16 digit  if   ( adr' len' digit )
	    true true      ( adr' len' digit true done )
	 else              ( adr' len' char )
	    drop false     ( adr' len' notdone )
	 then              ( adr' len' digit true done | adr' len' notdone )
      else                 (  )
	 false true        ( false done )
      then
   until
;
: get-hex-bytes  ( strbuf -- )
   >r				(  ) ( r: strbuf )
   ascii ) parse		( adr len ) ( r: strbuf )
   begin  nexthex  while	( adr' len' digit1 ) ( r: strbuf )
      >r  nexthex  0= ( ?? ) abort" Odd number of hex digits in string"
      r>			( adr'' len'' digit2 digit1 ) ( r: strbuf )
      4 lshift +		( adr'' len'' byte ) ( r: strbuf )
      r@ swap add-char		( adr'' len'' ) ( r: strbuf )
   repeat r> drop		(  )
;
\ : get-char  ( -- char )  input-file @ fgetc  ;
: get-char  ( -- char|-1 )
   source  >in @  /string  if  c@  1 >in +!  else  drop -1  then
;

headers
: get-string  ( -- adr len )
   "temp					( strbuf )
   begin					( strbuf )
      dup ascii " parse  rot  $cat dup		( strbuf strbuf )
      get-char  dup bl <=  if			( strbuf strbuf <bl )
         2drop count				( adr,len )
[ifexist] xref-string-hook  xref-string-hook  [then]
         exit					( adr,len )
      then					( strbuf strbuf char )
      case
         ascii n of  newline            add-char  endof
         ascii r of  carret             add-char  endof
         ascii t of  control I          add-char  endof
         ascii f of  control L          add-char  endof
         ascii l of  linefeed           add-char  endof
         ascii b of  control H          add-char  endof
         ascii ! of  bell               add-char  endof
         ascii ^ of  get-char h# 1f and add-char  endof
         ascii ( of  get-hex-bytes                endof
         ( default ) add-char false
      endcase					( strbuf )
   again					( strbuf )
;

: .(  \ string)  (s -- )
   ascii ) parse
[ifexist] xref-string-hook  xref-string-hook  [then]
   type
; immediate

\ : (   \ string  (s -- )  \ Skips to next )
\    ascii ) parse 2drop
\ ; immediate
[then]

: ",    (s adr len -- )
   dup 2+ taligned  here swap  note-string  allot  place
;

[ifndef] run-time
: ,"  \ string"  (s -- )
   get-string  ",
;

: ."  \ string"  (s -- )
   +level compile (.")   ," -level
; immediate

: s"  \ string   (s -- adr len )
   ascii " parse
   state @  if  compile (") ",  else  "temp $save  then
; immediate

: "   \ string"  (s -- adr len )
   get-string
   state @  if  compile (") ",  else  "temp $save  then
; immediate

: [""]  \ word  (s Compile-time: -- )
        (s Run-time: -- pstr )
   compile ("s)  safe-parse-word ",
; immediate

\ Obsolete
: ["]   \ string"  (s -- str )
   compile ("s)    ,"
; immediate

: \  \ rest-of-line  (s -- )      \ skips rest of line
   -1 parse
[ifexist] xref-string-hook  xref-string-hook  [then]
    2drop
; immediate

: compile-string  ( adr len -- )
   state @  if
      compile ("s) ",
   else
      "temp pack 
   then
;
: ""   \ name  ( -- pstr )
   safe-parse-word  compile-string
; immediate

: p"   \ string"  ( -- pstr )
   get-string  compile-string
; immediate

: c"   \ string"  ( -- pstr )
   ascii " parse
   compile-string
; immediate
[then]

create nullstring 0 c, 0 c,

\ Words for copying strings
\ Places a series of bytes in memory at to as a packed string
: place     (s adr len to-adr -- )  pack drop  ;

: place-cstr  ( adr len cstr-adr -- cstr-adr )
   >r  tuck r@ swap cmove  ( len ) r@ +  0 swap c!  r>
;

: even      (s n -- n | n+1 )  dup 1 and +  ;

\ Nullfix
: +str  (s pstr -- adr )     count + 1+ taligned ;

\ Copy a packed string from "from-pstr" to "to-pstr"
: "copy (s from-pstr to-pstr -- )      >r count r> place ;

\ Copy a packed string from "from-pstr" to "to-pstr", returning "to-pstr"
: "move (s from-pstr to-pstr -- to-pstr )   >r count r> pack  ;

\ : count      (s adr -- adr+1 len )  dup 1+   swap c@   ;
: /string  ( adr len cnt -- adr' len' )  tuck - -rot + swap  ;

: printable?  ( n -- flag ) \ true if n is a printable ascii character
   dup bl th 7f within  swap  th 80  th ff  between  or
;
: white-space? ( n -- flag ) \ true is n is non-printable? or a blank
   dup printable? 0=  swap  bl =  or
;

: -leading  ( adr len -- adr' len' )
   begin  dup  while   ( adr' len' )
      over c@  white-space? 0=  if  exit  then
      swap 1+ swap 1-
   repeat
;

: -trailing  (s adr len -- adr len' )
   dup  0  ?do   2dup + 1- c@   white-space? 0=  ?leave  1-    loop
;

: upper  (s adr len -- )  bounds  ?do i dup c@ upc swap c!  loop  ;
: lower  (s adr len -- )  bounds  ?do i dup c@ lcc swap c!  loop  ;

nuser caps
: f83-compare  (s adr adr2 len -- -1 | 0 | 1 )
   caps @  if  caps-comp  else  comp  then
;
headers
\ Unpacked string comparison
: +-1  ( n -- -1|0|+1 )  0< 2* 1+  ;
: compare  (s adr1 len1 adr2 len2 -- same? )
   rot 2dup 2>r min             ( adr1 adr2 min-len )  ( r: len2 len1 )
   comp dup  if                 ( +-1 )
      2r> 2drop                 ( +-1 )  \ Initial substrings differ
   else                         ( 0 )
      drop  2r> -               ( diff ) \ Initial substrings are the same
      \ This is tricky.  We want to convert zero to zero, positive
      \ numbers to -1, and negative numbers to +1.  Here's how it works:
      \ "dup  if  ..  then" leave 0 unchanged, and nonzero number are
      \ transformed as follows:
      \       +n  -n
      \ 0>    -1   0
      \ 2*    -2   0
      \ 1+    -1   1
      dup  if  0> 2* 1+  then
   then
;
\ $= can be defined as "compare 0=", but $= is used much more often,
\ and doesn't require all the tricky argument fixups, so it makes
\ sense to define $= directly, so it runs quite a bit faster.
: $=  (s adr1 len1 adr2 len2 -- same? )
   rot tuck  <>  if  3drop false exit  then   ( adr1 adr2 len1 )
   comp 0=
;
