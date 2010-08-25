\ parses1.fth 2.8 95/04/19
\ Copyright 1985-1990 Bradley Forthware

headers
: +string  ( adr len -- adr len+1 )  1+  ;
: -string  ( adr len -- adr+1 len-1 )  swap 1+  swap 1-  ;

\ Splits a string into two halves before the first occurrence of
\ a delimiter character.
\ adra,lena is the string including and after the delimiter
\ adrb,lenb is the string before the delimiter
\ lena = 0 if there was no delimiter

: split-before  ( adr len delim -- adra lena  adrb lenb )
   split-string 2swap
;
alias $split left-parse-string

: cindex  ( adr len char -- [ index true ]  | false )
   false swap 2swap  bounds  ?do  ( false char )
      dup  i c@  =  if  nip i true rot  leave  then
   loop                           ( false char  |  index true char )
   drop
;

\ Splits a string into two halves after the last occurrence of
\ a delimiter character.
\ adra,lena is the string after the delimiter
\ adrb,lenb is the string before and including the delimiter
\ lena = 0 if there was no delimiter

\ adra,lena is the string after the delimiter
\ adrb,lenb is the string before and including the delimiter
\ lena = 0 if there was no delimiter

: split-after  ( adr len char -- adra lena  adrb lenb  )
   >r  2dup + 0                       ( adrb lenb  adra 0 )

   \ Throughout the loop, we maintain both substrings.  Each time through,
   \ we add a character to the "after" string and remove it from the "before".
   \ The loop terminates when either the "before" string is empty or the
   \ desired character is found

   begin  2 pick  while               ( adrb lenb  adra lena )
      over 1- c@  r@ =  if \ Found it ( adrb lenb  adra lena )
         r> drop 2swap  exit          ( adrb lenb  adra lena )
      then
      2swap 1-  2swap swap 1- swap 1+ ( adrb lenb  adra lena )
   repeat                             ( adrb lenb  adr1 len1 )

   \ Character not found.  lenb is 0.
   r> drop  2swap
;
headers
