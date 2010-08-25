\ substrin.fth 2.6 94/09/06
\ Copyright 1985-1990 Bradley Forthware

\ High level versions of string utilities needed for sifting

only forth also hidden also definitions
decimal
forth definitions
\ True if str1 is a substring of str2
: substring?   ( adr1 len1  adr2 len2 -- flag )
   rot tuck     ( adr1 adr2 len1  len2 len1 )
   <  if  drop 2drop false  else  tuck $=  then
;

headerless
: unpack-name ( anf where -- where) \ Strip funny chars from a name field
   swap name>string rot pack
;
hidden definitions
: 4drop  ( n1 n2 n3 n4 -- )  2drop 2drop  ;
: 4dup   ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )  2over 2over  ;

headers
forth definitions
: sindex  ( adr1 len1 adr2 len2 -- n )
   0 >r
   begin  ( adr1 len1 adr2' len2' )
      \ If string 1 is longer than string 2, it is not a substring
      2 pick over  >  if  4drop  r> drop  -1 exit   then
      4dup substring?  if  4drop r> exit  then
      \ Not found, so remove the first character from string 2 and try again
      swap 1+ swap 1-
      r> 1+ >r
   again
;
only forth also definitions
