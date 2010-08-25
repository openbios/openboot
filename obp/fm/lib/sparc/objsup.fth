\ objsup.fth 2.11 99/05/04
\ Copyright 1985-1990 Bradley Forthware

\ SPARC version.
\ Machine dependent support routines used for the objects package.
\ These words know intimate details about the Forth virtual machine
\ implementation.

\ Assembles the common code executed by actions.  That code
\ extracts the next token (which is the acf of the object) from the
\ code stream, and leaves the corresponding apf in scr

headerless

: start-code ( -- )  code-cf !csp  ;

\ Assembles the code which begins a ;code clause
\ For SPARC, the apf of the child word is left in scr
: start-;code  ( -- )  start-code  ;

\ Code for executing an object action.  Extracts the next token
\ (which is the apf of the object) from the code stream and pushes
\ it on the stack.  Then performs the action of "docolon".

\ The Forth token stream contains a pointer to the code:
\ doaction call    sp adec
: doaction  ( -- )  acf-align colon-cf  ;

\ Returns the address of the code executed by the word whose code field
\ address is acf
: >code-adr  ( acf -- code-adr )
\dtc   dup l@ 2 << l->n +    \ Converts relative call instruction to target address
\itc   token@
;

code >action-adr  ( object-acf action# -- )
  ( ... -- object-acf action# #actions true | object-apf action-adr false )
                          \ action# in tos
      sp 0     scr  nget  \ object-acf in scr
\dtc  scr 0    sc1  ld    \ Call instruction in sc1
\dtc  sc1 2    sc1  sll   \ Call relative offset in sc1
64\ \dtc sc1 0    sc1  sra   \ Sign extend
\dtc  scr sc1  sc1  add   \ code address in sc1
\itc  scr 0    sc1  rtget \ code offset in sc1
\itc  sc1 base sc1  add	  \ code address in sc1
      \ You might think that this should be "/n*" and "nget".
      \ Superficially, that is correct.  However, the location of the
      \ #actions field is not necessarily 64-bit aligned, so an
      \ ldx instruction could fail.  Since #actions isn't likely
      \ to be more than 2**32 :-), it suffices to read just 32 bits.
      sc1 -1 /l*  sc2   ld    \ #actions in sc2
      sc2         tos   cmp   \ Test action
      <= if		      \ "true" branch is error
         sp /n    sp    sub   \ Make room on stack (delay slot)
         sp /n    sp    sub   \ The error case needs more room on the stack
         tos      sp 1 /n*  nput  \ Place action# on stack
         sc2      sp 0 /n*  nput  \ Place #actions on stack
      else
         true     tos   move  \ Return true for error  (delay)

\dtc     scr 8       scr   add   \ Compute action-apf from action-acf
\itc     scr /token  scr   add   \ Compute action-apf from action-acf
         scr    sp 1 /n*   nput  \ Put action-apf on stack

\t16     tos 1       tos   sll   \ Convert #actions to token offset
\t32     tos 2       tos   sll   \ Convert #actions to token offset
         sc1 tos     sc1   sub   \ Skip back several tokens
         sc1 -1 /n*  sc1   rtget \ Get action-adr token
         sc1 base    sc1   add   \ Relocate
         sc1    sp 0 /n*   nput  \ Put action-adr on stack
         false       tos   move  \ Return false for no error
      then
c;

headers
: action-name  \ name  ( action# -- )
   create  		\ Store action number in data field
\t16   w,
\t32   l,
   ;code               ( -- object-pfa )
\t16  apf         scr  lduh	\ Action# in scr
\t32  apf         scr  ld	\ Action# in scr

      ip  0       sc1  rtget	\ Object acf in sc1
      ip  /token  ip   add	\ Advance to next token
      sc1 base    sc1  add	\ Relocate

      tos         sp   push
\dtc  sc1 8       tos  add	\ Compute and push object-apf
\itc  sc1 /token  tos  add	\ Compute and push object-apf

\dtc  sc1 0       sc2  ld	\ Call instruction in sc2
\dtc  sc2 2       sc2  sll	\ Call relative offset in sc2
64\ \dtc sc2 0       sc2  sra	\ Sign extend
\dtc  sc1 sc2     sc1  add	\ default action code address
\itc  sc1 0       sc1  rtget	\ relative version of ..
\itc  sc1 base    sc1  add	\ default action code address

\t16  scr 1       scr  sll      \ Convert action# to token offset
\t32  scr 2       scr  sll      \ Convert action# to token offset
      sc1 scr     sc1  sub      \ Skip back action# tokens
      sc1 -1 /n*  scr  rtget    \ Get action-adr token

\dtc  scr base    %g0  jmpl	\ Tail of "next"

\itc  scr base    sc1  add
\itc  sc1 0       scr  rtget    \ Tail of "next"
\itc  scr base    %g0  jmpl

      nop
end-code

: >action#  ( apf -- action# )
\t16  w@
\t32  l@
;
