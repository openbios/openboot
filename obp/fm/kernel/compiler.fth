\ compiler.fth 2.22 01/05/18
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved.

hex

nuser state        \ compilation or interpretation
nuser dp           \ dictionary pointer

\ This can't use token@ and token! because the dictionary pointer
\ needs to temporarily contain odd byte offset because of c,
: here  (s -- addr )  dp @  ;

fffffffc value limit
: unused  ( -- #bytes )  limit here -  ;

defer allot-error
: allot  (s n -- )
   dup pad + d# 100 + limit  u>  if  allot-error  then
   dup  dp +!   ( n )
   dup 0<  if	\ Clear relocation bitmap if alloting a negative amount
      here swap negate clear-relocation-bits
   else
      drop
   then
;

[ifdef] run-time

:-h immediate ( -- )
\ Don't fix the target header because there isn't one!
\   lastacf-t @ 1-  th 40 toggle-t       \ fix target header
   \ We can't do this with immediate-h because the symbol we need to make
   \ immediate isn't necessarily the last one for which a header was
   \ created.  It could have been a forward reference, with the header
   \ created long ago.
   lastacf-s @ >flags  th 40 toggle        \ fix symbol table
;-h

: allot-abort  (s size -- size )
   ." Dictionary overflow - here "  here .  ." limit " limit .  cr
   ( -8 ) abort
;

[else]

: allot-abort  (s size -- size )
   ." Dictionary overflow - here "  here .  ." limit " limit .  cr
   ( -8 ) abort
;

[then]

' allot-abort is allot-error

: ,      (s n -- )       here   /n allot   unaligned-!   ;
: c,     (s char -- )    here  dup set-swap-bit  /c allot   c!   ;
: w,     (s w -- )       here   /w allot   w!   ;
: l,     (s l -- )       here   /l allot   unaligned-l!   ;
64\ : x,     (s x -- )       here   /x allot   unaligned-!   ;
: d,     (s d -- )       here   2 /n* allot   unaligned-d!   ;

: compile,  (s cfa -- )  token, ;
: compile  (s -- )   ip> dup ta1+ >ip   token@ compile,  ;

: ?pairs  (s n1 n2 -- )   <>  ( -22 ) abort" Control structure mismatch" ;

[ifndef] run-time

\ Compiler and state error checking
: ?comp   (s -- )  state @  0= ( -14 ) abort" Compilation Only " ;
: ?exec   (s -- )  state @     ( -29 ) abort" Execution Only " ;

: $defined   (s -- adr len 0 | xt +-1 )  safe-parse-word $find  ;
: $?missing  ( +-1 | adr len 0 -- +-1 )
   dup 0=  if  drop  .not-found  ( -13 ) abort  then
;
: 'i  ( "name" -- xt +-1 )  $defined $?missing  ;
: literal     (s n -- )
\t16   dup -1  h# fffe  between  if
\t16      compile (wlit) 1+ w,
\t16   else
\t16      compile  (lit)  ,
\t16   then

64\ \t32   dup -1 h# 0.ffff.fffe n->l between  if
64\ \t32      compile (llit) 1+ l,
64\ \t32   else
    \t32      compile (lit) ,
64\ \t32   then
;  immediate
: lliteral  (s l -- )  [compile] literal  ; immediate
: dliteral  (s l -- )  compile (dlit) d,  ; immediate

: safe-parse-word  ( -- adr len )
   parse-word dup 0=  ( -16 ) abort" Unexpected end-of-line"
;
: char  \ char (s -- n )
   safe-parse-word drop c@
;
: [char]  \ char  (s -- )
   char  1 do-literal
; immediate
: ascii  \ char (s -- n )
   char  1 do-literal
; immediate
: control  \ char  (s -- n )
   char  bl 1- and  1 do-literal
; immediate

: '   \ name  (s -- cfa )
   'i drop
;
: [']  \ name  (s -- )  ( Run time: -- acf )
   +level ' compile (') compile, -level
; immediate
: [compile]  \ name  (s -- )
   ' compile,
; immediate
: postpone  \ name  (s -- )
   'i  0<  if  compile compile  then  compile,
; immediate

: recurse  (s -- )  lastacf compile,  ; immediate

\ : dumpx  \ name  (s -- )
\   blword 10 dump
\ ;

: abort"  \ string"  (s -- )
   +level  compile (abort")  ,"  -level
; immediate

[then]

\ Control Structures

decimal
headerless
nuser saved-dp
nuser saved-limit
nuser level
headers
[ifdef] run-time
: +level  ( -- )  ;
: -level  ( -- )  ;
[else]
headerless
h# 400 /token-t * constant /compile-buffer
nuser 'compile-buffer
: compile-buffer  ( -- adr )  'compile-buffer @  ;

chain: init  ( -- )
   level off   /compile-buffer alloc-mem 'compile-buffer !
;
: reset-dp  ( -- )  saved-dp @ dp !  saved-limit @ is limit  ;

headers
: 0level  ( -- )  level @  if  level off  reset-dp  then  ;

: +level  ( -- )
   level @  if
      1 level +!
   else
      state @ 0=  if	\ If interpreting, begin temporary compilation
         1 level !  here saved-dp !  limit saved-limit !
	 compile-buffer dp !  compile-buffer /compile-buffer +  is limit
	 ]
      then
   then
;
: -level  ( -- )
   state @ 0= ( -22 ) abort" Control structure mismatch"
   level @  if
      -1 level +!
      level @ 0=  if
         \ If back to level 0, execute the temporary definition
         compile unnest  reset-dp
         [compile] [  compile-buffer >ip
      then
   then
;
[then]

headerless
: +>mark    (s acf -- >mark )  +level compile,  here 0 branch,  ;
: +<mark    (s -- <mark )      +level  here  ;
: ->resolve (s >mark -- )      here over - swap branch!  -level  ;
: -<resolve (s <mark acf -- )  compile,  here - branch,  -level  ;
headers

: but      ( m1 m2 -- m2 m1 )  swap  ;
: yet      ( m -- m m )  dup  ;
: cs-pick  ( mn .. m0 n -- mn .. m0 mn )  pick  ;
: cs-roll  ( mn .. m0 n -- mn-1 .. m0 mn )  roll  ;

: begin   ( -- <m )        +<mark				; immediate
: until   ( <m -- )        ['] ?branch -<resolve		; immediate
: again   ( <m -- )        ['] branch  -<resolve		; immediate

: if      ( -- >m )        ['] ?branch +>mark			; immediate
: ahead   ( -- >m )        ['] branch  +>mark			; immediate
: then    ( >m -- )        ->resolve				; immediate

: repeat  ( >m <m -- )     [compile] again      [compile] then	; immediate
: else	  ( >m1 -- >m2 )   [compile] ahead  but [compile] then	; immediate
: while   ( <m -- >m <m )  [compile] if     but			; immediate

: do      ( -- >m <m )     ['] (do)    +>mark     +<mark	; immediate
: ?do     ( -- >m <m )     ['] (?do)   +>mark     +<mark	; immediate
: loop    ( >m <m -- )     ['] (loop)  -<resolve  ->resolve	; immediate
: +loop   ( >m <m -- )     ['] (+loop) -<resolve  ->resolve	; immediate

\ XXX According to ANS Forth, LEAVE and ?LEAVE no longer have to be immediate
: leave   ( -- )   compile (leave)                              ; immediate
: ?leave  ( -- )   compile (?leave)                             ; immediate

[ifnexist] >user
: >user  (s pfa -- addr-of-user-var )
\t32 l@
\t16 w@
   up@ +
;
[then]

: user#,  ( #bytes -- user-var-adr )
   here swap ualloc
\t32   l,
\t16   w,
   >user
;

[ifndef] run-time
: .id     (s anf -- )  name>string type space  ;
: .name   (s acf -- )  >name .id  ;
[then]

nuser warning      \ control of warning messages
-1       is warning

[ifndef] run-time

\ Dr. Charles Eaker's case statement
\ Example of use:
\ : foo ( selector -- )
\   case
\     0  of  ." It was 0"   endof
\     1  of  ." It was 1"   endof
\     2  of  ." It was 2"   endof
\     ( selector) ." **** It was " dup u.
\   endcase
\ ;
\ The default clause is optional.
\ When an of clause is executed, the selector is NOT on the stack
\ When a default clause is executed, the selector IS on the stack.
\ The default clause may use the selector, but must not remove it
\ from the stack (it will be automatically removed just before the endcase)

\ At run time, (of) tests the top of the stack against the selector.
\ If they are the same, the selector is dropped and the following
\ forth code is executed.  If they are not the same, execution continues
\ at the point just following the the matching ENDOF

: case   ( -- 0 )   +level  0                            ; immediate
: of     ( -- >m )  ['] (of)     +>mark                  ; immediate
: endof  ( >m -- )  ['] (endof)  +>mark  but  ->resolve  ; immediate

: endcase  ( 0 [ >m ... ] -- )
   compile (endcase)
   begin  ?dup  while  ->resolve  repeat
   -level
; immediate

[then]
