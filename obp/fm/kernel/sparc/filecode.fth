\ filecode.fth 2.9 02/05/02
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Code words to support the file system interface - Sunrise versions

headerless
\ signed mixed mode addition (same as + on the Sunrise)
code ln+   (s n1 n2 -- n3 )  sp  scr  pop   tos scr  tos  add   c;

\ &ptr is the address of a pointer.  fetch the pointed-to
\ character and post-increment the pointer

code @c@++ ( &ptr -- char )
   tos    scr   get     \ Fetch the pointer
   tos    sc1   move	\ Copy of the address
   scr 0  tos   ldub    \ Get the byte
   scr 1  scr   add     \ Increment the pointer
   scr    sc1   put     \ Replace the pointer
c;

\ &ptr is the address of a pointer.  store the character into
\ the pointed-to location and post-increment the pointer

code @c!++ ( char &ptr -- )
   tos    scr    get     \ Fetch the pointer
   sp     sc1    pop     \ char in sc1
   sc1    scr 0  stb     \ Put the byte
   scr 1  scr    add     \ Increment the pointer
   scr    tos    put     \ Replace the pointer
   sp     tos    pop     \ Fixup top of stack
c;

\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"

code split-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
			\ char in tos
   sp 0 /n*  sc1  nget	\ len1
   sp 1 /n*  scr  nget	\ adr1
   sp 1 /n*  sp   sub	\ Make room for extra return value

   scr sc1   scr  add	\ Point to end
   %g0 sc1   sc3  sub	\ Index counts up from -len1
   sc3 1     sc3  sub	\ Account for pre-increment

   ahead
   sc3 1  sc3  addcc		\ Delay: Increment and test counter
   begin

      tos sc2       cmp		\ Compare to delimiter
      = if annul		\ Exit if delimiter found
      sc3 1  sc3  addcc		\ Delay: Increment and test counter

         sc1 sc3    sc1  add	\ Compute len2
	 sc1   sp 1 /n*  nput	\ .. and store on stack

	 scr sc3    scr  add	\ Compute adr1+len2
	 scr   sp 0 /n*  nput	\ .. and store on stack

         %g0 sc3    tos  sub	\ Return len1-len2
	 next
      then

   but then
   0= until annul
   scr sc3  sc2  ldub	\ Delay: Get the next character

   \ The test character is not present in the input string

   scr   sp 0 /n*   nput	\ Store adr1+len2 on stack
   %g0   tos        move	\ Return rem-len=0
c;

headers

nuser delimiter  \ delimiter actually found at end of word

nuser file

:-h struct ( -- 0 )  00  ;-h

\ Run-time action for fields
code-field: dofield
\itc   sp           adec
   tos         sp   put    \ Push the tos register
\t16   apf     scr  lduh   \ Get the structure member offset
\t32   apf     scr  ld     \ Get the structure member offset
   'user file  sc1  ld     \ Get the structure base address
64\ 'user file /l + sc2  ld
64\  sc1  h# 20     sc1  sllx
64\  sc2  sc1       sc1  or
   sc1 scr     tos  add    \ Return the structure member address
c;

\ Assembles the code field when metacompiling a field
:-h file-field-cf   ( -- )   dofield place-cf-t  ;-h

\ Metacompiler defining word for creating fields
:-h file-field  \ name  ( offset scrze -- offset' )
   " file-field-cf" header-t  over
\t32-t l,-t
\t16-t w,-t
   +   ?debug
;-h
