\ voccom.fth 3.15 02/05/02
\ Copyright 1985-1990 Bradley Forthware
\ Copyright: Copyright 1999-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright: Use is subject to license terms.

\ Common routines for vocabularies, independent of name field
\ implementation details

headers
: wordlist  ( -- wid )  (wordlist) lastacf  ;
: vocabulary  ( "name" -- )  header (wordlist)  ;

defer $find-next
' ($find-next) is $find-next

\  : insert-after  ( new-node old-node -- )
\     dup link@        ( new-node old-node next-node )
\     2 pick link!     ( new-node old-node )
\     link!
\  ;
tuser hidden-voc   origin-t is hidden-voc

: not-hidden  ( -- )  hidden-voc !null-token  ;

\ WARNING: current-voc is patched later by fm/lib/hashcach.fth
: hide   (s -- )
   current-voc hidden-voc token!
   last @
   [ifexist] xref-hide-hook  dup name>string xref-hide-hook 2drop [then]
   n>link current-voc remove-word
;

\ WARNING: hidden-voc is patched later  by fm/lib/hashcach.fth
: reveal  (s -- )
   hidden-voc get-token?  if			( xt )
      last @					( xt )
      [ifexist] xref-reveal-hook dup name>string xref-reveal-hook  2drop [then]
      n>link 0  rot  insert-word		( )
      not-hidden
   then
;

#threads-t constant #threads

auser voc-link     \ points to newest vocabulary

headerless

: voc-link,  (s -- )  \ links this vocabulary to the chain
   lastacf  voc-link link@  link,   voc-link link!
;

hex
0 value fake-name-buf

headers
: fake-name  ( xt -- anf )
   base @ >r hex
   <#  0 hold ascii ) hold  u#s  ascii ( hold  u#>   ( adr len )
   fake-name-buf $save       ( adr len )
   tuck + 1- tuck            ( anf len adr+len )
   swap 1- h# 80 or swap c!  ( adr )
   r> base !
;

\ Returns the name field address, or if the word is headerless, the
\ address of a numeric string representing the xt in parentheses.
: >name  ( xt -- anf )
   dup >name?  if  nip  else  drop fake-name  then
;

: immediate  (s -- )  last @  n>flags  dup c@  40 or  swap c!  ;
: immediate?  (s xt -- flag )  >flags c@  40 and  0<>  ;
: flagalias  (s -- )  last @  n>flags  dup c@  20 or  swap c!  ;
: .last  (s -- )  last @ .id  ;

: current-voc  ( -- voc-xt )  current token@  ;
: context-voc  ( -- voc-xt )  context token@  ;

0 value canonical-word
headerless

: duplicate-notification ( adr len voc -- adr len voc )
   where (compile-time-warning)
   >r 2dup type r> ."  isn't unique " cr
;

chain: init  ( -- )
   d# 20 alloc-mem  is fake-name-buf
   d# 32 alloc-mem  is canonical-word
;

headers
: $canonical  ( adr len -- adr' len' )
   caps @  if  d# 31 min  canonical-word $save  2dup lower  then
;

: $create-word  ( adr len voc-xt -- )
   >r $canonical
[ifexist] xref-header-hook
   xref-header-hook
[then]
  r> warning @  if
      3dup  $find-word  if   ( adr len voc-xt  xt )
         drop  duplicate-notification
      else                   ( adr len voc-xt  adr len )
         2drop
      then
   then                      ( adr len voc-xt )
   $make-header
;

: ($header)  (s adr len -- )  current-voc $create-word  ;

' ($header) is $header

: (search-wordlist)  ( adr len vocabulary -- false | xt +-1 )
   $find-word  dup  0=  if  nip nip  then
;
: search-wordlist  ( adr len vocabulary -- false | xt +-1 )
   >r $canonical r> (search-wordlist)
;
: $vfind  ( adr len vocabulary -- adr len false | xt +-1 )
   >r $canonical r> $find-word
;

: find-fixup  ( adr len alf true  |  adr len false -- xt +-1  |  adr len 0 )
   dup  if                                        ( adr len alf true )
      drop nip nip                                ( alf )
      dup link> swap l>name n>flags c@            ( xt flags )
      dup  h# 20 and  if  swap token@ swap  then  ( xt' flags )  \ alias?
      h# 40 and  if  1  else  -1  then                           \ immediate?
   then
;

headerless
2 /n-t * ualloc-t user tbuf
headers
: follow  ( voc-acf -- )  tbuf token!  0 tbuf na1+ !  ;

: another?  ( -- false  |  anf true )
   tbuf na1+ @  tbuf token@  next-word  ( 0 | alf true )
   if  dup tbuf na1+ !  l>name  true  else  false  then
;

: another-word? ( alf|0  voc-acf -- alf' voc-acf anf true  |  false )
   tuck next-word  if    ( voc-acf alf' )
      tuck l>name  true  ( alf' voc-acf anf true )
   else                  ( voc-acf )
      drop  false        ( false )
   then
;

\ Forget

headerless
: trim   (s alf voc-acf -- )
   >r 0                                       ( adr 0 )
   begin  r@ next-word   while                ( adr alf )
      2dup <=  if  dup r@ remove-word  then   ( adr alf )
   repeat                                     ( adr )
   r> 2drop
;

headers

auser fence        \ barrier for forgetting

: (forget)   (s adr -- )	\ reclaim dictionary space above "adr"

   dup fence a@ u< ( -15 ) abort" below fence"  ( adr )

   \ Forget any entire vocabularies defined after "adr"

   voc-link                          ( adr first-voc )
   begin                             ( adr voc )
      \ XXX this may not work with a mixed RAM/ROM system where
      \ RAM is at a lower address than ROM
      link@ 2dup  u<                 ( adr voc' more? )
   while                             ( adr voc )
      dup voc> current-voc =         ( adr voc error? )
      ( -15 ) abort" I can't forget the current vocabulary."
      \ Remove the voc from the search order
      dup voc> (except               ( adr voc )
      >voc-link                      ( adr voc-link )
   repeat                            ( adr voc )
   dup voc-link link!                ( adr voc )

   \ For all remaining vocabularies, unlink words defined after "adr"

   \ We assume that we haven't forgotten all the vocabularies;
   \ otherwise this will fail.  Forgetting all the vocabularies would
   \ crash the system anyway, so we don't worry about it.
   begin                             ( adr voc )
      2dup voc> trim                 ( adr voc )
      >voc-link                      ( adr voc-link-adr )
      another-link? 0=               ( adr voc' )
   until                             ( adr )
   l>beginning  here - allot     \ Reclaim dictionary space
;

: forget   (s -- )
   safe-parse-word   current-voc $vfind  $?missing  drop
   >link  (forget)
;

: marker  ( "name" -- )
   create  #user @ ,
   does> dup @  #user !  body> >link  (forget)
;

chain: init ( -- ) ['] ($find-next) is $find-next  ;
