\ nlist.fth 2.5 01/04/06
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

\ : struct  ( -- 0 )  0  ;			Use lib/struct.fth
\ : field  ( offset size -- offset' )
\   create  over , +
\   does> @ +
\ ;

headerless
struct  \ symbol table entry
   /l field sym_strx
   /c field sym_type
   /c field sym_other
   /w field sym_desc
   /l field sym_value
constant /aout-symbol

\ Interesting values for sym_type
\ 5 constant external-procedure			\ unused dup
\ 7 constant external-variable			\ unused dup

headers
