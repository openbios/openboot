\ ccalls.fth 2.4 94/05/30
\ Copyright 1985-1990 Bradley Forthware

\ Defining words to construct Forth interfaces to C subroutines
\ and Unix system calls.  This is strongly implementation dependent, and will
\ require EXTENSIVE modifications for other Forth systems, other CPU's,
\ and other operating systems.
\
\ Defines:
\
\ syscall:    ( syscall# -- )        ( Input Stream: name arg-spec )
\ subroutine: ( adr -- )             ( Input Stream: name arg-spec )
\
\ This version is for SPARC Unix systems where ints, longs, and addresses
\ are all the same size.  Under this assumption, the only thing we have to
\ do to the stack arguments is to convert Forth strings to C strings.

decimal
only forth assembler also forth also hidden also definitions

headerless
variable #args  variable #results  variable arg#

: system-call ( syscall# -- )
   [ also assembler ]
   %g2 sc1 move
   ( call# )  %g1  move
   %g0 0  always  trapif
   u< if
      0    up  ['] errno >user#  st   \ Delay slot
      %o0  up  ['] errno >user#  st
      -1  %o0  move
   then
   sc1 %g2 move
   [ previous ]
;
\ : subroutine-call   ( subroutine-adr -- )
\    [ also assembler ]
\    ( adr )  call
\    %g2 sc1 move		\ Delay slot
\    sc1 %g2 move
\    [ previous ]
\ ;
: wrapper-call  ( call# -- )
   [ also assembler ]
					\ Get address of system call table
   'user syscall-vec  scr  nget
   bubble
   ( call# ) scr swap  scr nget		\ Address of routine
   %g1 sc1 move
   scr %g0  %o7  jmpl
   %g2 sc2 move		\ Delay slot
   sc1 %g1 move
   sc2 %g2 move
   [ previous ]
;

: sys:  \ name ( call# -- )
   code
;
: %o#  ( -- reg )  [ also assembler ]  arg# @ %o0 +  [ previous ]  ;
: arg  ( -- )
   arg# @  if
      [ also assembler ]  sp  arg# @ 1- /n*   %o#  nget  [ previous ]
   else
      [ also assembler ]  tos  %o0  move  [ previous ]
   then
   1 arg# +!
;
: str  ( -- )
   arg# @  if
      [ also assembler ]  sp   arg# @ 1- /n*   %o#  nget
                          %o#  1               %o#  add [ previous ]
   else
      [ also assembler ]  tos  1  %o0  add  [ previous ]
   then
   1 arg# +!
;   
: res  ( -- )  1 #results +!  ;
: }  ( -- )
   #results @  if
      #args @ 0=  if  [ also assembler ]
         tos  sp  push
      [ previous ]  then

      #args @ 1 > if  [ also assembler ]
         sp  #args @ 1- /n*  sp   add
      [ previous ]  then

      [ also assembler ]  %o0 tos  move   [ previous ]
   else   \ No results
      #args @     if  [ also assembler ]
         sp  #args @ 1- /n*  tos  nget
         sp  #args @    /n*  sp   add
      [ previous ]  then
   then
;
: scan-args ( -- )
   #args off
   0   ( marker )
   begin
      bl word  1+ c@
      case
      ascii l of  ['] arg    true  endof 
      ascii i of  ['] arg    true  endof 
      ascii a of  ['] arg    true  endof
      ascii s of  ['] str    true  endof 
      ascii - of             false endof
      ascii } of  ." Where's the -- ?" abort endof
      ( default ) ." Bad type specifier: " dup emit abort
    endcase
  while
    1 #args +!
  repeat
  arg# off
  begin  ?dup  while  execute  repeat
;
: do-call  ( ??? 'call-assembler -- ) \ ??? is args specific to the call type
   execute
;
: scan-results ( -- )
   #results off
   begin
      bl word  1+ c@
      case
      ascii l of                  true  endof 
      ascii i of                  true  endof 
      ascii a of                  true  endof 
      ascii s of  ." Can't return strings yet" abort   true  endof 
      ascii } of                  false endof
      ( default ) ." Bad type specifier: " dup emit
      endcase
   while
      1 #results +!
   repeat
   }
;
only forth hidden  also forth assembler  also forth  definitions
: {  \ args -- results }  ( -- )
   scan-args  do-call  scan-results    next
;

headers
: syscall:  \ name  ( syscall# -- syscall# 'system-call )
   ['] system-call
   code   current @ context !    \ don't want to be in assembler voc
;
\ : subroutine:  \ name  ( adr -- adr 'subroutine-call )
\    ['] subroutine-call code   current @ context !
\ ;

only forth also definitions
