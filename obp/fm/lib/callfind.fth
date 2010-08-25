\ callfind.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ Callfinder
\ The place to start searching is implementation-dependent.
\ The best place would be at the lowest Forth definition in the
\ dictionary.

decimal

: .calls  ( cfa -- )
   hi-segment-base 
   begin ( cfa search-start )
      2dup hi-segment-limit  tsearch  ( acf last [ found-at ] f )
   while  dup  .caller cr    ( acf last found-at)
      exit?  if  exit  then
      nip ta1+
   repeat drop
   ( acf )
   lo-segment-base 
   begin ( cfa search-start )
      2dup lo-segment-limit  tsearch  ( acf last [ found-at ] f )
   while  dup  .caller cr    ( acf last found-at)
      exit?  if  exit  then
      nip ta1+
   repeat 2drop
;
only forth also definitions
