\ dumphead.fth 2.4 92/01/28
\ Copyright 1985-1990 Bradley Forthware

\ Modify 'dispose' to dump out all heads, not just transient ones.
\ This file is loaded later, because we need 'over-vocabulary'.

: head.  ( alf -- )  l>name dup new-name>  f.name  ;
: dumpheads  ( -- )
   header:? on    \ Dump using 'header:'
   voc-link  begin  another-link?  while
      ['] head.  over voc>  over-vocabulary     ( voc-link )
      >voc-link
   repeat
;

\ New dispose, calls old and then dumps all remaining heads
: dispose  ( -- )
   dispose
   base @ >r hex
   open-headerfile
   dumpheads
   close-headerfile
   r> base !
;

