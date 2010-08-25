\ cstrings.fth 2.8 01/04/06
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Conversion between Forth-style strings and C-style null-terminated strings.
\ cstrlen and cscount are defined in cmdline.fth

decimal

headerless
0 value cstrbuf		\ Initialized in
chain: init  ( -- )  d# 258 alloc-mem is cstrbuf  ;

headers
\ Convert an unpacked string to a C string
: $cstr  ( adr len -- c-string-adr )
   \ If, as is usually the case, there is already a null byte at the end,
   \ we can avoid the copy.
   2dup +  c@  0=  if  drop exit  then
   >r   cstrbuf r@  cmove  0 cstrbuf r> + c!  cstrbuf
;

\ Convert a packed string to a C string
: cstr  ( forth-pstring -- c-string-adr )  count $cstr  ;

\ Find the length of a C string, not counting the null byte
: cstrlen  ( c-string -- length )
   dup  begin  dup c@  while  ca1+  repeat  swap -
;
\ Convert a null-terminated C string to an unpacked string
: cscount  ( cstr -- adr len )  dup cstrlen  ;

headers
