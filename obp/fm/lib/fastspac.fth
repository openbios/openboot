\ fastspac.fth 2.4 94/09/01
\ Copyright 1985-1994 Bradley Forthware

\ Version of "spaces" which uses "type" instead of "emit", for systems
\ where "type" is significantly faster than "emit".

headerless
create spacebuf  here 80 allot  80 blank
headers
: spaces  ( #spaces -- )
   begin  dup  0>  while
      dup 80 min            ( #remaining #thistime )
      spacebuf over type -  ( #remaining )
   repeat                   ( #remaining )
   drop
;
