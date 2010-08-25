id: @(#)interp.fth 2.19 03/12/08 13:22:06
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1990 Bradley Forthware
copyright: Use is subject to license terms.

\ The Text Interpreter

\ Input stream parsing

\ Error reporting
defer mark-error  ' noop is mark-error
defer show-error  ' noop is show-error
: where  ( -- )  mark-error show-error  ;

: lose  ( -- )  true ( -13) abort" Undefined word encountered "  ;

\ Number parsing
hex
: >number  ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
  \ convert double number, leaving address of first unconverted byte
   begin  dup  while                  ( ud adr len )
      over c@  base @  digit          ( ud adr len  digit true  |  char false )
      0=  if  drop exit  then         ( ud adr len  digit )
      >r  2swap  r>                   ( adr len ud  digit )
      swap base @ um*  drop           ( adr len ud.low  digit ud.high' )
      rot base @ um*  d+              ( adr len  ud' )
      2swap  1 /string                ( ud' adr len )
   repeat                             ( ud' adr len )
;
: numdelim?  ( char -- flag )  dup ascii . =  swap ascii , =  or  ;
: $dnumber?  ( adr len -- [ n .. ] #cells )
   dup  0=  if  ( adr 0 )  nip  exit  then
   0 0  2swap                                         ( ud $ )
   over c@ ascii - =                                  ( ud $ neg? )
   dup  >r  negate /string                            ( ud $' )  ( r: neg? )

   \ Convert groups of digits possibly separated by periods or commas
   begin  >number  dup 1 >  while                     ( ud' $' )
      over c@ numdelim?  0=  if                       ( ud' $' )
         2drop  r> 3drop  0  exit                     ( ud' $' )
      then                                            ( ud' $' )
      1 /string                                       ( ud' $' )
   repeat                                             ( ud' $' )

   if                                                 ( ud adr )
      \ Do not accept a trailing comma, thus preventing,
      \ for example, "c," from being interpreted as a number
      c@  ascii . =  if                               ( ud )
         true                                         ( ud dbl? )
      else                                            ( ud )
         r> 3drop  0  exit
      then                                            ( ud dbl? )
   else                                               ( ud adr )
      drop false                                      ( ud dbl? )
   then                                               ( ud dbl? )

   over or  if                                        ( ud )
      r>  if  dnegate  then  2
   else
      drop  r>  if  negate  then  1
   then
;

defer do-defined    ( cfa -1 | cfa 1  -- ?? )
defer $do-undefined  ( adr len -- )

headers
defer do-literal
: (do-literal)  ( n 1 | d 2 -- n | d | )
   state @  if
      2 =  if  [compile] dliteral  else  [compile] literal  then
   else
      drop
   then
;
' (do-literal) is do-literal
defer $handle-literal?  ( adr len -- handled? )
: ($handle-literal?)  ( adr len -- handled? )
   $dnumber?  dup  if  do-literal true  then
;
' ($handle-literal?) is $handle-literal?

headers
: $compile  ( adr len -- ?? )
   2dup  2>r                        ( adr len )  ( r: adr len )
   $find  dup  if                   ( xt +-1 )
      2r> 2drop do-defined          ( )
   else                             ( adr' len' 0 )
      3drop                         ( )
      2r@ $handle-literal?  0=  if  ( )
         2r@  $do-undefined         ( )
      then
      2r> 2drop
  then
;
headerless
: interpret-do-defined  ( cfa -1 | cfa 1 -- ?? )  drop execute  ;
: compile-do-defined    ( cfa -1 | cfa 1 -- )
  0> if    execute   \ if immediate
     else  compile,  \ if not immediate
     then
;
headers
: .not-found  ( adr len -- )  (compile-time-error) where type ."  ?" cr  ;
headerless
\ Abort after an undefined word in interpret state
: $interpret-do-undefined  ( adr len -- )
   (compile-time-error)  mark-error set-abort-message  d# -13 throw
;
\ Compile a surrogate for an undefined word in compile state
: $compile-do-undefined    ( adr len -- )  .not-found  compile lose  ;

headers
defer [ immediate
headerless
: ([)  ( -- )
  ['] interpret-do-defined    is do-defined
  ['] $interpret-do-undefined is $do-undefined
  state off
;
' ([) is [

headers
defer ]
headerless
: (])  ( -- )
  ['] compile-do-defined     is do-defined
  ['] $compile-do-undefined  is $do-undefined
  state on
;
' (]) is ]

headers
\ Run-time error checking
: ?stack  ( ?? -- )
   sp@  sp0 @  swap       u<  ( -4 ) abort" Stack Underflow"
   sp@  sp0 @  ps-size -  u<  ( -3 ) abort" Stack Overflow"
;

defer ?permitted  ' noop is ?permitted

defer interpret
: (interpret  ( -- )
   begin
\     ?stack
      parse-word dup
   while
      ?permitted
      $compile
   repeat
   2drop
;
' (interpret  is interpret

\ Ensure that the cursor in on an empty line.
: ??cr  ( -- )  #out @  if  cr  then  ;

\ This hack is for users of window systems.  If you pick up with the
\ mouse an entire previous command line, including the prompt, then
\ paste it into the current line, Forth will ignore the prompt.
: ok  ( -- )  ;

defer status  ( -- )  ' noop is status


\ A hook for automatic pagination

defer mark-output  ( -- )  ' noop is mark-output


\ Prompts the user for another line of input.  Executed only if the input
\ stream is coming from a terminal.

defer (ok) ( -- )
: "ok" ." ok " ;
' "ok" is (ok)

defer reset-page
' noop is reset-page
: do-prompt  ( -- )  reset-page prompt  ;
