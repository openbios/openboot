\ needs.fth 2.5 94/11/15
\ Copyright 1985-1994 Bradley Forthware

\ Implements needs and \needs.  These work as follows:
\
\ needs foo tools.fth
\
\ If foo is not defined, the file tools.fth will be loaded, which should
\ define foo.  If foo is already defined, nothing will happen.
\
\ \needs foo <arbitrary Forth commands>
\
\ If foo is not defined, the rest of the line is executed, else it is ignored

: needs  \ wordname filename  ( -- )
   safe-parse-word $canonical $find  if  ( cfa +-1 )
      drop  safe-parse-word 2drop
   else
      2drop safe-parse-word included
   then
;
: \needs ( -- ) ( Input Stream: desired-word  more-forth-commands )
   safe-parse-word $canonical $find  if  ( cfa +-1 )
      drop  postpone \
   else                                  ( adr len )
      2drop
   then
;
