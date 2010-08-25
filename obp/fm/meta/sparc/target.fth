purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ Target configuration - SPARC

decimal

only forth also meta assembler definitions
: normal ( -- )   \ Perform target-dependent assembler initialization
;

only forth also meta definitions

: init-relocation-t ; immediate

: lobyte th 0ff and ;
: hibyte 8 >> lobyte ;

\t16-t tshift-t constant tshift-t

2 constant /w-t
4 constant /l-t
8 constant /d-t
32\ /l-t constant /n-t
64\ /d-t constant /n-t

\t16-t /w-t constant /a-t
\t32-t /l-t constant /a-t
/a-t constant /thread-t
\t16-t /w-t constant /token-t
\t32-t /l-t constant /token-t
\t16-t /w-t constant /link-t
\t32-t /l-t constant /link-t
/token-t constant /defer-t
/n-t th 800 * constant user-size-t
/n-t th 200 1- * constant ps-size-t
/n-t th 200 1- * constant rs-size-t
\t16-t /w-t constant /user#-t
\t32-t /l-t constant /user#-t

\ 32 bit host Forth compiling 32-bit target Forth
: l->n-t ; immediate
: n->l-t ; immediate
: n->n-t ; immediate
: s->l-t ; immediate

: c!-t ( n add -- ) >hostaddr c! ;
: c@-t ( target-address -- n ) >hostaddr c@ ;

\ SPARC is big-endian
: w!-t ( n add -- )
   over hibyte over c!-t  ca1+ swap lobyte swap c!-t
;
: l!-t ( l add -- ) >r lwsplit r@ w!-t r> /w-t + w!-t ;
: !-t  ( n add -- ) l!-t ;

: w@-t ( target-address -- n )
   dup c@-t 8 << swap 1+ c@-t or
;
: l@-t ( target-address -- n )
   dup >r /w-t + w@-t  r> w@-t  wljoin
;
32\ : @-t  ( target-address -- n ) l@-t ;
64\ : @-t  ( target-address -- n ) /l + l@-t ;

\ Store target data types into the host address space.
: c-t!  ( c host-address -- )  c!  ;
: w-t!  ( w host-address -- )
   over hibyte  over c-t!  ca1+  swap lobyte swap c-t!
;
: l-t!  ( l host-address -- )  >r  lwsplit  r@ w-t!  r> /w-t + w-t!  ;
32\ : n-t!  ( n host-address -- )  l-t!  ;
64\ : n-t!  ( n host-address -- )  /l + l-t!  ;

\ Next 3 are machine-independent
: c,-t ( byte -- )  dp-t @ c!-t 1 dp-t +! ;
: w,-t ( word -- )  dp-t @ w!-t /w-t dp-t +! ;
: l,-t ( long -- )  dp-t @ l!-t /l-t dp-t +! ;

32\ : ,-t ( n -- )  l,-t  ;        \ for 32 bit stacks
64\ : ,-t ( n -- )
64\    dup h# 8000.0000 and  if
64\       dup h# ffff.ff00 u>  if  -1  else  0  then
64\    else 0  then  l,-t l,-t
64\ ;
: ,user#-t ( user# -- )
\t32-t  l,-t
\t16-t  w,-t
;

: a@-t ( target-address -- target-address )
\t16-t   w@-t tshift-t <<  origin-t +
\t32-t   l@-t
;
: a!-t ( token target-address -- )
\t16-t   swap  origin-t -  tshift-t >>  swap  w!-t
\t32-t   l!-t
;
: token@-t ( target-address -- target-acf )  a@-t  ;
: token!-t ( acf target-address -- )  a!-t  ;

: rlink@-t  ( occurrence -- next-occurrence )
\t16-t   w@-t 1 <<  origin-t +
\t32-t   a@-t
;
: rlink!-t  ( next-occurrence occurrence -- )
\t16-t   swap  origin-t -  1 >>  swap  w!-t
\t32-t   token!-t
;


\ Machine independent
: a,-t  ( adr -- )  here-t /a-t allot-t  a!-t  ;
: token,-t ( token -- )  here-t /token-t allot-t  token!-t  ;

\ These versions of linkx-t are for absolute links
: link@-t ( target-address -- target-address' )  a@-t  ;
: link!-t ( target-address target-address -- )  a!-t  ;
: link,-t ( target-address -- )  a,-t  ;

: a-t@ ( host-address -- target-address )
\t16-t  w@ tshift-t <<  origin-t +
\t32-t  l@
;
: a-t! ( target-address host-address -- )
\t16-t  swap origin-t -  tshift-t >> swap w!
\t32-t  l!
;
: rlink-t@  ( host-adr -- target-adr )
\t16-t  w@ 1 <<  origin-t +
\t32-t  l@
;
: rlink-t!  ( target-adr host-adr -- )
\t16-t  swap origin-t -  1 >> swap w!
\t32-t  l!
;

: token-t@ ( host-address -- target-acf )  a-t@  ;
: token-t! ( target-acf host-address -- )  a-t!  ;
: link-t@  ( host-address -- target-address )  a-t@  ;
: link-t!  ( target-address host-address -- )  a-t!  ;

\ Machine independent
: a-t, ( target-address -- )  here  /a-t allot  a-t!  ;
: token-t, ( target-address -- )  here  /token-t allot  token-t!  ;
: >body-t ( cfa-t -- pfa-t )
\t32-t   8 +		\ Call instruction plus delay instruction
\t16-t   2 +		\ Indirect token
;

1 constant #threads-t

create threads-t   #threads-t /link-t * allot

: $hash-t  ( str voc-ptr -- thread )
   nip swap c@  #threads-t 1- and  /thread-t * +
;

\ Should allocate these dynamically.
\ The dictionary space should be dynamically allocated too.

\ The user area image lives in the host address space.
\ We wish to store into the user area with -t commands so as not
\ to need separate words to store target items into host addresses.
\ That is why user+ returns a target address.

\ Machine Independent

0 constant userarea-t
: setup-user-area ( -- )
   user-size-t alloc-mem is userarea-t
   userarea-t user-size-t  erase
;

: >user-t ( cfa-t -- user-address-t )
   >body-t
\t32-t  l@-t
\t16-t  w@-t
   userarea-t  +
;

: n>link-t ( anf-t -- alf-t )  dup begin 1+ dup c@ h# 80 and until c@ + 1+  ;
: l>name-t ( alf-t -- anf-t )  1- dup c@ h# 1f and -  ;
: >link-t ( acf-t -- alf-t ) /link-t - ;
decimal
/l constant #align-t  \ XXX Is this right ?
\t16-t /w constant #talign-t
\t32-t /l constant #talign-t
\t16-t 1 tshift-t << constant #linkalign-t
\t16-t 1 tshift-t << constant #acf-align-t
\t32-t /l constant #linkalign-t
\t32-t /l constant #acf-align-t
: aligned-t  ( n1 -- n2 )  #align-t 1- +  #align-t negate and  ;
: acf-aligned-t  ( n1 -- n2 )  #acf-align-t 1- +  #acf-align-t negate and  ;

\ NullFix bl -> 0
: align-t ( -- )
   begin   here-t #align-t  1- and   while   0 c,-t   repeat
;
: talign-t ( -- )
   begin   here-t #talign-t 1- and   while   0 c,-t   repeat
;
: linkalign-t  ( -- )
   begin   here-t #linkalign-t 1- and   while   0 c,-t   repeat
;
: acf-align-t  ( -- )
   begin   here-t #acf-align-t 1- and   while   0 c,-t   repeat
;

: entercode ( -- )
   only forth also labels also meta also srassembler
\   assembler
   [ assembler ] normal [ meta ]
;

\ Next 5 are Machine Independent
: cmove-t ( from to-t n -- )
  0 do over c@  over c!-t  1+ swap 1+ swap loop  2drop
;
: place-cstr-t  ( adr len cstr-adr-t -- cstr-adr-t )
   >r  tuck r@ swap cmove-t  ( len ) r@ +  0 swap c!-t  r>
;
: "copy-t ( from to-t -- )
  over c@ 2+  cmove-t
;
: toggle-t ( addr-t n -- ) swap >r r@ c@-t xor r> c!-t ;

: clear-threads-t  ( hostaddr -- )
   #threads-t /link-t * bounds  do
      origin-t i link-t!
   /link +loop
;
: initmeta  ( -- )
   threads-t clear-threads-t  threads-t current-t !
;

\ For compiling branch offsets used by control constructs.
\ These compile relative branches.

\t16-t /w-t constant /branch
\t32-t /l-t constant /branch
: branch! ( from target -- )
   over - ( from offset ) swap
\t16-t   w!-t
\t32-t   l!-t
;
: branch, ( target -- )
   here-t -
\t16-t   w,-t
\t32-t   l,-t
;

: thread-t!  ( thread adr -- )  link-t!  ;

only forth also meta also definitions
: install-target-assembler  ( -- )
   [ also assembler ]
   ['] /l-t    is /asm
   ['] here-t  is here
   ['] allot-t is asm-allot
   ['] l@-t    is asm@
   ['] l!-t    is asm!
   [ previous ]
;
: install-host-assembler  ( -- )
   [ assembler ] resident-assembler [ meta ]
;
