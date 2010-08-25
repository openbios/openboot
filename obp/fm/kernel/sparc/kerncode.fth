id: @(#)kerncode.fth 2.41 03/12/08 13:22:15
purpose: 
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1990 Bradley Forthware
copyright: Use is subject to license terms.

\ Meta compiler source for the Forth 83 kernel code words.
\ TODO:
\ separate heads.
\ Change code-field: so that when compiled into a metacompiler definition,
\ that word would return the 0-relative address.  When compiled into a
\ target definition, the word would return the absolute address.  Essentially,
\ we need to define "dolabel" very early in the kernel source.

meta
hex

\ Allocate and clear the initial user area image
\ mlabel init-user-area
setup-user-area

extend-meta-assembler

\ ---- Assembler macros that reside in the host environment
\ and assemble code for the target environment

\ Forth Virtual Machine registers

\ Note that the Forth Stack Pointer (%g7) is NOT the same register that
\ C uses for the stack pointer (%o6).  The hardware does all sorts of
\ funny things with the C stack pointer when you do save and restore
\ instructions, and when the register windows overflow.

:-h sp   %g7  ;-h  :-h base %g2  ;-h  :-h up  %g3  ;-h
:-h tos  %g4  ;-h  :-h ip   %g5  ;-h  :-h rp  %g6  ;-h

\ Scratch Registers
:-h scr %l0  ;-h  :-h sc1  %l1 ;-h  :-h sc2  %l2 ;-h  :-h sc3 %l3  ;-h
:-h sc4 %l4  ;-h  :-h sc5  %l5 ;-h  :-h sc6  %l6 ;-h  :-h sc7 %l7  ;-h

:-h spc %o7  ;-h	\ Saved Program Counter - set by the CALL instruction

\ Macros:

\ Parameter Field Address
\t32-t \dtc-t :-h apf  ( -- )  spc 8  ;-h
\t32-t \itc-t :-h apf  ( -- )  sc1 4  ;-h
\t16-t        :-h apf  ( -- )  sc1 2  ;-h

\ Put a bubble in the pipeline to patch the load interlock bug
:-h bubble  ( nop )  ;-h

32\ :-h slln  ( rs1 rs2 rd -- )  sll  ;-h
32\ :-h srln  ( rs1 rs2 rd -- )  srl  ;-h
32\ :-h sran  ( rs1 rs2 rd -- )  sra  ;-h
32\ :-h nget  ( ptr off  dst -- )  ld  ;-h
32\ :-h nput  ( src off  ptr -- )  st  ;-h

64\ :-h slln  ( rs1 rs2 rd -- )  sllx  ;-h
64\ :-h srln  ( rs1 rs2 rd -- )  srlx  ;-h
64\ :-h sran  ( rs1 rs2 rd -- )  srax  ;-h
64\ :-h nget  ( ptr off  dst -- )  ldx  ;-h
64\ :-h nput  ( src off  ptr -- )  stx  ;-h

:-h lget  ( ptr dst -- )  0  swap  ld  ;-h
:-h lput  ( src ptr -- )  0  swap  st  ;-h

:-h get   ( ptr dst -- )  0  swap  nget ;-h
:-h put   ( src ptr -- )  0  swap  nput ;-h

:-h move ( src dst -- )  %g0     -rot  add  ;-h
:-h ainc ( ptr -- )      dup /n  swap  add  ;-h
:-h adec ( ptr -- )      dup /n  swap  sub  ;-h
:-h push ( src ptr -- )  dup     adec  put  ;-h
:-h pop  ( ptr dst -- )  over   -rot  get   ainc  ;-h
:-h test ( src -- )      %g0    %g0   addcc  ;-h
:-h cmp  ( s1 s2 -- )    %g0          subcc  ;-h
\ Get a token
:-h rtget ( srca srcb dst -- )
\t16-t  dup >r lduh  r> ( dst )
\t16-t  tshift-t over sll

\t32-t  ld   bubble
\t32-t   \ We could increment a counter here to gather statistics with
\t32-t   \ no speed penalty in the 32-bit !

;-h
\ Get a branch offset
:-h bget ( src dst -- )
\t8-t   0 swap  ldsb	\ Is the limited range a problem?
\t16-t  0 swap  ldsh
32\ \t32-t  0 swap  ld
64\ \t32-t  tuck 0 swap  lduw
64\ \t32-t  0  over      sra
;-h

:-h /n* /n * ;-h

:-h 'user#  \ name  ( -- user# )
    '  ( acf-of-user-variable )  >body-t
\t32-t l@-t
\t16-t w@-t
;-h
:-h 'user  \ name  ( -- user-addressing-mode )
    meta-asm[   up 'user#   ]meta-asm
;-h
:-h 'body  \ name  ( -- variable-apf )
    '  ( acf-of-user-variable )  >body-t
;-h
:-h 'acf  \ name  ( -- variable-apf )
    '  ( acf-of-user-variable )  >body-t
;-h
:-h set  ( value  reg  -- )
    2dup sethi  swap h# 3ff land swap tuck  add
;-h

\ There are a few places in the code where moving the previous instruction
\ to the delay slot of the "next jmp" instruction won't work.  Generally
\ these are places where a control structure ends just before "next".
\ inhibit-delay assembles a nop instruction in cases where that is needed.
\ This ought to be done by the assembler, but it is hard to figure out.
:-h inhibit-delay
\t16-t  meta-asm[  nop  ]meta-asm
;-h

\ assembler macro to assemble next
:-h next
   meta-asm[
\t8-t    byte-next always branchif
\t8-t    nop		\ XXX should be  token-table sc2 sethi

\t16-t   here-t 4 - l@-t  here-t l!-t   \ Advance previous instruction
\t16-t   h# 81c0.e000  here-t 4 - l!-t  4 allot-t  \ up 0   %g0 jmpl  instr.

\t32-t   ip 0      scr  rtget
\t32-t   scr base  %g0  jmpl
\t32-t   ip /token-t     ip   add
  ]meta-asm
;-h
:-h c;    next end-code ;-h

\t16-t \itc :-h tld  ( src offset  dst -- )
\t16-t \itc    dup >r  lduh
\t16-t \itc    r@  tshift-t  r>  sll
\t16-t \itc ;-h

\ Create the code for "next" in the user area

\t16-t  compile-in-user-area

mlabel (next)   \ Shared code for next; will be copied into user area
\t16   ip 0       sc1  rtget
\t16   sc1  base  sc1  add
\t16   sc1 0      scr  rtget
\t16   scr base      %g0  jmpl
\t16   ip /token-t   ip   add
\t16-t end-code
\t16-t restore-dictionary

\itc-t d# 64 equ #user-init	\ Leaves space for the shared "next"

meta-compile


\ ---- Action code for target words classes.

\ "docode" eliminates the need to separately acf-align both the code field
\ and the body of a code definition, thus saving 12 bytes per code definition
\ in the t16s4 version.

\t16-t tshift-t 4 =  [if]
\t16-t code-field: docode
\t16-t    apf 2 + %g0 jmpl
\t16-t    nop
\t16-t end-code
\t16-t [then]

code-field: dolabel
\itc    sp         adec
\dtc  \ The label's code field contains        dolabel call   sp adec

      tos    sp    put	\ Push the apf of the variable
      apf    tos   add

\itc  tos 3  tos   add	\ Align to a longword boundary
\itc  tos 3  tos   andn
c;

code-field: docolon
\itc  rp          adec
\dtc  \ The colon definition's code field contains   docolon call   rp adec
      ip    rp    put	\ Save the ip on the return stack
      apf   ip    add	\ Reload ip with apf of colon definition
c;

code-field: docreate
\itc  sp          adec
\dtc  \ The word's code field contains        docreate call   sp adec
      tos   sp    put	\ Push the apf of the variable
      apf   tos   add
c;

\  In-dictionary variables are a leftover from the earliest FORTH
\  implementations.  They have no place in a ROMable target-system
\  and we are deprecating support for them; but Just In Case you
\  ever want to restore support for them, define the command-line
\  symbol:   in-dictionary-variables
[ifdef] in-dictionary-variables
   \  Support for in-dictionary variables, i.e., where the variable's
   \  storage location is in the dictionary rather than in user-space.
   code-field: dovariable
   \itc  sp          adec
   \dtc  \ The variable's code field contains        dovariable call   sp adec
	 tos   sp    put	\ Push the apf of the variable
	 apf   tos   add
   c;
      \  Hey, waidaminit!  This is the same as  docreate  just above!
      \  An in-dictionary variable could be as simple as    create 0 ,   ...
[then]

code-field: douser
\itc  sp            adec
\dtc  \ The user variable's code field contains       douser call   sp adec
      tos     sp   put
\t16  apf     scr  lduh	\ Get the user number
\t32  apf     scr  ld	\ Get the user number
      bubble
      scr up  tos  add	\ Add the base address of the user area
c;

code-field: dovalue
\itc  sp           adec
\dtc  \ The value's code field contains       dovalue call   sp adec
      tos     sp   put
\t16  apf     scr  lduh	\ Get the user number
\t32  apf     scr  ld	\ Get the user number
      bubble
      scr up  tos  nget	\ Get the contents of the user area location
c;

\ Defers could run faster by compiling the defer offset into the instruction
\ as in    up user#  scr  ld     scr base  %g0 jmpl    nop
\ But it would be harder to compile, metacompile, decompile, and set

code-field: dodefer
\dtc  \ The user variable's code field contains  dodefer call  apf  scr  ld
\t32       scr up    scr  ld	\ Get the acf stored in that user location
\t32       bubble

\t16       apf       scr  lduh
\t16       scr up    sc1  tld	\ Get the acf stored in that user location
\t16       sc1 base  scr  rtget \ Read the token

           scr base  %g0  jmpl	\ Execute that word
\t16   sc1  base  sc1  add

   nop
end-code

code-field: doconstant
\itc  sp           adec
\dtc  \ The constant's code field contains        doconstant call   sp adec
      tos      sp    put
\dtc  apf      tos   ld		\ Get the constant's value
64\ \dtc tos 20   tos  sllx
64\ \dtc apf 4 +  scr  ld
64\ \dtc tos scr  tos  or

\itc  apf      tos   lduh	\ Get the high halfword of the constant's value
\itc  tos 10   tos   slln	\ Shift into high halfword
\itc  apf 2 +  scr   lduh	\ Get the low halfword of the constant's value
\itc  scr tos  tos   add	\ Merge the two halves
64\ \itc tos 10  tos slln
64\ \itc apf 4 + scr lduh
64\ \itc scr tos  tos add
64\ \itc tos 10  tos slln
64\ \itc apf 6 + scr lduh
64\ \itc scr tos  tos add
c;

code-field: do2constant
\itc  sp             adec
\dtc  \ The constant's code field contains        do2constant call  sp adec
      sp	     adec	\ Make room on the stack
      tos      sp /n nput	\ Save the old tos on the memory stack

\dtc  apf      tos   ld		\ Get the bottom constant's value

64\ \dtc tos th 20   tos  sllx
64\ \dtc apf 4 +     scr  ld
64\ \dtc tos scr     tos  or

\dtc  tos      sp    put	\ Put it on the memory stack
\dtc  apf /n + tos   ld		\ Get the top constant's value

64\ \dtc tos th 20     tos  sllx
64\ \dtc apf /n 4 + +  scr  ld
64\ \dtc tos scr       tos  or

\itc  apf      tos   lduh	\ Get the high halfword of the bottom value
\itc  tos      sp 0  sth	\ Store on stack
\itc  apf /w +  tos  lduh	\ Get the low halfword of the bottom value
\itc  tos      sp 2  sth	\ Store on stack

\itc  apf /n + tos   lduh	\ Get the high halfword of the top value
\itc  tos 10   tos   sll	\ Shift into high halfword
\itc  apf /n /w + +  scr   lduh	\ Get the low halfword of the top value
\itc  scr tos  tos   add	\ Merge the two halves
c;

code-field: dodoes
\itc  \ The child word's code field contains a pointer to the doesclause
\dtc  \ The child word's code field contains   doesclause call   apf scr add
      \ The doesclause's code field contains       dodoes call   sp  adec
      tos     sp   put
\dtc  scr     tos  move
\itc  apf     tos  add
      ip      rp   push
\dtc  apf     ip   add
\itc  spc 8   ip   add
c;

\ ---- Define the format of target code fields by creating host
\ words that will create target code fields.

:-h place-cf-t  ( action-apf -- )
         aligned-t
\dtc-t   meta-asm[  ( action-adr )  call  sp adec  ]meta-asm
\itc-t   token,-t
;-h

:-h code-cf     ( -- )
\itc-t  \t32-t  here /token-t + aligned
\itc-t  \t16-t  [ tshift-t 4 <> ]-h [if]  here /token-t + aligned  [else]  docode  [then]
\itc-t          place-cf-t  align-t
;-h

:-h colon-cf    ( -- )  ( 'body-t ) docolon    place-cf-t
\dtc-t  -4 allot-t  meta-asm[  rp adec  ]meta-asm
;-h

:-h defer-cf    ( -- )
  ( 'body-t ) dodefer    place-cf-t
\dtc-t  -4 allot-t  meta-asm[  apf scr ld  ]meta-asm
;-h

:-h label-cf    ( -- )  ( 'body-t ) dolabel    place-cf-t   align-t  ;-h
:-h constant-cf ( -- )  ( 'body-t ) doconstant place-cf-t  ;-h
:-h create-cf   ( -- )  ( 'body-t ) docreate   place-cf-t  ;-h
[ifdef] in-dictionary-variables
   :-h variable-cf ( -- )  ( 'body-t ) dovariable place-cf-t  ;-h
[then]
:-h user-cf     ( -- )  ( 'body-t ) douser     place-cf-t  ;-h
:-h value-cf    ( -- )  ( 'body-t ) dovalue    place-cf-t  ;-h
:-h startdoes   ( -- )
\dtc-t  ( 'body-t ) dodoes     place-cf-t
\itc-t   meta-asm[  dodoes call  sp adec  ]meta-asm
;-h
:-h start;code  ( -- )  ;-h
:-h vocabulary-cf ( -- )
    \ The forward reference will be resolved later by fix-vocabularies
    compile-t <vocabulary>

\dtc-t   meta-asm[  apf  scr  add	 ]meta-asm  \ Address of parameter field

;-h


\ ---- Run-time words compiled by compiling words.

headerless
\ We can do better; combine the incrementing in   ip ainc   with that in next
code (lit)  ( -- n )
   tos sp push

    \t16   ip  0    scr  lduh   scr 10  scr  slln   ip 2  tos  lduh   scr tos  tos  add
64\ \t16   tos 10   tos  slln   ip   4  scr  lduh
64\ \t16   tos scr  tos  add    tos 10  tos  slln   ip 6  scr  lduh   scr tos  tos  add

32\ \t32   ip 0 tos nget
64\ \t32   ip 0  scr  lduw  scr 20  scr  sllx  ip 4  tos  lduw   scr tos  tos  add
   ip ainc
c;

code (wlit)  ( -- n )
   tos sp push
\t16   ip 0  tos  lduh   ip 2  ip  add   tos 1  tos  sub
\t32   ip tos get  ip ainc
c;

code (llit)  ( -- n )
    \t32  tos    sp   push
    \t32  ip     tos  lget
64\ \t32  tos 1  tos  sub
64\ \t32  ip  /l ip   add
32\ \t32  ip          ainc

    \t16  tos      sp   push
    \t16  ip  0    scr  lduh
    \t16  scr 10   scr  slln
    \t16  ip  2    tos  lduh
    \t16  scr tos  tos  add
64\ \t16  tos 1    tos  sub
    \t16  ip  /l   ip   add
c;

\ High level branch. The branch offset is compiled in-line.
code branch ( -- )
( 0 L: ) mloclabel bran1
   ip      scr  bget  \ branch
   ip scr  ip   add
c;

\ High level conditional branch.
code ?branch ( f -- )  \ Takes the branch if the flag is false
   tos 0  %g0   addcc
   sp     tos   get
   ( 0 B: ) bran1  0=    brif
   sp           ainc	\ Delay slot
   ip /branch  ip    add
c;

\ Run time word for loop
code (loop)  ( -- )
   rp     scr       get
   bubble
   scr 1  scr       addcc  \ increment loop index
   ( 0 B: ) bran1 vc  brif   \ branch if not done
   scr   rp         put    \ Write back the loop index (delay slot)
   rp 3 /n*    rp   add    \ done; remove loop params from stack
   ip /branch  ip   add    \ Skip the branch offset
c;

\ Run time word for +loop
code (+loop) ( increment -- )
   rp       scr     get
   bubble
   scr tos  scr     addcc  \ increment loop index
   scr   rp         put    \ Write back the loop index
   sp    tos        get
   bran1 ( 0 B: ) vc         brif   \ branch if not done
   sp               ainc   \ Delay slot
   rp 3 /n*    rp   add    \ done; remove loop params from stack
   ip /branch  ip   add    \ Skip the branch offset
c;

\ Run time word for do
code (do)  ( l i -- )
   tos  sc1      move   \ i in sc1
   sp   scr      get    \ l in scr
   sp 1 /n*      tos  nget
   sp 2 /n*      sp   add
( 1 L: ) mloclabel pd0 ( -- r: loop-end-offset l+0x8000 i-l-0x8000 )
    ip           rp   push     \ remember the do offset address
    ip /branch   ip   add     \ skip the do offset
    h# 8000.0000 sc2  sethi
64\ sc2  h# 20   sc2  sllx
    scr sc2      scr  add
    scr          rp   push
    sc1 scr      sc1  sub
    sc1          rp   push
c;
meta

\ Run time word for ?do
code (?do)  ( l i -- )
   tos       sc1   move   \ i in sc1
   sp        scr   get    \ l in scr
   sp 1 /n*  tos   nget
   sc1 scr         cmp
   ( 1 B: ) pd0  0<>       brif
   sp 2 /n*  sp    add
   ip        scr   bget	\ branch
   scr ip    ip    add
c;

headers
\ Loop index for current do loop
code i  ( -- n )
   tos       sp    push
   rp        tos   get
   rp 1 /n*  scr   nget
   bubble
   tos scr   tos   add
c;

\ Loop index for next enclosing do loop
code j   ( -- n )
   tos       sp   push
   rp 3 /n*  tos  nget
   rp 4 /n*  scr  nget
   bubble
   tos scr   tos  add
c;

headerless
code (leave)  ( -- )
( 2 L: ) mloclabel pleave
   rp 2 /n*   ip   nget    \ Get the address of the ending offset
   rp 3 /n*   rp   add     \ get rid of the loop indices
   ip         scr  bget	   \ branch
   ip scr     ip   add
c;

code (?leave)  ( f -- )
   tos        test
   sp   tos   get
   ( 2 B:  ) pleave 0<> brif
   sp         ainc
   inhibit-delay
c;

headers
code unloop  ( -- )  rp  3 /n*  rp  add  c;  \ Discard the loop indices

headerless
code (of)  ( selector test -- [ selector ] )
   sp  scr  pop     \ Test in tos, Selector in scr
   scr tos  cmp
   0=  if
   scr  tos  move  \ Delay slot - Copy selector to tos
      sp     tos  pop
      ip /branch  ip   add	\ Skip the branch offset
      next
   then
   ip     scr  bget
   ip scr  ip  add	\ Take the branch
c;

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.

code (endof)  ( -- )   ip  scr  bget    ip scr  ip   add    c;
code (endcase)  ( n -- )      sp   tos  pop    c;

\ ---- Ordinary Forth words.

headers
\ Execute a Forth word given a code field address
code execute   ( acf -- )
\dtc tos     scr  move
\dtc sp      tos  get
\dtc scr 0   %g0  jmpl
\dtc sp           ainc

\itc tos       sc1  move
\itc sp        tos  get
\itc sc1 0     scr  rtget
\itc scr base  %g0  jmpl
\itc sp             ainc
end-code

assembler  ( 3 L: ) mlabel dofalse   0  tos  move  next   meta

\ Convert a character to a digit according to the current base
code digit  ( char base -- digit true | char false )
   tos  scr  move	\ base in scr
   sp   tos  get	\ char in tos
   tos ascii 0 tos  subcc	\ convert to number
   ( 3 B: ) dofalse < brif	\ Anything less than ascii 0 isn't a digit
  tos  h# 0a  cmp	\ test for >= 10
   >=  if annul		\ Try for a letter representing a digit
      tos  scr    cmp	\ Compare digit to base

      tos   ascii A ascii 0 -  cmp
      ( 3 B: ) dofalse < brif	\ bad if > '9' and < 'A'
      tos   ascii a ascii 0 -  cmp
      >=  if
         tos ascii A ascii 0 - d# 10 -   tos  sub   \ Delay
         tos ascii a ascii A -           tos  sub
      then
      tos scr cmp	\ Compare digit to base
   then
   ( 3 B: ) dofalse >= brif	\ Not a digit
   nop
   tos  sp  put		\ Replace the char on the stack with the digit
   -1   tos move	\ True to indicate success
c;

\ Copy cnt characters starting at from-addr to to-addr.  Copying is done
\ strictly from low to high addresses, so be careful of overlap between the
\ two buffers.

code cmove  ( src dst cnt -- )  \ Copy from bottom to top
   sp 1 /n*  scr   nget     \ Src into scr
   sp 0 /n*  sc1   nget     \ Dst into sc1

   scr tos  scr  add    \ Src = src+cnt (optimize for low-to-high copy)
   sc1 tos  sc1  add    \ Dst = dst+cnt
   sc1 1    sc1  sub    \ Account for the position of the addcc instruction
   %g0 tos  tos  subcc  \ Negate cnt

   <> if
      nop
      begin
         scr tos   sc2  ldub       \ (delay) Load byte
         tos 1     tos  addcc      \ (delay) Increment cnt
      >= until
         sc2   sc1 tos  stb        \ Store byte
   then

   sp 2 /n*  tos  nget    \ Delete 3 stack items
   sp 3 /n*  sp   add     \   "
c;

code cmove>  ( src dst cnt -- )  \ Copy from top to bottom
   sp 1 /n*  scr   nget      \ Src into scr
   sp 0 /n*  sc1   nget      \ Dst into sc1

   sc1 1 sc1   add	\ Account for the position of the subcc instruction

   tos 0       cmp	\ Don't do anything if the count is 0.
   <> if
      tos 1  tos  sub   \ Decrement cnt (startup loop)

      begin
         scr tos   sc2  ldub    \ (delay) Load byte
         tos 1     tos  subcc   \ (delay) Decrement cnt
      < until
         sc2   sc1 tos  stb     \ Store byte
   then

   sp 2 /n*  tos  nget    \ Delete 3 stack items
   sp 3 /n*  sp   add     \   "
c;

code and ( n1 n2 -- n3 )  sp  scr  pop   tos scr  tos  and   c;
code or  ( n1 n2 -- n3 )  sp  scr  pop   tos scr  tos  or    c;
code xor ( n1 n2 -- n3 )  sp  scr  pop   tos scr  tos  xor   c;

code <<      ( n1 cnt -- n2 )  sp  scr  pop   scr tos  tos  slln   c;
code >>      ( n1 cnt -- n2 )  sp  scr  pop   scr tos  tos  srln   c;
code >>a     ( n1 cnt -- n2 )  sp  scr  pop   scr tos  tos  sran   c;
code lshift  ( n1 cnt -- n2 )  sp  scr  pop   scr tos  tos  slln   c;
code rshift  ( n1 cnt -- n2 )  sp  scr  pop   scr tos  tos  srln   c;

code +   ( n1 n2 -- n3 )  sp  scr  pop   tos scr  tos  add   c;
code -   ( n1 n2 -- n3 )  sp  scr  pop   scr tos  tos  sub   c;

code invert  ( n1 -- n2 )     tos -1  tos  xor  c;
code negate  ( n1 -- n2 )  %g0 tos  tos  sub   c;

\  Mark the first code-definition in the dictionary;
\  we will need it later...
\  XXX  We might be able to make this  low-dictionary-adr
\  XXX  and move that from  debugm.fth  (or  debugm16.fth )
headerless
: first-code-word ( -- acf )  (') (lit) ;
headers

: abs   ( n1 -- n2 )  dup 0<  if  negate  then   ;

: min  ( n1 n2 -- n3 )  2dup  >  if  swap  then  drop  ;
: max  ( n1 n2 -- n3 )  2dup  <  if  swap  then  drop  ;
: umin ( u1 u2 -- u3 )  2dup u>  if  swap  then  drop  ;
: umax ( u1 u2 -- u3 )  2dup u<  if  swap  then  drop  ;

code up@  ( -- addr )  tos sp push   up tos move   c;
code sp@  ( -- addr )  tos sp push   sp tos move   c;
code rp@  ( -- addr )  tos sp push   rp tos move   c;
code up!  ( addr -- )  tos up move   sp tos pop    c;
code sp!  ( addr -- )  tos sp move   sp tos pop    c;
code rp!  ( addr -- )  tos rp move   sp tos pop    c;
code >r   ( n -- )     tos rp push   sp tos pop    c;
code r>   ( -- n )     tos sp push   rp tos pop    c;
code r@   ( -- n )     tos sp push   rp tos get    c;
code >user ( pfa -- addr )
\t32	tos	%g0	scr	lduw
\t16	tos	%g0	scr	lduh
	up	scr	tos	add
c;
code 2>r  ( n1 n2 -- )
   rp  /n 2*  rp     sub
   sp         scr    get
   scr        rp /n  nput
   tos        rp 0   nput
   sp  /n     tos    nget
   sp  /n 2*  sp     add
c;
code 2r>  ( -- n1 n2 )
   sp  /n 2*  sp     sub
   tos        sp /n  nput
   rp /n      tos    nget
   tos        sp 0   nput
   rp 0       tos    nget
   rp  /n 2*  rp     add
c;
code 2r@  ( -- n1 n2 )
   sp  /n 2*  sp     sub
   tos        sp /n  nput
   rp /n      tos    nget
   tos        sp 0   nput
   rp 0       tos    nget
c;

code >ip   ( n -- )     tos rp push   sp tos pop    c;
code ip>   ( -- n )     tos sp push   rp tos pop    c;
code ip@   ( -- n )     tos sp push   rp tos get    c;
: ip>token  ( ip -- token-adr )  /token -  ;

code exit ( -- )       rp ip pop  c;
code unnest ( -- )     rp ip pop  c;

code tuck  ( n1 n2 -- n2 n1 n2 )
   sp   scr    get
   bubble
   scr  sp     push
   tos  sp /n  nput
c;
code nip   ( n1 n2 -- n2 )
   sp  ainc
c;
code flip  ( w1 -- w2 )  \  byte-swap the low two bytes; clear the rest.
   tos  0ff   scr  and  	\  lowest byte into scr
   scr    8   scr  slln 	\  lowest byte into second byte of scr
   tos    8   tos  srln 	\  second byte into lowest byte of tos
   tos  0ff   tos  and  	\  clear the rest of tos
   tos scr  tos  or
c;

extend-meta-assembler
:-h leaveflag  ( condition -- )
\ macro to assemble code to leave a flag on the stack
   if
   0  tos  move   \ Delay slot
      -1 tos move
   then
   inhibit-delay
;-h

meta-compile

code 0=  ( n -- f )  tos test  0=  leaveflag c;
code 0<> ( n -- f )  tos test  0<> leaveflag c;
code 0<  ( n -- f )  tos test  0<  leaveflag c;
code 0<= ( n -- f )  tos test  <=  leaveflag c;
code 0>  ( n -- f )  tos test  >   leaveflag c;
code 0>= ( n -- f )  tos test  0>= leaveflag c;

extend-meta-assembler
:-h compare
   sp  scr  pop
   scr tos  cmp
;-h
meta-compile

code <   ( n1 n2 -- f )  compare <   leaveflag c;
code >   ( n1 n2 -- f )  compare >   leaveflag c;
code =   ( n1 n2 -- f )  compare 0=  leaveflag c;
code <>  ( n1 n2 -- f )  compare <>  leaveflag c;
code u>  ( n1 n2 -- f )  compare u>  leaveflag c;
code u<= ( n1 n2 -- f )  compare u<= leaveflag c;
code u<  ( n1 n2 -- f )  compare u<  leaveflag c;
code u>= ( n1 n2 -- f )  compare u>= leaveflag c;
code >=  ( n1 n2 -- f )  compare >=  leaveflag c;
code <=  ( n1 n2 -- f )  compare <=  leaveflag c;

code drop ( n -- )      sp   tos  pop    c;
code ?dup ( n -- 0|n,n)
   tos  %g0	%g0	subcc
   0<> if
      nop
      tos	sp	push
   then
   inhibit-delay
c;
code dup  ( n -- n n )  tos  sp   push   c;
code over ( n1 n2 -- n1 n2 n1 )  tos sp push    sp /n  tos  nget  c;
code swap ( n1 n2 -- n2 n1 )
   sp   scr  get
   tos  sp   put
   scr  tos  move
c;
code rot  ( n1 n2 n3 -- n2 n3 n1 )
   sp 0 /n*    scr    nget
   sp 1 /n*    sc1    nget
   scr    sp 1 /n*    nput
   tos    sp 0 /n*    nput
   sc1    tos    move
c;
code -rot ( n1 n2 n3 -- n3 n1 n2 )
   sp 0 /n*  scr    nget
   sp 1 /n*  sc1    nget
   tos    sp 1 /n*  nput
   sc1    sp 0 /n*  nput
   scr    tos    move
c;
code 2drop  ( d -- )      sp ainc   sp tos pop  c;
code 2dup   ( d -- d d )
   sp        scr       get
   sp 2 /n*  sp        sub
   tos       sp 1 /n*  nput
   scr       sp 0 /n*  nput
c;
code 2over  ( d1 d2 -- d1 d2 d1 )
   sp 2 /n*  sp        sub
   tos       sp 1 /n*  nput
   sp 4 /n*  tos       nget
   bubble
   tos       sp 0 /n*  nput
   sp 3 /n*  tos       nget
c;
code 2swap  ( d1 d2 -- d2 d1 )
   sp 2 /n*  sc2    nget
   sp 1 /n*  sc1    nget
   sp 0 /n*  scr    nget
   bubble
   scr    sp 2 /n*  nput
   tos    sp 1 /n*  nput
   sc2    sp 0 /n*  nput
   sc1    tos    move
c;
code 3drop  ( n1 n2 n3 -- )
   sp 2 /n*  tos   nget
   sp 3 /n*  sp    add
c;
code 3dup   ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
   sp 1 /n*  sc1    nget
   sp 0 /n*  scr    nget
   sp 3 /n*  sp     sub
   tos    sp 2 /n*  nput
   sc1    sp 1 /n*  nput
   scr    sp 0 /n*  nput
c;

code pick   ( nm ... n1 n0 k -- nm ... n2 n0 nk )
32\  tos 2   tos  sll    \ Multiply by /n
64\  tos 3   tos  sllx   \ Multiply by /n
     sp tos  tos  nget   \ Index into stack
c;

code 1+  ( n1 -- n2 )  tos 1  tos  add   c;
code 2+  ( n1 -- n2 )  tos 2  tos  add   c;
code 1-  ( n1 -- n2 )  tos 1  tos  sub   c;
code 2-  ( n1 -- n2 )  tos 2  tos  sub   c;

code 2/  ( n1 -- n2 )  tos 1  tos  sran   c;
code u2/ ( n1 -- n2 )  tos 1  tos  srln   c;
code 2*  ( n1 -- n2 )  tos 1  tos  slln   c;
code 4*  ( n1 -- n2 )  tos 2  tos  slln   c;
code 8*  ( n1 -- n2 )  tos 3  tos  slln   c;

code on ( addr -- )
           -1  scr    move
    \dtc  scr  tos 0  st
64\ \dtc  scr  tos 4  st
64\ \itc  scr  tos 4  sth
64\ \itc  scr  tos 6  sth
    \itc  scr  tos 0  sth
    \itc  scr  tos 2  sth
          sp  tos     pop
c;
code off ( addr -- )
    \dtc   %g0  tos 0  st
64\ \dtc   %g0  tos 4  st
64\ \itc   %g0  tos 6  sth
64\ \itc   %g0  tos 4  sth
    \itc   %g0  tos 0  sth
    \itc   %g0  tos 2  sth
            sp  tos    pop
c;

code +! ( n addr -- )
          sp  0 /n*  scr  nget
    \dtc  tos        sc1  lget

64\ \dtc  sc1 20     sc1  slln
64\ \dtc  tos /l     sc2  ld
64\ \dtc  sc1 sc2    sc1  add

    \itc  tos 0      sc1  lduh
    \itc  sc1 10     sc1  slln
    \itc  tos 2      sc2  lduh
    \itc  sc1 sc2    sc1  add

64\ \itc  tos 4      sc2  lduh
64\ \itc  sc1 10     sc1  slln
64\ \itc  sc1 sc2    sc1  add

64\ \itc  tos 6      sc2  lduh
64\ \itc  sc1 10     sc1  slln
64\ \itc  sc1 sc2    sc1  add

          sc1 scr    sc1  add

64\ \dtc  sc1 tos    /l   st
64\ \dtc  sc1 20     sc1  srln
    \dtc  sc1        tos  lput

64\ \itc  sc1 tos    6    sth
64\ \itc  sc1 10     sc1  srln
64\ \itc  sc1 tos    4    sth
64\ \itc  sc1 10     sc1  srln

    \itc  sc1 tos    2    sth
    \itc  sc1 10     sc1  srln
    \itc  sc1 tos    0    sth

          sp  1 /n*  tos  nget
          sp  2 /n*  sp   add
c;

code @   ( addr -- n )
64\ \dtc tos 0    scr  ld
64\ \dtc scr 20   scr  slln
64\ \dtc tos 4    tos  ld
64\ \dtc tos scr  tos  or

64\ \itc tos 0    sc1  lduh
64\ \itc sc1 10   scr  slln
64\ \itc tos 2    sc1  lduh
64\ \itc sc1 scr  scr  or
64\ \itc scr 10   scr  slln
64\ \itc tos 4    sc1  lduh
64\ \itc sc1 scr  scr  or
64\ \itc scr 10   scr  slln
64\ \itc tos 6    sc1  lduh
64\ \itc sc1 scr  tos  or

32\ \dtc tos 0    tos  ld

32\ \itc tos 2    scr  lduh
32\ \itc tos 0    tos  lduh
32\ \itc tos 10   tos  slln
32\ \itc scr tos  tos  add
c;

code d@  ( addr -- nlow nhigh )
   tos 0  scr ldd
   sc1    sp  push
   scr    tos move
c;

64\ code x@ ( addr -- x )	\ doubleword aligned
64\   tos tos get
64\ c;

code l@ ( addr -- l )		\ longword aligned
   tos tos lget
c;

32\ code <l@ ( addr -- l )  tos 0  tos  ld    c;
code w@ ( addr -- w )		\ 16-bit word aligned
   tos 0  tos  lduh
c;

32\ code <w@ ( addr -- w )  tos 0  tos  ldsh  c; \ with sign extension
64\ code <w@ ( addr -- w )
64\    tos 0  tos     lduh
64\    tos d# 48 tos  sllx
64\    tos d# 48 tos  srax
64\ c;
64\ code <l@ ( addr -- l )
64\    tos 0  tos  lduw
64\    tos 0  tos  sra
64\ c;

code c@ ( addr -- c )
   tos 0  tos  ldub
c;

code unaligned-@  ( addr -- l )
   tos 0  scr  ldub
   tos 1  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 2  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 3  sc1  ldub   scr 8 scr slln
64\   scr sc1 scr add
64\   tos 4  sc1  ldub   scr 8 scr slln  scr sc1 scr add
64\   tos 5  sc1  ldub   scr 8 scr slln  scr sc1 scr add
64\   tos 6  sc1  ldub   scr 8 scr slln  scr sc1 scr add
64\   tos 7  sc1  ldub   scr 8 scr slln
   scr sc1 tos add
c;
code be-l@  ( addr -- l )
   tos 0  scr  ldub
   tos 1  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 2  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 3  sc1  ldub   scr 8 scr slln  scr sc1 tos add
c;
code unaligned-l@  ( addr -- l )
   tos 0  scr  ldub
   tos 1  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 2  sc1  ldub   scr 8 scr slln  scr sc1 scr add
   tos 3  sc1  ldub   scr 8 scr slln  scr sc1 tos add
c;
code unaligned-w@  ( addr -- w )
   tos 0  scr  ldub
   tos 1  sc1  ldub   scr 8 scr slln  scr sc1 tos add
c;

\ 16-bit token version doesn't require alignment on a word boundary
code !   ( n addr -- )
( 4 L: ) mloclabel  start-of-!
   sp  0  scr  nget
   bubble

64\ \dtc   scr     tos /l  st
64\ \dtc   scr 20  scr     srln
    \dtc   scr     tos 0   st

64\ \itc   scr     tos 6  sth
64\ \itc   scr 10  scr    srln
64\ \itc   scr     tos 4  sth
64\ \itc   scr 10  scr    srln

    \itc   scr     tos 2  sth
    \itc   scr 10  scr    srln
    \itc   scr     tos 0  sth

   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;

headerless
\  These two words are sufficient to implement a very fast  IS
\  The first will be applied to USER definitions (primarily VALUEs
\  but also VARIABLEs) and the second to DEFER words.
\  Their actions are the same as the obsolete  (is)  used to be;
\  the main difference is that the determination of the word-type
\  of the target of the IS is made at compile-time rather than
\  at run-time.

code (is-user)  ( n -- )
   tos       sp   push		\  Do the  (')  in-line
   ip 0      tos  rtget 		\  Next token in caller
   tos base  tos  add			\  TOS <= ACF-of-next-token-in-caller
   ip /token ip	  add			\  Complete the  (') 
				\  Do the  >body  in-line
   tos   0 >body-t   tos	add

	tos	%g0	scr	\  Do the  >user  in-line
\t32				lduw
\t16				lduh

   ( 4 B: ) start-of-!   bra			\  Go to the !
	up	scr	tos	add	\  TOS <= user-addr of IS-target
end-code

code (is-defer)  ( acf -- )
   tos  base  scr  sub		\  Start the token!
\t16  scr tshift-t  scr      srl	\  SCR <= token to store
				\  Do the  (')  in-line
   ip 0      tos  rtget 		\  Next token in caller
   ip /token ip	  add			\  Bump past next token in caller
   tos base  tos  add			\  TOS <= ACF of next token
					\  That completed the  (') 

				\  Do the  >body  in-line
   tos   0 >body-t   tos	add

	tos	%g0	sc1	\  Do the  >user  in-line
\t32				lduw
\t16				lduh
	up	sc1	tos	add	\  TOS <= user-addr of IS-target
			
	scr    tos		\  Complete the token!
\t16		    0    sth
\t32			 lput ( ???XXX tput )

	sp   tos  pop
c;


headers


code d!  ( n-low n-high addr -- )
   sp  0 /n*  scr  nget
   sp  1 /n*  sc1  nget
   bubble
   scr  tos 0  std
   sp  2 /n*  tos  nget
   sp  3 /n*  sp   add
c;
64\ code x!   ( x addr -- )
64\    sp  0  scr  nget
64\    bubble
64\    scr        tos  put
64\    sp  1 /n*  tos  nget
64\    sp  2 /n*  sp   add
64\ c;

code l!   ( n addr -- )
   sp  0  scr  nget
   bubble
   scr   tos 0 st
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;
code w!  ( w addr -- )
   sp  0  scr  nget
   bubble
   scr   tos 0 sth
   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;
code c!  ( c addr -- )
   sp  0  scr  nget
   bubble
   scr   tos 0 stb
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;

code unaligned-d!   ( d addr -- )
   sp  0  scr  nget

64\                        scr    tos 1 /n* 7 +  stb
64\   scr 8  scr    srln   scr    tos 1 /n* 6 +  stb
64\   scr 8  scr    srln   scr    tos 1 /n* 5 +  stb
64\   scr 8  scr    srln   scr    tos 1 /n* 4 +  stb
64\   scr 8  scr    srln
                           scr    tos 1 /n* 3 +  stb
      scr 8  scr    srln   scr    tos 1 /n* 2 +  stb
      scr 8  scr    srln   scr    tos 1 /n* 1 +  stb
      scr 8  scr    srln   scr    tos 1 /n* 0 +  stb

   sp  1 /n*  scr  nget

64\                        scr    tos 7  stb
64\   scr 8  scr    srln   scr    tos 6  stb
64\   scr 8  scr    srln   scr    tos 5  stb
64\   scr 8  scr    srln   scr    tos 4  stb
64\   scr 8  scr    srln
                           scr    tos 3  stb
      scr 8  scr    srln   scr    tos 2  stb
      scr 8  scr    srln   scr    tos 1  stb
      scr 8  scr    srln   scr    tos 0  stb

   sp  2 /n*  tos  nget
   sp  3 /n*  sp   add
c;
code unaligned-!   ( n addr -- )
   sp  0  scr  nget
   bubble

64\   scr    tos 7  stb
64\   scr 8  scr    srln   scr    tos 6  stb
64\   scr 8  scr    srln   scr    tos 5  stb
64\   scr 8  scr    srln   scr    tos 4  stb
64\   scr 8  scr    srln

   scr    tos 3  stb
   scr 8  scr    srln   scr    tos 2  stb
   scr 8  scr    srln   scr    tos 1  stb
   scr 8  scr    srln   scr    tos 0  stb

   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;
code be-l!   ( n addr -- )
   sp  0  scr  nget
   bubble
   scr    tos 3  stb
   scr 8  scr    srln   scr    tos 2  stb
   scr 8  scr    srln   scr    tos 1  stb
   scr 8  scr    srln   scr    tos 0  stb
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;
\ In some versions, be-l, needs to set a swap bit
: be-l,  ( l -- )  here /l allot  be-l!  ;
code unaligned-l!   ( n addr -- )
   sp  0  scr  nget
   bubble
   scr    tos 3  stb
   scr 8  scr    srln   scr    tos 2  stb
   scr 8  scr    srln   scr    tos 1  stb
   scr 8  scr    srln   scr    tos 0  stb
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;
code unaligned-w!   ( w addr -- )
   sp  0  scr  nget
   bubble
   scr    tos 1  stb
   scr 8  scr    srl
   scr    tos 0  stb
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;

code 2@  ( addr -- d )
    tos /n   sc1  lduh tos /n 2 +   scr  lduh  sc1 10   sc1  slln
64\ scr sc1  sc1  add  tos /n 4 +   scr  lduh  sc1 10   sc1  slln
64\ scr sc1  sc1  add  tos /n 6 +   scr  lduh  sc1 10   sc1  slln
    scr sc1  scr  add

    scr      sp   push

    tos  0   sc1  lduh tos 2   scr  lduh  sc1 10   sc1  slln
64\ scr sc1  sc1  add  tos 4   scr  lduh  sc1 10   sc1  slln
64\ scr sc1  sc1  add  tos 6   scr  lduh  sc1 10   sc1  slln

    scr  sc1  tos  add
c;
code 2!  ( d addr -- )
    sp  0   scr    nget
    bubble

64\ scr   tos 6  sth  scr 10  scr  srln
64\ scr   tos 4  sth  scr 10  scr  srln
    scr   tos 2  sth  scr 10  scr  srln
    scr   tos 0  sth

    sp  /n  scr    nget

    bubble

64\ scr   tos /n 6 + sth  scr 10  scr  srln
64\ scr   tos /n 4 + sth  scr 10  scr  srln
    scr   tos /n 2 + sth  scr 10  scr  srln
    scr   tos /n 0 + sth

    sp  2 /n*   tos    nget
    sp  3 /n*   sp     add
c;

\  code fill ( start-addr count char -- )
\  			\ char in tos
\     sp 0 /n*  scr  nget	\ count in scr
\
\     scr %g0 %g0 subcc
\     > if
\        nop
\        sp 1 /n*  sc1  nget	\ start in sc1
\        begin
\  	 scr 1  scr  subcc
\           tos  sc1 scr  stb
\        0= until
\           nop
\     then
\
\     sp 2 /n*   tos  nget
\     sp 3 /n*   sp   add
\  c;

code fill  ( start-addr count char -- )
				\ tos = data byte
   sp  0 /n*  scr   nget	\ scr = count
				\ sc1 = addr

   scr 10  %g0   subcc
   >= if			\ Enough to bother optimizing?
      sp 1 /n*  sc1   nget	\ ( delay)  sc1 = addr

      \ Store stray bytes at top of range
      scr sc1  sc2  add		\ Last+1 byte location in range
      sc2   3  sc3  andcc	\ Count - # extra bytes at top of range (0-3)
      scr sc3  scr  sub		\ Adjust main counter for later
      0 F:  bra			\ Jump to the until branch
      sc2   3  sc2  andn	\ (delay) Starting adr at top (X X X 0|4)
      begin
         tos  sc2 sc3  stb	\ Store data byte
      0 L:
      0<= until
         sc3  1   sc3  subcc	\ (delay)

      \ Fill sc4-sc5 pair with repeated data bytes
      tos  ff  sc4  and		\ Mask all but desired byte
      sc4   8  sc2  sll
      sc4 sc2  sc4  or		\ sc4 = 0000abab
      sc4  10  sc2  sll
      sc4 sc2  sc4  or		\ sc4 = abababab

      \ Store bulk of data, as 32-bit words (4 bytes at a time)
      \ Guaranteed to execute at least once
      scr  4   scr  subcc	\ Pre-subtract count
      0 F:  bra			\ Jump to the until branch
      sc1  4   sc3  add		\ (delay) Pre-add starting address
      begin
         sc4  sc3 scr  st	\ Store sc4 data (4 bytes)
      0 L:
      0< until
         scr  4   scr  subcc	\ (delay)

      scr  8  scr  add		\ Restore correct remaining count
   then

   \ Store the few remaining bytes at bottom of range
   0 F:  bra			\ Jump to the until branch
   scr 0   %g0  subcc 		\ (delay)
   begin
      tos  sc1 scr  stb		\ Store data byte
   0 L:
   0<= until
      scr  1   scr  subcc	\ (delay)

   sp  2 /n*    tos  nget	\ Remove 3 items off of stack
   sp  3 /n*    sp   add	\   "
c;

code noop ( -- )  inhibit-delay  c;

32\ code n->l ( n.unsigned -- l )  inhibit-delay  c;
64\ code n->l ( n.unsigned -- l )  tos 0 tos srl  c;
: s>d  ( n -- d )  dup 0<  ;  \ Depends on  true=-1, false=0

code wbsplit ( l -- b.low b.high )
   tos  h# ff  scr  and
   scr         sp   push
   tos  8      tos  srln
   tos  h# ff  tos  and
c;

code bwjoin ( b.low b.high -- w )
   sp         scr  pop
   scr h# ff  scr  and
   tos h# ff  tos  and
   tos  8     tos  slln
   tos  scr   tos  or
c;

code lwsplit ( l -- w.low w.high )  \ split a long into two words
   tos     scr  move
   scr 10  scr  sll
   scr 10  scr  srl
   scr     sp   push
   tos 10  tos  srl
c;
code wljoin ( w.low w.high -- l )
   sp       scr  pop
   scr 10   scr  sll   \ Throw away any high order bits in w.low
   scr 10   scr  srl
   tos 10   tos  sll
   tos scr  tos  or
c;

64\ code xlsplit ( x -- l.lo l.hi )
64\   tos 0      scr  srl  \ Clear high order 32 bits
64\   scr        sp   push
64\   tos h# 20  tos  srln
64\ c;

64\ code lxjoin ( l.lo l.hi -- x )
64\    sp         scr  pop
64\    scr 0      scr  srl  \ Clear high order 32 bits
64\    tos h# 20  tos  slln
64\    tos scr    tos  or
64\ c;

1 constant /c
2 constant /w
4 constant /l
8 constant /x

16\ /w constant /n
32\ /l constant /n
64\ /x constant /n

code ca+  ( addr index -- addr+index*/c )
   sp       scr  pop
   tos scr  tos  add
c;
code wa+  ( addr index -- addr+index*/w )
   sp       scr  pop
   tos 1    tos  sll
   tos scr  tos  add
c;
code la+  ( addr index -- addr+index*/l )
   sp       scr  pop
   tos 2    tos  sll
   tos scr  tos  add
c;
64\ code xa+  ( addr index -- addr+index*/x )
64\    sp       scr  pop
64\    tos 3    tos  slln
64\    tos scr  tos  add
64\ c;
code na+  ( addr index -- addr+index*/n )
     sp       scr  pop
16\  tos 1    tos  slln   \ Multiply by /n
32\  tos 2    tos  slln   \ Multiply by /n
64\  tos 3    tos  slln   \ Multiply by /n
     tos scr  tos  add
c;
code ta+  ( addr index -- addr+index*/t )
   sp       scr  pop
\t16   tos 1    tos  slln
\t32   tos 2    tos  slln
   tos scr  tos  add
c;

code ca1+  ( addr -- addr+/w )      tos /c  tos  add   c;
code char+ ( addr -- addr+/w )      tos /c  tos  add   c;
code wa1+  ( addr -- addr+/w )      tos /w  tos  add   c;
code la1+  ( addr -- addr+/l )      tos /l  tos  add   c;
64\ code xa1+  ( addr -- addr+/x )      tos /x  tos  add   c;
code na1+  ( addr -- addr+/n )      tos /n  tos  add   c;
code cell+ ( addr -- addr+/n )      tos /n  tos  add   c;
code ta1+  ( addr -- addr+/token )  tos /token  tos  add   c;

code /c*   ( n -- n*/c )  inhibit-delay  c;
code chars ( n -- n*/c )  inhibit-delay  c;
code /w*   ( n -- n*/w )  tos 1  tos  slln  c;
code /l*   ( n -- n*/l )  tos 2  tos  slln  c;
code /x*   ( n -- n*/x )  tos 3  tos  slln  c;
16\ code /n* ( n -- n*/n )  tos 1  tos  slln  c; \ Multiply by /n
32\ code /n* ( n -- n*/n )  tos 2  tos  slln  c; \ Multiply by /n
64\ code /n* ( n -- n*/n )  tos 3  tos  slln  c; \ Multiply by /n
16\ code cells ( n -- n*/n )  tos 1  tos  slln  c; \ Multiply by /n
32\ code cells ( n -- n*/n )  tos 2  tos  slln  c; \ Multiply by /n
64\ code cells ( n -- n*/n )  tos 3  tos  slln  c; \ Multiply by /n

code upc ( char -- upper-case-char )
   tos  ascii a  cmp
   >=  if
      tos  ascii z  cmp
      >  if  annul
	 tos  ascii A ascii a -  tos  add
      then
   then
   inhibit-delay
c;
code lcc ( char -- lower-case-char )
   tos  ascii A  cmp
   >=  if
      tos  ascii Z  cmp
      >  if  annul
	 tos   ascii a ascii A -   tos  add
      then
   then
   inhibit-delay
c;

\ string compare - case sensitive
code comp ( addr1 addr2 len -- -1 | 0 | 1 )
			\ len in tos
   sp 0 /n*  scr   nget	\ addr2 in scr
   sp 1 /n*  sc1   nget	\ addr1 is sc1

   0 F:  bra  \ jump to the subcc instruction
   nop
   begin
      sc1 1  sc1  add
      scr 0  sc3  ldub
      scr 1  scr  add
      sc2 sc3     cmp
      <> if   nop
         <  if
            1   tos   move	\ Delay slot
            -1  tos   move
         then
         sp 2 /n*   sp  add
         next
      then

      \ branch target
      0 L:
      tos 1  tos  subcc
   0< until  annul
      sc1 0  sc2  ldub     	\ Delay slot

   0         tos  move
   sp 2 /n*  sp   add
c;

\ string compare - case insensitive
code caps-comp ( addr1 addr2 len -- -1 | 0 | 1 )
                         \ len in tos
   sp 0 /n*  scr   nget  \ addr2 in scr
   sp 1 /n*  sc1   nget  \ addr1 is sc1

   0 F:  bra  \ jump to the subcc instruction
   nop
   begin
      sc1 1  sc1  add
      scr 0  sc3  ldub
      scr 1  scr  add
      sc2 ascii a cmp
      >= if
         sc2 ascii z cmp	\ Delay slot
         <= if  nop
            sc2 ascii A ascii a -  sc2  add
         then
      then
      sc3 ascii a cmp
      >= if
         sc3 ascii z cmp	\ Delay slot
         <= if  nop
            sc3 ascii A ascii a -  sc3  add
         then
      then
      sc2 sc3     cmp
      <> if   nop
         <  if
            1   tos   move      \ Delay slot
            -1  tos   move
         then
         sp 2 /n*   sp  add
         next
      then

      \ branch target
      0 L:
      tos 1  tos  subcc
   0< until  annul
      sc1 0  sc2  ldub          \ Delay slot

   0      tos  move
   sp 2 /n*  sp   add
c;

code pack  ( str-addr len to -- to )
   sp  scr  pop		\ scr is len
   sp  sc1  pop		\ sc1 is "from"; tos is "to"

   scr ff   scr  and	\ Never store more than 257 bytes

   scr  tos 0    stb	\ Place length byte

   tos 1    tos  add	\ Offset "to" by 1 to skip past the length byte

   %g0  tos scr  stb	\ Put a null byte at the end

   0 F:  bra  		\ jump to the until  branch
   scr 1    scr    subcc	\ Delay slot

   begin
      sc2   tos scr   stb
      scr 1     scr   subcc
   0 L:
   0< until annul
      sc1 scr   sc2   ldub	\ Delay slot

   tos 1   tos  sub		\ Fix "to" to point to the length byte
c;

code (')  ( -- acf )
   tos       sp   push
   ip 0      tos  rtget
   ip /token ip   add
   tos base  tos  add
c;
\ Modifies caller's ip to skip over an in-line string
code skipstr ( -- addr len)
   sp 2 /n*  sp        sub
   tos       sp 1 /n*  nput
   rp  0     scr       nget    \ Get string address in scr
   bubble
   scr 0     tos       ldub  \ Get length byte in tos
   scr 1     scr       add   \ Address of data bytes
   scr       sp 0 /n*  nput  \ Put addr on stack

   \ Now we have to skip the string
   scr tos         scr   add   \ Scr now points past the last data byte
   scr #talign     scr   add   \ Round up to token boundary + null byte
   scr #talign 1-  scr   andn
   scr             rp 0  nput  \ Put the modified ip back
c;
code (")  ( -- addr len)
   sp 2 /n*  sp     sub
   tos       sp /n  nput
   ip  0     tos    ldub  \ Get length byte in tos
   ip  1     ip     add   \ Address of data bytes
   ip        sp 0   nput  \ Put addr on stack

   \ Now we have to skip the string
   ip  tos          ip   add   \ ip now points past the last data byte
   ip  #talign      ip   add  \ Round up to a token boundary, plus null byte
   ip  #talign 1-   ip   andn
c;
code count  ( addr -- addr+1 len )
   tos 1   tos  add
   tos -1  scr  ldub
   tos     sp   push
   scr     tos  move
c;

code between ( n min max -- f )
   tos		scr	move		\ max
   sp		sc2	pop		\ min
   sp		sc3	pop		\ n
   sc3	sc2	%g0	subcc
   0>=			if
      %g0	tos	move		\ (delay)
      sc3  scr	%g0	subcc
      0>		if
         %g0 1	tos	sub		\ (delay)
         %g0  	tos	move
      then
   then
   inhibit-delay
c;

code within ( n1 min max+1 -- f )
   tos		scr	move		\ max
   sp		sc2	pop		\ min
   sp		sc3	pop		\ n
   sc3	sc2	%g0	subcc
   0>=			if
      %g0	tos	move		\ (delay)
      sc3  scr	%g0	subcc
      0<		if
         %g0  	tos	move		\ (delay)
         %g0 1	tos	sub
      then
   then
   inhibit-delay
c;

code bounds ( adr len -- adr+len adr )
   tos		scr	move		\ len
   sp		sc1	pop		\ adr
   sc1  tos	sc2	add		\ adr+len
   sc2		sp	push
   sc1		tos	move
c;

code origin  ( -- addr )
   tos  sp   push
   base tos  move
c;
code origin+  ( n -- adr )
   tos base  tos  add
c;
code origin-  ( n -- adr )
   tos base  tos  sub
c;

code i-flush  ( adr -- )
   tos 0         iflush        \ This may cause a trap on MP machines
   sp  tos       pop
c;

\  : instruction!  ( bits adr -- )
\     tuck l! i-flush
\  ;
code instruction!  ( bits adr -- )
   sp     scr    get
   scr    tos 0  st
   tos 0         iflush        \ This may cause a trap on MP machines
   sp 1 /n*  tos nget
   sp 2 /n*  sp  add
c;

: instruction, ( opcode -- )
   here /l allot instruction!
;

\ ---- Support words for the incremental compiler

headerless

\  Create constants to represent the instructions that go into the
\  delay-slots of the code-fields of various definition-types.
\  We can use the assembler itself to construct the instruction.
\  This is more efficient and accurate than using literal numerics,
\  and will also be handy in determining definition-types.

\  Because  constant  is not yet properly defined, we have to use the
\  assembler to create the code-field of a  constant  definition-type.
\  This turns out to be not too bad, because we need the assembler anyway...

\  Integer value of the instruction that goes into the delay-slot
\  after the  call  in:  create  variable  user  value  constant
\  and in the  doesclause  of a defining word that uses  does>
\
\  The instruction itself:
\      Decrements the Stack Pointer.
\dtc  code dec-sp-instr
\dtc     doconstant  call
\dtc     sp  adec	\  Execute this in the delay slot
\dtc 64\   0 l,		\  High-half of longword constant for 64-bit platforms
\dtc     sp  adec	\  This is the constant!  =  8e21e00 /n or
\dtc  end-code

\itc  label dec-sp-instr   #align-t negate allot-t   \  Kind of suckey,
						     \  but at least it works.
\  \itc  code-field: dec-sp-instr  \  Tried this instead; it failed BIG TIME!

\itc     doconstant token,-t
\itc 64\   0 l,		\  High-half of longword constant for 64-bit platforms
\itc     sp  adec	\  This is the constant!  =  8e21e00 /n or
\itc  do-exitcode


\dtc  \  Integer value of the instruction that goes into the delay-slot
\dtc  \  after the  call  in the CF of a word defined by :  (colon).
\dtc  \
\dtc  \  The instruction itself:
\dtc  \      Decrements the Return-Stack Pointer.
\dtc  code dec-rp-instr
\dtc     doconstant call
\dtc        sp  adec	\  Execute this in the delay slot
\dtc 64\   0 l,		\  High-half of longword constant for 64-bit platforms
\dtc     rp  adec	\  This is the constant!  =  8c21a000 /n or
\dtc  end-code


\dtc  \  Integer value of the instruction that goes into the delay-slot
\dtc  \  after the  call  in the CF of a child word of a  does>  definer
\dtc  \  or in the CF of an  action:  of a word defined with  used .
\dtc  \
\dtc  \  The instruction itself:
\dtc  \      Adds 8 to the PC in %o7, yielding the PFA, which goes into scr
\dtc  code pfa>scr-instr
\dtc     doconstant call
\dtc        sp  adec	\  Execute this in the delay slot
\dtc 64\   0 l,		\  High-half of longword constant for 64-bit platforms
\dtc     apf  scr  add	\  This is the constant!  =  a003e008
\dtc  end-code


\dtc  \  Integer value of the instruction that goes into the delay-slot
\dtc  \  after the  call  in the CF of a  defer  word.
\dtc  \
\dtc  \  The instruction itself:
\dtc  \      Adds 8 to the PC in %o7, yielding the PFA, and loads the
\dtc  \      contents of that location (i.e., the first Parameter) into scr
\dtc  code param>scr-instr
\dtc     doconstant call
\dtc        sp  adec	\  Execute this in the delay slot
\dtc 64\   0 l,		\  High-half of longword constant for 64-bit platforms
\dtc     apf  scr  ld 	\  This is the constant!  =  e003e008
\dtc  end-code




\  Prepare the 30-bit-wide longword-offset for a call or branch instruction
: >offset-30 ( target-addr where -- longword-offset )
   -
64\   n->l
   2 >>
;
\ Put a call instruction to target-addr at where
: put-call  ( target-addr where -- )
   tuck >offset-30		( where longword-offset )
   4000.0000         or		( where call-instruction )
   swap instruction!
;

\ Put a branch instruction to target-addr at where
: put-branch  ( target-addr where -- )
   tuck >offset-30		( where longword-offset )
     3f.ffff    and		( where branch-offset )
   3080.0000    or     		( where branch-instruction )
   swap instruction!
;

\ Replace the delay slot of the previous code field
: set-delay-slot  ( delay-instruction -- )  here /l - instruction!  ;

: place-call  ( action-adr -- )
   origin+ acf-align  here  /l 2* allot  put-call
   dec-sp-instr set-delay-slot		\  sp  adec
;

\ Place the "standard" code field, with a "sp /n  sp  sub" instruction
\ in the delay slot
: place-cf  ( action-adr -- )
\dtc  place-call
\itc  origin+ acf-align  token,
;
: code-cf  ( -- )
\dtc             acf-align
\itc \t32        here ta1+ aligned origin -
\itc \t16 [ tshift-t 4 <> ] [if]  here ta1+ aligned  origin - [else]  docode [then]
\itc             place-cf align
;
: >code  ( acf-of-code-word -- address-of-start-of-machine-code )
\itc  >body aligned
;
\dtc : code?  ( acf -- f )  \ True if the acf is for a code word
\dtc  c@ h# c0 and h# 40 <>  \ Most non-code words start with a call instr.
\dtc ;

\itc \t16 tshift-t 4 <> [if]
\itc \t16 : code? ( acf -- f )
\itc \t16    dup token@ swap  2dup 2 + = >r  4 + =  r> or
\itc \t16 ;
\itc \t16 [else]
\itc \t16 : code? ( acf -- f )
\itc \t16    token@ origin- docode =
\itc \t16 ;
\itc \t16 [then]

headers
: next  (  --- )
\    ip  0       scr  ld
\    scr base    %g0  jmpl
\    ip  /token  ip   add
\t32  e0016000 instruction,	\ ld   [%g5], %l0
\t32  81c40002 instruction,	\ jmp   %l0, %g2, %g0
\t32  [ 8a016000 /token or ]
\t32     literal instruction,	\ add  %g5, /token, %g5

\     up 0  %g0 jmpl
\     nop
\t16  81c0.e000 instruction,	\ jmp  %g3, 0, %g0
\t16  8000.0000 instruction,	\ add  %g0, %g0, %g0
;

headerless

\ The "word type" is a number that distinguishes one type of
\ word from another.  This is highly implementation-dependent.

\ For the SPARC implementation, the magic number returned by
\ word-type is the offset of the action code from the origin

\itc  \  Indicate whether the given location is a call instruction
\itc  \      and, if so, return the target address
\itc  : call-placed? ( acf -- addr true | false )
\itc     dup l@ dup c000.0000 and 4000.0000 = tuck if
\itc         2 << l->n rot + swap
\itc     else
\itc        drop nip
\itc     then
\itc  ;

headers

: word-type  ( acf -- word-type )
\dtc dup l@ 2 << l->n +
\itc token@
;

headerless

: create-cf    ( -- )  docreate   place-cf  ;
[ifdef] in-dictionary-variables
   : variable-cf  ( -- )  dovariable place-cf  ;
[then]
: place-does   ( -- )  dodoes     place-call  ;
: place-;code  ( -- )  ;

\ Ip is assumed to point to (;code .  flag is true if
\ the code at ip is a does> clause as opposed to a ;code clause.
: does-ip?  ( ip -- ip' flag )
   dup token@  ['] (does>) =  ( ip flag )
   if   ta1+ acf-aligned la1+ la1+  true  else  ta1+ acf-aligned false  then
;

: put-cf  ( action-clause-addr where -- )
\dtc   tuck put-call                    ( where )
\dtc   pfa>scr-instr	 swap la1+ instruction!		\  apf  scr  add
\itc   token!
;

\  used  sets the code field of the most-recently-defined word
\ so that it executes the code at action-clause-addr
: used  ( action-clause-addr -- )  lastacf put-cf  ;


\  Indicate whether the given address has the code-field of a does-clause.
\      (I.e., the call to  dodoes).
\  Leave the address, return a flag.
: does-clause? ( addr -- addr flag )
   dup la1+ l@ dec-sp-instr = if
      dup		\  Delay-slot instruction is right...
\dtc  word-type
\itc  call-placed? if
	 dodoes origin+ = exit
\itc  then
   then
   false
;

\  Indicate whether given ACF is of a word that was defined with
\       does> .  If so, return the  does-cfa  under the  true.
: does-cf? ( possible-acf -- does-cfa true | false )
\dtc  			\  Possible valid child word of a  does>  definer?
\dtc  dup la1+ l@ pfa>scr-instr = if			\  apf  scr  add
\dtc  			\  Delay-slot instruction is right...
	 word-type		\  Possible address of the  does-clause
	 does-clause?  ?dup nip  exit
\dtc  then
      drop false
;

headers
\ Need this to make headerless work
: colon-cf  ( -- )
   docolon place-cf
\dtc   dec-rp-instr  set-delay-slot	\ rp adec
;
headerless
: colon-cf?  ( possible-acf -- flag )
\dtc dup word-type docolon origin+ =  swap
\dtc la1+ l@  dec-rp-instr  =  and	\ rp adec
\itc      token@  ['] here token@ =
;
: user-cf  ( -- )  douser place-cf  ;
: value-cf  ( -- )  dovalue place-cf  ;
: constant-cf  ( -- )  doconstant place-cf  ;
: defer-cf  ( -- )
   dodefer place-cf
\dtc   param>scr-instr	 set-delay-slot 	\ apf  scr  ld
;
\  Indicate whether the word whose ACF is given 
\  was defined with  defer .
: defer?  ( acf -- flag )
\dtc     dup
   word-type dodefer origin+ =
\dtc     swap la1+ l@  param>scr-instr  =  and	\ apf  scr  ld
;
: 2constant-cf  ( -- )  do2constant place-cf  ;

\t16 2 constant /branch
\t32 4 constant /branch
: branch, ( offset -- )
\t32 l,
\t16 w,
;
: branch! ( offset where -- )
\t16 w!
\t32 l!
;
: branch@ ( where -- offset )
\t16 <w@
\t32 <l@
;
\ >target depends on the way that branches are compiled
: >target  ( ip-of-branch-instruction -- target )  ta1+ dup branch@ +  ;

\ ---- More ordinary Forth words.

headers
/a constant /a
[ifexist] t8
: a@  ( adr -- adr' )  @ origin+  ;
: a!  ( adr1 adr2 -- )  swap origin- swap !  ;
[else]
code a@  ( adr -- adr' )
\t16 tos 0 tos lduh  tos tshift-t tos sll
\ XX 64\ \t32 tos /l  scr ld
\ XX 64\ \t32 tos tos lget
\ XX 64\ \t32 tos h# 20 tos sllx
\ XX 64\ \t32 tos scr tos or
\t32 tos tos lget
   tos base tos add
c;
code a!  ( adr1 adr2 -- )
   sp         scr  pop
   scr base   scr  sub
\t16   scr tshift-t    scr  srl
\t16   scr           tos 0  sth
\ XX 64\ \t32   scr     tos /l  st
\ XX 64\ \t32   scr  h# 20 scr  srlx
\t32   scr     tos 0   st
   sp         tos  pop
c;
[then]
: a,  ( adr -- )  here  /a allot  a!  ;

/token constant /token
code token@ ( addr -- cfa )
   tos 0     tos  rtget
   tos base  tos  add
c;
code token! ( cfa addr -- )
   sp        scr  get
   bubble
   scr base  scr  sub
\t16  scr tshift-t  scr      srl
\t16  scr    tos 0    sth
\t32  scr    tos      lput ( ???XXX tput )
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;

: token, ( cfa -- )  here  /token allot  token!  ;

code null  ( -- token )
   tos   sp   push
   base  tos  move
c;
: !null-link   ( adr -- )  null swap link!  ;
: !null-token  ( adr -- )  null swap token!  ;
code non-null?  ( link -- false | link true )
   tos  base    cmp
   <>  if
   false scr  move       \ Delay slot

      tos  sp  push
      true scr move
   then
   scr  tos  move
c;
: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;


code body> ( pfa -- cfa )
\dtc	tos	8	tos	sub
\itc	tos	/token	tos	sub
c;
code >body ( cfa -- pfa )
\dtc    tos	8	tos	add
\itc	tos	/token	tos	add
c;
\t16 /w constant /user#
\t32 /l constant /user#

\ Move to a machine alignment boundary.
\ SPARC requires alignment on 32-bit boundaries, but we only require
\ 16-bit alignment in the 16-bit token version, using halfword memory
\ accesses to make this work.

: round-down  ( adr granularity -- adr' )  1- invert and  ;
: round-up  ( adr granularity -- adr' )  1-  tuck +  swap invert and  ;
: (align)  ( size granularity -- )
   1-  begin  dup here and  while  0 c,  repeat  drop
;
: aligned  ( adr -- adr' )  3 + -4 and  ;

code acf-aligned  ( adr -- adr' )
\t16  1 tshift-t << 1 -  scr  move
\t32  3                  scr  move
      tos scr            tos  add
      tos scr            tos  andn
c;
: acf-align  ( -- )  #acf-align (align)  here 'lastacf token!  ;

headers
: /mod  ( dividend divisor -- remainder quotient )
  \ Check if either factor is negative
    2dup               ( n1 n2 n1 n2)
    or 0< if           ( n1 n2)

        \ Both factors not non-negative do division by:
        \ Take absolute value and do unsigned division
        \ Convert to truncated signed divide by:
        \  if dividend is negative then negate the remainder
        \  if dividend and divisor have opposite signs then negate the quotient
        \ Then convert to floored signed divide by:
        \  if quotient is negative and remainder is non-zero
        \    add divisor to remainder and decrement quotient

        2dup swap abs swap abs  ( n1 n2 u1 u2)     \ Absolute values

        u/mod              ( n1 n2 urem uqout)     \ Unsigned divide
        >r >r              ( n1 n2) ( uquot urem)

        over 0< if         ( n1 n2) ( uquot urem)
            r> negate >r                   \ Negative dividend; negate remainder
        then               ( n1 n2) ( uquot trem)

        swap over          ( n2 n1 n2) ( uquot trem)
        xor 0< if          ( n2) ( uquot trem)
            r> r>
            negate         ( n2 trem tquot)  \ Opposite signs; negate quotient
           -rot            ( tquot n2 trem)
            dup 0<>  if
                +          ( tquot rem) \ Negative quotient & non-zero remainder
                swap 1-    ( rem quot)  \ add divisor to rem. & decrement  quot.
            else
                nip swap   ( rem quot)
            then
        else
            drop r> r>     ( rem quot)
        then

    else   \ Both factors non-negative

        u/mod          ( rem quot)
    then
;

: /     ( n1 n2 -- quot )   /mod  nip ;

: mod   ( n1 n2 -- rem )    /mod  drop  ;

headerless
\ SPARC version is dynamically relocated, so we don't need a bitmap
: clear-relocation-bits  ( adr len -- )  2drop  ;
headers
