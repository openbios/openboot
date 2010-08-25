\ @(#)dump.fth 2.6 95/04/19
\ From Perry/Laxen, largely verbatim
\ Copyright 1985-1990 Bradley Forthware

\ The dump utility gives you a formatted hex dump with the ascii
\ text corresponding to the bytes on the right hand side of the
\ screen.  In addition you can use the SM word to set a range of
\ memory locations to desired values.  SM displays an address and
\ its contents.  You can go forwards or backwards depending upon
\ which character you type. Entering a hex number changes the
\ contents of the location.  DL can be used to dump a line of
\ text from a screen.

decimal

only forth also hidden also  definitions

headers
defer dc@ ' c@ is dc@
headerless
: .2   (s n -- )   <#   u# u#   u#>   type   space   ;
: d.2   (s addr len -- )   bounds ?do   i dc@ .2   loop   ;
: emit.   (s char -- )
   d# 127 and dup printable? 0=  if  drop  ascii .  then  emit
;
: emit.ln (s addr len -- )
   bounds ?do   i dc@ emit.   loop
;
: dln   (s addr --- )
   ??cr   dup  n->l 8 u.r   2 spaces   8 2dup d.2 space
   over + 8 d.2 space
   d# 16 emit.ln
;

: ?.n    (s n1 n2 -- n1 )
   2dup = if  ." \/"  drop   else   2 .r   then   space   ;
: ?.a    (s n1 n2 -- n1 )
   2dup = if  ." v"  drop   else   1 .r   then  ;

: .head   (s addr len -- addr' len' )
   ??cr over d# 16 >> d# 16 >> ?dup  if
      8 u.r 2 spaces
   else
      10 spaces
   then
   swap   dup d# -16 and  swap  d# 15 and
   8 0 do   i ?.n   loop   space  d# 16 8 do   i ?.n   loop
   space   d# 16 0 do  i ?.a  loop   rot +
;
headers

: (dump) ( addr len -- )
   base @ -rot  hex   .head  ( addr len )
   dup 0= if 1+ then
   bounds do   i dln  exit? ?leave  16 +loop   base !
;
also forth definitions

: dump ( addr len -- )      ['] c@ is dc@ (dump)  ;
: du   ( addr -- addr+64 )  dup d# 64 dump   d# 64 +  ;

only forth also definitions
