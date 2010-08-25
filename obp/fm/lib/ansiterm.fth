id: @(#)ansiterm.fth 1.1 94/09/01
purpose: Terminal control for ANSI terminals
copyright: Copyright 1994 FirmWorks  All Rights Reserved.

headerless
: .esc[        ( -- )     control [ (emit  [char] [ (emit  ;
: .esc[x       ( c -- )   .esc[ (emit  ;
headers

: left         ( -- )     [char] D .esc[x  -1 #out  +!  ;
: right        ( -- )     [char] C .esc[x   1 #out  +!  ;
: up           ( -- )     [char] A .esc[x  -1 #line +!  ;
: down         ( -- )     [char] B .esc[x   1 #line +!  ;
: insert-char  ( c -- )   [char] @ .esc[x  (emit ;
: delete-char  ( -- )     [char] P .esc[x  ;
: kill-line    ( -- )     [char] K .esc[x  ;
: kill-screen  ( -- )     [char] J .esc[x  ;
: insert-line  ( -- )     [char] L .esc[x  ;
: delete-line  ( -- )     [char] M .esc[x  ;
: dark         ( -- )     [char] 7 .esc[x  [char] m (emit  ;
: light        ( -- )     [char] m .esc[x  ;

: at-xy  ( col row -- )
    2dup #line !  #out !
    base @ >r decimal
    .esc[   1+ (.) (type  [char] ; (emit  1+ (.) (type  [char] H (emit
    r> base !
;
: page         ( -- )  0 0 at-xy  kill-screen  ;

false [if] 
headerless
: color:  ( adr len "name" -- )
   create ",  does> .esc[  count (type  [char] m (emit
;
headers

" 0"    color: default-colors
" 1"    color: bright
" 2"    color: dim
" 30"   color: black-letters
" 31"   color: red-letters
" 32"   color: green-letters
" 33"   color: yellow-letters
" 34"   color: blue-letters
" 35"   color: magenta-letters
" 36"   color: cyanletters
" 37"   color: white-letters
" 40"   color: black-screen
" 41"   color: red-screen
" 42"   color: green-screen
" 43"   color: yellow-screen
" 44"   color: blue-screen
" 45"   color: magenta-screen
" 46"   color: cyan-screen
" 47"   color: white-screen
[then]
