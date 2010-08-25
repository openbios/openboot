id: @(#)is.fth 2.10 03/12/08 13:22:08
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware
copyright: Use is subject to license terms.

\ Prefix word for setting the value of variables, constants, user variables,
\ values, and deferred words.  State-smart so it is used the same way whether
[ifndef] in-dictionary-variables
\ interpreting or compiling.  You could now use IS in place of ! where speed
\ matters, because the newer faster IS is actually 20% faster than  !  (but
\ it's still not recommended practice.  Better to use VALUE.)
[else]
\ interpreting or compiling.  Don't use IS in place of ! where speed matters,
\ because IS is much slower than ! .
[then]
\
\ Examples:
\
\ 3 constant foo
\ 4 is foo
\
\ defer money
\ ' dollars is money
\ : european ['] euros is money ;

\ IS is a "generic store".
\ IS figures out where the data for a word is stored, and replaces that data.
\ The previous implementation was not particularly fast; this is much faster.

\ This is loaded before "order.fth"
\ only forth also hidden also definitions

\  In-dictionary variables are a leftover from the earliest FORTH
\  implementations.  They have no place in a ROMable target-system
\  and we are deprecating support for them; but Just In Case you
\  ever want to restore support for them, define the command-line
\  symbol:   in-dictionary-variables
[ifdef] in-dictionary-variables
   variable isvar
[then]

\  \  Replace this next one with something we actually use
\  0 value isval

headerless

[ifdef] run-time
: is-error  ( data acf -- )  true ( -32 ) abort" inappropriate use of `is'"  ;
[else]
: is-error  ( data acf -- )  ." Can't use is with " .name cr ( -32 ) abort  ;
[then]

headers

defer to-hook
' is-error is to-hook

headerless

: >bu  ( acf -- data-adr )  >body >user  ;

create word-types
]    limit		\ value
     #user		\ user variable
     key		\ defer
[ifdef] in-dictionary-variables
     isvar		\ in-dictionary variable
[then]
     bl 		\ constant
[  origin   token,-t	\ END   \ origin should be null

create data-locs
]    >bu		\ value
     >bu		\ user variable
     >bu		\ defer
[ifdef] in-dictionary-variables
     >body		\ in-dictionary variable
[then]
     >body		\ constant
[

\  One of these words will be called when interpreting  IS ,
\  based on the word-type of the target-word.  
\  When compiling  IS , the group below will be used.
: is-user  ( n acf -- )  >bu       !  ;
: is-defer ( n acf -- )  >bu  token!  ;
: is-const ( n acf -- )  >body     !  ;

create !data-ops
]    is-user		\ value
     is-user		\ user variable
     is-defer		\ defer
[ifdef] in-dictionary-variables
     is-const		\ in-dictionary variable
[then]
     is-const		\ constant
[

\  These are the words that are compiled-in when compiling  IS
[ifnexist] (is-user)
   : (is-user)  ( n -- )  ip> dup ta1+ >ip  token@  is-user  ;
[then]
[ifnexist] (is-defer)
   : (is-defer) ( n -- )  ip> dup ta1+ >ip  token@  is-defer ;
[then]


\  We may obsolete this eventually.  Constants should stay constant...
: (is-const) ( n -- )  ip> dup ta1+ >ip  token@  is-const ;

create (!data-ops)
]    (is-user)		\ value
     (is-user)		\ user variable
     (is-defer)		\ defer
[ifdef] in-dictionary-variables
     (is-const) 	\ in-dictionary variable
[then]
     (is-const) 	\ constant
[

: associate  ( acf -- true  |  index false )
   word-type  ( n )
   word-types  begin              ( n adr )
      2dup get-token?             ( n adr n  false | acf true )
   while                          ( n adr n acf )
      word-type  = if             ( n adr )
         word-types -		  ( n index )
         \t32 2/ 2/		  ( n index ) \ equiv. of '/token /'
         \t16 2/		  ( n index )
	 nip false  exit          ( index false )
      then                        ( n adr )
      ta1+                        ( n adr' )
   repeat                         ( n adr n )
   3drop true                     ( true )
;

: +token@  ( index table -- acf )  swap ta+ token@  ;
: +execute ( index table -- )      +token@ execute  ;

: kerntype?  ( acf -- flag )
   associate  if  false  else  drop true  then  ( flag )
;

headers
: behavior  ( defer-acf -- acf2 )  >bu token@  ;

: (is  ( data acf -- )
   dup  associate  if  is-error  then   ( data acf index )
   !data-ops +execute                   ( )
;

: >data  ( acf -- data-adr )
   dup associate  if        ( acf )
      >body                 ( data-adr )
   else                     ( acf index )
      data-locs +execute    ( data-adr )
   then                     ( data-adr )
;

[ifndef] run-time
: compile-is ( acf -- )
   dup associate drop	\  Already filtered through  kerntype	( acf index )
   (!data-ops) +token@						( acf is-acf )
   token, token,
;
: do-is  ( data acf -- )
   dup kerntype?  if     ( [data] acf )
      state @  if   compile-is  else  (is   then
   else                    ( [data] acf )
      to-hook
   then
;

\ is is the word that is actually used by applications
: is  \ name  ( data -- )
   ' do-is
; immediate

\ only forth also definitions

[then]
