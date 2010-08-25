\ alias.fth 2.6 94/09/04
\ Copyright 1985-1994 Bradley Forthware

\ Alias makes a new word which behaves exactly like an existing
\ word.  This works whether the new word is encountered during
\ compilation or interpretation, and does the right thing even
\  if the old word is immediate.

decimal

: setalias  ( xt +-1 -- )
   0> if  immediate  then                ( acf )
   flagalias
   lastacf  here - allot   token,
;
: alias  \ new-name old-name  ( -- )
   create  hide  'i  reveal  setalias
;
