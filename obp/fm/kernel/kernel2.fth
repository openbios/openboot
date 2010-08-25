id: @(#)kernel2.fth 2.11 03/12/08 13:22:09
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1990 Bradley Forthware
copyright: Use is subject to license terms.

\ Kernel colon definitions
decimal
 0 constant 0     1 constant 1      2 constant 2      3 constant 3
 4 constant 4     5 constant 5      6 constant 6      7 constant 7
 8 constant 8
-1 constant true  0 constant false
32 constant bl
\ 64 constant c/l

[ifnexist] bounds
   : bounds  ( adr len -- adr+len adr )  over + swap  ;
[then]

: roll    ( nk nk-1 ... n1 n0 k -- nk-1 ... n1 n0 nk )
   >r  r@ pick   sp@ dup  na1+
   r> 1+ /n*
   cmove> drop
;



[ifnexist] ?dup
   : ?dup    ( n -- [n] n )        dup if   dup   then   ;
[then]
[ifnexist] between
   : between ( n min max -- f )    >r over <= swap r> <= and  ;
[then]
[ifnexist] within
   : within  ( n min max+1 -- f )  over -  >r - r> u<  ;
[then]

: erase      ( adr len -- )   0 fill   ;
: blank      ( adr len -- )   bl fill   ;
: pad        ( -- adr )       here 300 +   ;
: depth      ( -- n )         sp@ sp0 @ swap - /n /   ;
: clear      ( ?? -- Empty )  sp0 @ sp!  ;

: hex        ( -- )   16 base !  ;
: decimal    ( -- )   10 base !  ;
: octal      ( -- )    8 base !  ;
: binary     ( -- )    2 base !  ;

: ?enough   ( n -- )  depth 1- >   ( -4 ) abort" Not enough Parameters"  ;

hex
ps-size-t constant ps-size
rs-size-t constant rs-size

: cdump  ( adr len -- )
   base @ >r  hex
   bounds  ?do
      i 8 u.r  ." : "  i  h# 10  bounds  do
         i /l bounds  do  i c@ <# u# u# u#> type space  loop  space
      /l +loop
      i  h# 10  bounds  do
         i c@  dup  bl h# 80 within  if  emit  else  drop ." ."  then
      loop
      cr
   h# 10 +loop
   r> base !
;
: ldump  ( adr len -- )
   base @ >r  hex
   bounds  ?do
      i 8 u.r  ." : "  i  h# 10  bounds  do
         i l@ 8 u.r space space
      /l +loop
      i  h# 10  bounds  do
         i c@  dup  bl h# 80 within  if  emit  else  drop ." ."  then
      loop
      cr
   h# 10 +loop
   r> base !
;
headerless
: (compile-time-error)  ( -- ) d# 58 d# 45 fsyscall ;
: (compile-time-warning) ( -- ) d# 59 d# 45 fsyscall ;
headers

: abort  ( ?? -- )  mark-error  -1 throw  ;

\ Run-time words used by the compiler; also used by metacompiled programs
\ even if the interactive compiler is not present

nuser abort"-adr
nuser abort"-len
: set-abort-message  ( adr len -- )  abort"-len !  abort"-adr !  ;
: abort-message  ( -- adr len )  abort"-adr @  abort"-len @  ;
: (.")  ( -- )           skipstr type  ;
: (abort")   ( f -- )
   if
      (compile-time-error) mark-error  ip@ count  set-abort-message  -2 throw
   else
      skipstr 2drop
   then
;
: ?throw  ( flag throw-code -- )  swap  if  throw  else  drop  then  ;
: ("s)  ( -- str-addr )  skipstr  ( addr len )  drop 1-  ;

nuser 'lastacf         \ acf of latest definition
: lastacf  ( -- acf )  'lastacf token@  ;

