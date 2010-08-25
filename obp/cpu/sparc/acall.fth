\ acall.fth 2.4 94/09/06
\ Copyright 1985-1990 Bradley Forthware

\ Usage:
\    " external-procedure-name" $acall
\ or
\    " external-procedure-name" $acall: name  { args -- results }


: $acall   ( procedure-name$ -- )
   [ also assembler ]

   dictionary-size      ( procedure-name$ offset )
   here call		\ make space for relocatable addr
   -rot  $add-call	\ symtab entry

   [ previous ]
;

\ : $acall:  \ name  ( procedure-name$ -- procedure-name$ 'subroutine-call )
\    ['] $acall code   current token@ context token!
\ ;
