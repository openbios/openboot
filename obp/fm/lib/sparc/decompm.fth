\ decompm.fth 2.9 94/06/11
\ Copyright 1985-1990 Bradley Forthware

\ Machine/implementation-dependent definitions
decimal
headerless

only forth also hidden also  definitions
: dictionary-base  ( -- adr )  origin  ;

\  forth definitions
\  defer hi-segment-base   ' here   is hi-segment-base
\  defer hi-segment-limit  ' here   is hi-segment-limit
\  defer lo-segment-base   ' origin is lo-segment-base
\  defer lo-segment-limit  ' here   is lo-segment-limit
\  hidden definitions

: ram/rom-in-dictionary?  ( adr -- flag )
   dup  #talign 1-  and  0=  if
      dup  lo-segment-base lo-segment-limit  within
      swap hi-segment-base hi-segment-limit  within  or
   else
      drop false
   then
;

' ram/rom-in-dictionary? is in-dictionary?

\ True if adr is a reasonable value for the interpreter pointer
: reasonable-ip?  ( adr -- flag )
   dup  in-dictionary?  if  ( ip )
      #talign 1- and 0=  \ must be token-aligned
   else
      drop false
   then
;

\ variable isvar  \ already defined
\ create iscreate \ already defined

headerless0
only forth also definitions
headers
