\ format.fth 2.3 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ Output Formatting
decimal
headerless0

variable lmargin    0 lmargin !
variable rmargin   79 rmargin !
: ?line  (s n -- )
   #out @ +    rmargin @ >  if  cr  lmargin @ spaces  then
;
: ?cr  (s -- )  0 ?line  ;
: to-column  (s column -- )  #out @  -  1 max spaces  ;

variable tabstops  8 tabstops !
: ?to-column ( string-length starting-column -- )
   tuck + rmargin @ >  if
      drop cr  lmargin @ spaces
   else
      #out @ - spaces
   then
;
: .tab  ( string-length -- )
   \ Find the next tab stop after the current cursor position
   rmargin @ tabstops @ +  dup lmargin @  do   ( string-length target-column )
      i  #out @   >=  if  drop i leave  then   ( string-length target-column )
   tabstops @ +loop                            ( string-length target-column )
   ?to-column
;
headers
