id: @(#)extra.fth 3.15 03/12/08 13:22:13
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware
copyright: Use is subject to license terms.

\ Definitions originally from kerncode.fth which are not used in the
\ "run-time" version.
hex

\ Execute a Forth word given a pointer to a code field address
code perform ( addr-of-acf -- )
   tos 0      scr  rtget
   sp         tos  get
   scr base   %g0  jmpl
   sp              ainc
end-code

\ Select a vocabulary thread by hashing the lookup name.
\ Hashing function:  Use the lower 2 bits of the first character in
\ the name to select one of 4 threads in the array pointed-to by voc-ptr.
headerless
code hash  ( str-addr voc-apf -- thread )
   \ The next 2 lines are equivalent to ">threads", which in this
   \ implementation happens to be the same as ">body >user"
\t32   tos 8   tos   ld		\ Get the user number
\t16   tos 2   tos   lduh	\ Get the user number
   up tos  tos   add	\ Find the address of the threads

   sp      scr   pop
   scr 1   scr   ldub
   bubble
   scr 3   scr   and
\t16   scr 1   scr   sll
\t32   scr 2   scr   sll
   tos scr tos   add
c;
headers
\ Search a vocabulary thread (link) for a name matching string.
\ If found, return its code field address and -1 if immediate, 1 if not
\ immediate.  If not found, return the string and 0.

\ Name field:
\     name: forth-style packed string, no tag bits
\     flag: 40 bit is immediate bit
\ Padding is optionally inserted between the name and the flags
\ so that the byte after the flag byte is on an even boundary.

\t32 code search-thread ( string link origin -- acf -1  | acf 1  | string 0 )
\t32    sp  tos  pop      \ Discard origin; we already have it in a register
\t32 \ Registers:
\t32 \ tos    alf of word being tested
\t32 \ scr    string
\t32 \ sc1    name being tested
\t32 \ sc2    # of characters left to test
\t32 \ string is kept on the top of the external stack
\t32
\t32    begin
\t32       tos base   cmp    0<>	\ Test for end of list
\t32    while
\t32       tos /token  sc1  add		\ Get name address of word to test
\t32       sp          scr  get    	\ Get string address
\t32       bubble
\t32       scr 0    sc2  ldub		\ get the name field length
\t32       begin
\t32          scr 0  sc3  ldub		\ Compare 2 characters
\t32          sc1 0  sc4  ldub
\t32 	 bubble
\t32          sc3 sc4     cmp
\t32       0= while			\ Keep looking as long as characters match
\t32 	 nop
\t32          scr 1  scr  add		\ Increment byte pointers
\t32          sc2 1  sc2  subcc		\ Decrement byte counter
\t32          0< if			\ If we've tested all chars, the names match.
\t32          sc1 1  sc1  add		\ Delay slot
\t32             sc1 0   tos  ldub	\ Get flags byte into tos register
\t32
\t32 \dtc        sc1 4   sc1  add	\ Now find the code field by
\t32 \dtc        sc1 -4  sc1  and	\ aligning to the next 4 byte boundary
\t32
\t32 \itc        sc1 2   sc1  add	\ Now find the code field by
\t32 \itc        sc1 -2  sc1  and	\ aligning to the next 2 byte boundary
\t32
\t32 	    tos 20  %g0  andcc  	\ Test the alias flag
\t32 	    0<> if
\t32        nop
\t32 	       sc1 0      sc1  rtget	\ Get acf
\t32           sc1 base   sc1  add	\ Relocate
\t32 \itc   else
\t32 \itc      nop
\t32 \itc      sc1 0   sc2  lduh	\ Is is a realigned code word?
\t32 \itc      sc2 0        cmp
\t32 \itc      = if  nop
\t32 \itc         sc1 2 sc1 add		\ Align to 4 byte boundary
\t32 \itc      then
\t32
\t32        then
\t32
\t32 	    sc1     sp   put		\ Replace string on stack with acf
\t32 	    tos 40  %g0  andcc  	\ Test the immediate flag
\t32 	    0<> if
\t32 	       -1   tos  move		\ Not immediate  \ Delay slot
\t32 	    ( else )
\t32 	       1    tos  move		\ Immediate
\t32 	    then
\t32             inhibit-delay
\t32 	    next
\t32          then
\t32       repeat
\t32          nop
\t32
\t32       \ The names did not match, so check the next name in the list
\t32       tos 0     tos  rtget		\ Fetch next link
\t32       tos base  tos  add
\t32    repeat
\t32       nop
\t32
\t32    \ If we get here, we've checked all the names with no luck
\t32    0  tos   move
\t32 c;

code ($find-next)  ( adr len link -- adr len alf true  |  adr len false )
\ Registers:
\ tos    alf of word being tested
\ scr    string
\ sc1    anf of word being tested
\ sc2    # of characters left to test
\ sc3    character from string
\ sc4    character from name
\ sc5    string length
\ string is kept on the top of the external stack

   sp  1 /n*      scr  nget	\ Get string address

   sp  0 /n*      sc5  nget	\ get the name field length

   ahead
   scr sc5        scr  add	\ Point to end of string

   begin
      tos /token  tos  sub	\ >link
      tos 1       sc1  sub	\ sc1 points to count byte at *end* of string

      %g0 sc5     sc2  subcc	\ Set starting loop index and cond. codes
      begin
	 sc1 sc2  sc4  ldub	\ Get character from name field
	 scr sc2  sc3  ldub	\ Get character from search string
	 sc3 sc4       cmp	\ Compare 2 characters
      <> until
         sc2 1    sc2  addcc	\ Increment loop index

      0> if			\ If we've tested all name chars, we
	 sc1 0      sc4  ldub	\ get the count byte from the name field
	 sc4 h# 1f  sc4  and	\ may have a match; check the count byte
	 sc4 sc5       cmp	\ Compare count bytes
	 = if
	 nop
	    tos   sp   push	\ Push alf above str$
	    -1    tos  move	\ True on top of stack means "found"
	    next
         then
      then

      but then
      \ The names did not match, so check the next name in the list
      tos 0       tos  rtget	\ Fetch next link  ( next acf )
      tos         0    cmp		\ Test for end of list
   = until
      tos base    tos  add		\ Relocate

   \ If we get here, we've checked all the names with no luck
   0  tos   move
c;

headers
: ?negate  ( n1 n2 -- n3 )  if  negate  then  ;

code wflip ( l1 -- l2 )  \ word-swap the low two words; clear the rest.
    tos  /n 2 - 8 *  scr  slln	\  lowest word to upper word of scr
64\ tos  /n 4 - 8 *  tos  slln	\  second word to upper word of tos
    tos d# 16        tos  srln	\  second word to 2nd-from-upper word of tos
    tos       scr    tos  or	\  Join with lowest word (the rest is cleared).
64\ tos  /n 4 - 8 *  tos  srln	\  and back into place
c;

code toggle  ( addr byte-mask -- )
   sp  0 /n*  scr  nget
   bubble
   scr 0    sc1  ldub
   bubble
   sc1 tos  sc1  xor
   sc1     scr 0 stb
   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;
code log2 ( n -- log2-of-n )
   %g0  1  scr  sub	\ result -> scr  Init'l = -1; return -1 if N was zero.
   begin
      tos  %g0  %g0   subcc
   0<> while
      tos    1  tos   srln
   repeat
      scr    1  scr   add
   scr  tos  move
c;
\
\  Extract some of the rightmost bits from a cell
code bits ( mask #bits -- mask' bits )
    sp   %g0   scr    nget	\  scr <=  mask
    scr  tos   sc1    srln      \  sc1 <=  mask'
    1    sc2          set
    sc2  tos   tos    slln
    tos    1   tos    sub	\  tos <= lowbits
    scr  tos   tos    and	\  tos <= bits
    sc1  %g0   sp     nput	\  mask' => next-on-stack
c;

code s->l ( n.signed -- l )  inhibit-delay  c;
32\ code l->n ( l -- n )  inhibit-delay  c;
64\ code l->n ( l -- n )  tos 0 tos sra  c;
code n->a     ( n -- a )  inhibit-delay  c;
32\ code l->w ( l -- w )  tos d# 16  tos  sll   tos d# 16  tos  srl  c;
64\ code l->w ( l -- w )  tos d# 48  tos  sllx  tos d# 48  tos  srlx c;
32\ code n->w ( n -- w )  tos d# 16  tos  sll   tos d# 16  tos  srl  c;
64\ code n->w ( n -- w )  tos d# 48  tos  sllx  tos d# 48  tos  srlx  c;

code l>r  ( l -- )     tos rp push   sp tos pop    c;
code lr>  ( -- l )     tos sp push   rp tos pop    c;
code lr@  ( -- l )     tos sp push   rp tos get    c;

headerless
code /t* ( n -- n*/t )  tos 2  tos  sll  c;
headers

\t16 tshift-t constant tshift	\ Shift factor for offset tokens

#talign-t constant #talign	\ Alignment of tokens compiled in colon defs.

#linkalign-t constant #linkalign
/l constant #align		\ Hardware alignment: instruction, word fetches

\t16 1 tshift-t << constant #acf-align	\ Code field alignment
\t32 #acf-align-t constant #acf-align

: align  ( -- )  #align (align)  ;
: talign  ( -- )  #talign (align)  ;
: taligned  ( adr -- adr' )  #talign round-up  ;
\ headerless
: linkalign  ( -- )  #linkalign (align)  ;
headers

: u*  ( un1 un2 -- product )  um* drop  ;
