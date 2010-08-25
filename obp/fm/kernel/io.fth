\  @(#)io.fth 2.22 05/02/14
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

decimal

\ Emit is a two-level vector.
\ The low level is (emit and the high level is emit.
\ The low-level vector just selects the output device.
\ The high-level vector performs other processing such as keeping
\ track of the current position on the line, pausing, etc.
\ Terminal control with escape sequences should use the low-level vector
\ to prevent a pause from garbling the escape sequence.
\ Key is a two-level vector.
\ The low level is (key and the high level is key.
\ The low-level vector just selects the output device.
\ The high-level vector performs other processing such as switching
\ the input stream between different windows.

defer (type  ( adr len -- ) \ Low-level type; just outputs characters
defer type   ( adr len -- ) \ High-level type
defer (emit ( c -- )   \ Low level emit; just puts out the character
defer emit  ( c -- )   \ Higher level; keeps track of position on the line, etc
defer (key  ( -- c )   \ Low level key; just gets key
defer key   ( -- c )   \ Higher level; may do other nonsense
defer key?   ( -- f )   \ Is a character waiting?
defer bye    ( -- )     \ Exit to the operating system, if any
defer (interactive? ( -- f ) \ Is input coming from the keyboard?
defer interactive? ( -- f ) \ Is input coming from the keyboard?
' (interactive? is interactive?

defer prompt  ( -- )
defer quit

defer accept  ( adr len -- )	\ Read up to len characters from keyboard

defer alloc-mem  ( #bytes -- address )
defer free-mem   ( adr #bytes -- )

defer lock[    ( -- )   ' noop is lock[
defer ]unlock  ( -- )   ' noop is ]unlock

defer sync-cache  ( adr len -- )  ' 2drop is sync-cache

defer #out   ( -- adr )
defer #line  ( -- adr )
defer cr     ( -- )

\ Default actions
: key1  ( -- char )  begin  pause key?  until  (key  ;
: emit1  ( char -- )  pause (emit 1 #out +!  ;
: type1  ( adr len -- )  pause  dup #out +!  (type  ;
: default-type  ( adr len -- )
   0 max  bounds ?do  pause  i c@ (emit  loop
;
\ headerless		\ from campus version
nuser (#out        \ number of characters emitted
\ headers		\ from campus version
nuser (#line       \ the number of lines sent so far

\ Install defaults
' emit1       is emit
' type1       is type
' key1        is key
' (#out       is #out
' (#line      is #line

decimal

 7 constant bell
 8 constant bs
10 constant linefeed
13 constant carret

\ Obsolescent, but required by the IEEE 1275 device interface
nuser span			\ number of characters received by expect

\ A place to put the last word returned by blword
0 value 'word

: expect  ( adr len -- )  accept span !  ;

defer newline-pstring
: newline-string  ( -- adr len )  newline-pstring count  ;
: newline  ( -- char )  newline-string + 1-  c@  ; \ Last character

: space  (s -- )   bl emit   ;
: spaces   (s n -- )   0  max  0 ?do  space  loop  ;
: backspaces  (s n -- )  dup negate #out +!  0 ?do bs (emit loop  ;
: beep  (s -- )  bell (emit  ;
: (lf  (s -- )  1 #line +!  linefeed (emit  ;
: (cr  (s -- )  carret (emit  ;
: lf   (s -- )  #out off  (lf  ;
: crlf   (s -- )  (cr lf  ;

0 value tib

headerless
0 value #-buf
chain: init  ( -- )
   40 dup alloc-mem + is #-buf
   /tib   alloc-mem   is tib
;
headers

nuser base         \ for numeric input and output

nuser hld          \ points to last character held in #-buf
: hold   (s char -- )   -1 hld +!   hld @ c!   ;
: hold$  ( adr len -- )
   dup  if
      1- bounds swap  do  i c@ hold  -1 +loop
   else
      2drop
   then
;
: <#     (s -- )     #-buf  hld  !  ;
: sign   (s n -- )  0< if  ascii -  hold  then  ;
\ for upper case hex output, change 39 to 7
: >digit (s n -- char )  dup 9 >  if  39 +  then  48 +  ;
: u#     (s u1 -- u2 )
   base @ u/mod  ( nrem u2 )   swap  >digit  hold    ( u2 )
;
: u#s    (s u -- 0 )     begin  u#  dup   0=  until  ;
: u#>    (s u -- addr len )    drop  hld  @  #-buf  over  -  ;

: mu/mod (s d n1 -- rem d.quot )
   >r  0  r@  um/mod  r>  swap  >r  um/mod  r>
;

: #      (s ud1 -- ud2 )
   base @ mu/mod ( nrem ud2 )  rot     >digit  hold    ( ud2 )
;
: #s     (s ud -- 0 0 )  begin   #  2dup or  0=  until  ;
: #>     (s ud -- addr len )     drop  u#>  ;

: (u.)  (s u -- a len )  <# u#s u#>   ;
: u.    (s u -- )       (u.)   type space   ;
: u.r   (s u len -- )     >r   (u.)   r> over - spaces   type   ;
: (.)   (s n -- a len )   dup abs  <# u#s   swap sign   u#>   ;
: (.d)  ( n -- adr len )  base @ >r  decimal  (.)  r> base !  ;
: (.h)  ( n -- adr len )  base @ >r  hex      (.)  r> base !  ;
: s.    (s n -- )       (.)   type space   ;
: .r    (s n l -- )     >r   (.)   r> over - spaces   type   ;

[ifndef] run-time
headerless
: (ul.) (s ul -- a l )  n->l  <# u#s u#>   ;
headers
: ul.   (s ul -- )      (ul.)   type space   ;
headerless
: ul.r  (s ul l -- )    >r   (ul.)   r> over - spaces   type  ;

: (l.)  (s l -- a l )   dup l->n swap  abs   <# u#s  swap sign  u#>   ;
headers
: l.    (s l -- )       base @ d# 10 = if (l.) else (ul.) then type space   ;
headerless
: l.r   (s l l -- )     >r   (l.)   r> over - spaces   type   ;
headers
[then]

\ smart print that knows that signed hex numbers are uninteresting
: n.    (s n -- ) base @ 10 = if s. else u. then  ;
: .     (s n -- )       (.)   type space   ;
: ?     (s addr -- )    @  n.  ;

: (.s        (s -- )
   depth 0 ?do  depth i - 1- pick n.  loop
;
: .s         (s -- )
   depth 0<
   if   ." Stack Underflow "  sp0 @ sp!
   else depth
        if (.s else ." Empty " then
   then
;
: ".  (s pstr -- )  count type  ;
