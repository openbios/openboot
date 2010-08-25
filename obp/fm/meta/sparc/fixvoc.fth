\ fixvoc.fth 2.3 93/11/01
\ Copyright 1985-1990 Bradley Forthware

only forth meta also forth also definitions
\ Nasty kludge to resolve the to pointer to the does> clause of vocabulary
\ within "forth".  The problem is that the code field of "forth" contains
\ a call instruction to the does> clause of vocabulary.  This call is a 
\ forward reference which cannot be resolved in the same way as compiled
\ addresses.

: used-t  ( definer-acf child-acf -- )
\t32-t  \ Construct a call instruction to the definer acf
\t32-t  2dup - n->l 2 >> h# 4000.0000 or       ( definer-acf child-acf call-instr )
\t32-t  swap [ also meta ] l!-t [ previous ]   ( definer-acf )  drop
\t16-t  [ also meta ] token!-t [ previous ]
;

: fix-vocabularies  ( -- )
   [""] <vocabulary>  also symbols  find   previous  ( acf true | str false )
   0= abort" Can't find <vocabulary> in symbols"
   dup resolution@ >r               ( acf )  ( RS: <vocabulary>-adr )
   dup first-occurrence@                     ( acf occurrence )
   \ Don't let fixall muck with this entry later
   0 rot first-occurrence!		     ( occurrence )
   begin  another-occurrence?  while         ( occurrence )
      dup [ meta ] rlink@-t [ forth ] swap   ( next-occurrence occurrence )
      r@ swap used-t
   repeat
   r> drop
;
