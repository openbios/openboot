\ strings.fth 2.10 96/07/25
\ Copyright 1985-1994 Bradley Forthware

\ Primitives to concatenate ( "cat ), and print ( ". ) strings.
decimal
headerless

h# 260 buffer: string2

headerless0

: save-string  ( pstr1 -- pstr2 )  string2 "copy string2  ;

headers
: $number  ( adr len -- true | n false )
   $dnumber?  case
      0 of  true        endof
      1 of  false       endof
      2 of  drop false  endof
   endcase
;

headerless
: $hnumber  ( adr len -- true | n false )  push-hex  $number  pop-base  ;
headers

\ Here is a direct implementation of $number, except that it doesn't handle
\ DPL, and it allows , in addition to . for number punctuation
\ : $number  ( adr len -- n false | true )
\    1 0 2swap                    ( sign n adr len )
\    bounds  ?do                  ( sign n )
\       i c@  base @ digit  if    ( sign n digit )
\        swap base @ ul* +        ( sign n' )
\       else                      ( sign n char )
\          case                   ( sign n )
\             ascii -  of  swap negate swap  endof    ( -sign n )
\             ascii .  of                    endof    ( sign n )
\             ascii ,  of                    endof    ( sign n )
\           ( sign n char ) drop nip 0 swap leave     ( 0 n )
\          endcase
\       then
\    loop                         ( sign|0 n )
\    over  if                     ( sign n )
\       * false                   ( n' false )
\    else                         ( 0 n )
\       2drop true                ( true )
\    then
\ ;
