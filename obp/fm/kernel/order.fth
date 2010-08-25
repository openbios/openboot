id: @(#)order.fth 2.13 03/12/11 09:22:49
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ Search order.  Maintains the list of vocabularies that are
\ searched while interpreting Forth code.

decimal
16 equ nvocs
nvocs constant #vocs	\ The # of vocabularies that can be in the search path

nvocs /token-t * ualloc-t user context   \ vocabulary searched first
tuser current      \ vocabulary which gets new definitions

#vocs /token * constant /context
: context-bounds  ( -- end start )  context /context bounds  ;

headerless
: shuffle-down  ( adr -- finished? )
   \ The loop goes from the next location after adr to the end of the
   \ context array.
   context-bounds drop  over /token +  ?do    ( adr )
       \ Look for a non-null entry, replace the current entry with that one,
       \ and replace that one with null
       i get-token?  if                       ( adr acf )
          over token!   i !null-token  leave  ( adr )
       then                                   ( adr )
   /token +loop
   drop
;
headers
: clear-context  ( -- )
   context-bounds  ?do  i !null-token  /token +loop
;
headerless
: compact-search-order  ( -- )
   context-bounds  ?do
      i get-token? 0=  if   i shuffle-down  else  drop  then
   /token +loop
;
headers
: (except  ( voc-acf -- )   \ Remove a vocabulary from the search order
   context-bounds  ?do
      dup  i token@  =  if  i  !null-token  then
   /token +loop
   drop compact-search-order
;

nuser prior        \ used for dictionary searches
: $find   ( adr len -- xt +-1 | adr len 0 )
   2dup 2>r
   $canonical        ( adr' len' )
   prior off         ( adr len )
   false             ( adr len found? )
   context-bounds  ?do
      drop
      i get-token?  if                    ( adr len voc )

         \ Don't search the vocabulary again if we just searched it.
         dup prior @ over prior !  =  if  ( adr len voc )
            drop false                    ( adr len false )
         else                             ( adr len voc )
	    $find-word  dup ?leave        ( adr len false )
         then                             ( adr len false )

      else                                ( adr len voc )
         false                            ( adr len false )
      then                                ( adr len false )
   /token +loop                           ( adr len false  |  xt +-1 )
   ?dup  if
      2r> 2drop
   else
      2drop  2r> false
   then
;
: find  ( pstr -- pstr false  |  xt +-1 )
   dup >r count $find  dup  0=  if  nip nip  r> swap  else  r> drop  then
;

\ The also/only vocabulary search order scheme

decimal
: >voc  ( n -- adr )  /token *  context +  ;

vocabulary root   root definitions-t

: also  ( -- )  context  1 >voc   #vocs 2- /token *  cmove>  ;

: (min-search)  root also re-heads also ;
defer minimum-search-order  ' (min-search) is minimum-search-order
: forth-wordlist  ( -- wid )  ['] forth  ;
: get-current  ( -- )  current token@  ;
: set-current  ( -- )  current token!  ;

: get-order  ( -- vocn .. voc1 n )
   0  0  #vocs 1-  do
      i >voc token@ non-null?  if  swap 1+  then
   -1 +loop
;
: set-order  ( vocn .. voc1 n -- )
   dup #vocs >  abort" Too many vocabularies in requested search order"
   clear-context
   0  ?do  i >voc token!  loop
;

: only  ( -- )
   clear-context
\   ['] root  #vocs 1- >voc  token!
   minimum-search-order
;

: except  \ vocabulary-name  ( -- )
   ' (except
;
: seal  ( -- )  ['] root (except  ;
: previous   ( -- )
   1 >voc  context  #vocs 2- /token *  cmove
   #vocs 2- >voc  !null-token
;

: definitions  ( -- )  context token@ set-current  ;

: order   ( -- )
   ." context: "
   get-order  0  ?do  .name  loop
   4 spaces  ." current: "  get-current .name
;
: vocs   ( -- )
   voc-link  begin  another-link?  while  ( link )
      #out @ 64 >  if  cr  then
      dup  voc>  .name
      >voc-link
   repeat
;

vocabulary forth   forth definitions-t

\ only forth also definitions
\ : (cold-hook   ( -- )   (cold-hook  only forth also definitions  ;
\ headers

chain: init  ( -- )  only forth also definitions  ;

\ "Hidden" is a vocabulary that can be used to contain implementation words
\ that shouldn't appear in the forth dictionary.  It was popular before we
\ had the option to compile such words headerless (and also save space).
\ Headerless words made the decompiler less useful, so we added a way for
\ developers to restore headerful behavior

vocabulary hidden   hidden definitions-t

\ "Re-heads" is the vocabulary that will hold restored headers and make them
\ searchable to the decompiler.  It will be somewhat of a while before we
\ actually use it, but we need it defined now so that we can get it into the
\ search-order early on in the game.

vocabulary re-heads

  forth definitions-t
