\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: strings.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)strings.fth 1.1 04/09/07
purpose: String utility functions
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: null$ ( -- adr 0 ) " " ;

: byte-compare ( adr1 len1 adr2 len2 -- same? )
   rot tuck =  if  comp 0=  else  3drop false  then
;

\ Skip over 'n' characters in a string.
: /string ( adr len n -- adr' len' )  tuck - >r + r> ;

\ String compare.
: $=  ( adr1 len1 adr2 len2 -- same? )
   byte-compare
;

\ Case-insensitive string compare.
: $case= ( adr1 len1 adr2 len2 -- same? )
   rot tuck <>  if  3drop false exit  then		( adr1 adr2 len1 )
   0  ?do 
      over i ca+ c@ lcc  over i ca+ c@ lcc  <>  if
         2drop false unloop exit
      then
   loop
   2drop true
;

\ Decimal string to number conversion.
: $dnumber ( adr,len -- n false | true )
   base @ >r  decimal  $number  r> base !
;

\ Hexadecimal string to number conversion.
: $hnumber ( adr,len -- n false | true )
   base @ >r  hex  $number  r> base !
;

\ Return a pointer to the first occurence of a character in a string.
: strchr ( adr len char -- adr' )
   >r  over ca+  swap
   begin  2dup >  while
      dup c@  r@ =  if  nip r> drop exit  then  ca1+
   repeat
   r> 3drop 0
;

\ Locate the first occurence of a substring in a string. Returns a
\ pointer to the located substring, or 0 if the substring is not 
\ found. If the substring is of zero length, a pointer to the 
\ string will be returned.
: strstr ( str$ substr$ -- adr | 0 )
   2 pick over <  if				( adr len substr$ ) 
      2drop 2drop 0 exit			( 0 )
   then						( adr len substr$ )
   rot over - 1+  0  ?do			( adr substr$ ) 
      3dup comp 0=  if				( adr substr$ ) 
         2drop unloop exit			( adr )
      then					( adr substr$ )
      rot  ca1+  -rot				( adr' substr$ )
   loop						( adr' substr$ )
   3drop 0					( 0 )
;

\ Skip over all occurences of specified characters at the beginning
\ of the string.
: string-skipchars ( str$ chars$ -- str$' )
   2over bounds ?do					( str$ chars$ )
      2dup i c@ strchr if				( str$ chars$ )
         2swap  1 /string  2swap			( str$' chars$ )
      else						( str$ chars$ )
         leave						( str$ chars$ )
      then						( str$ chars$ )
   loop							( str$' chars$ )
   2drop						( str$' )
;

\ Get the next token from the text string. Tokens are delimited by one 
\ or more characters specified in the delimiter string.
: strtok ( text$ delim$ -- rem$ tok$ )
   2swap 2over  string-skipchars  2swap			( text$' delim$ )
   2over bounds ?do					( text$' delim$ )
      2dup  i c@ strchr if				( text$' delim$ )
         2drop  i c@ left-parse-string unloop exit	( rem$ tok$ )
      then						( text$' delim$ )
   loop							( text$' delim$ )
   2drop null$ 2swap					( null$ tok$ )
;

\ Split a string into 2 substrings.
: string-split ( adr len n -- adr+n len-n adr n )
   >r  2dup r@ /string  2swap drop r>
;

\ Get contents of a quoted string.
: qdstring>string ( $ -- $' )
   over c@ ascii " =  if  
      1 /string  ascii " left-parse-string  2swap 2drop
   then
;

\ Concatenate strings.
: strcat ( adr1 len1 adr2 len2 -- adr1 len1+len2 )
   2over 2over 2swap ca+ swap move  nip +
;

\ Store string as a null-terminated string and return pointer past the
\ terminating null character.
: $cstrput ( str len dest-adr -- end-adr )
   swap  2dup ca+ >r  move  0 r@ c!  r> ca1+
;

: cstrlen ( cstr -- length )
   dup  begin  dup c@  while  ca1+  repeat  swap -
;

: cscount ( cstr -- adr len )  dup cstrlen ;

: upper ( adr len -- )  bounds  ?do  i dup c@ upc swap c!  loop ;
: lower ( adr len -- )  bounds  ?do  i dup c@ lcc swap c!  loop ;

d# 64  instance buffer:  hexascii-buf

\ Get ASCII hexadecimal representation of octet stream 
: octet-to-hexascii ( data datalen -- buf buflen )
   hexascii-buf 0  2swap				( buf 0 data datalen )
   dup 0=  over d# 32 >  or  if				( buf 0 data datalen )
      2drop exit					( buf 0 )
   then							( buf 0 data datalen )
   base @ >r  hex					( buf 0 data datalen )
   bounds ?do						( buf len )
      i c@  <# u# u# u#>				( buf len $ )
      2over ca+  swap move				( buf len )
      2+						( buf len' )
   loop							( buf len' )
   2dup upper						( buf len' )
   r> base !						( buf buflen )
;

\ Get octet stream representation of ASCII hexadecimal string
: hexascii-to-octet ( data datalen -- buf buflen )
   hexascii-buf 0  2swap				( buf 0 data datalen )
   dup 0=  over d# 128 > or  over  2 mod 0<>  or if	( buf 0 data datalen )
      2drop exit					( buf 0 )
   then							( buf 0 data datalen )
   bounds ?do						( buf len )
      i 2 $hnumber  if					( buf len )
         drop 0 unloop exit				( buf 0 )
      then						( buf len n )
      >r  2dup ca+  r> swap c!				( buf len )
      1+						( buf len' )
   2 +loop						( buf len' )
;

headers
