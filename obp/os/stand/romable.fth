\ romable.fth 2.5 94/09/01
\ Copyright 1985-1990 Bradley Forthware

\ Warns about stores into the dictionary to help catch non-ROMable code.
forth definitions
headerless
: variable   nuser  ;
: 2variable  2 /n* ualloc user  ;
: lvariable  /l ualloc user  ;
: n!  ( val adr -- )  !  ;
: shared-variable  nuser  ;
headers

