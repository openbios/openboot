\ ftrace.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ Display a Forth stack backtrace
only forth also hidden also  forth definitions

: ftrace  ( -- )   \ Forth stack
   %ip >saved .traceline
   %rp >saved  rssave-end swap  (rstrace   
;

only forth also definitions
