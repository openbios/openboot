\ loclabel.fth 2.10 02/05/02
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Local labels for the assembler.
\ A local label can be inserted in an assembly-language program
\ to mark a position.  A relative branch instruction can then reference
\ that location by its local name.
\
\ Local label names:               0 L:  1 L:  2 L:  3 L:  etc.
\ Local label forward references:  0 F:  1 F:  etc
\ Local label backward references: 0 B:  1 B:  etc
\
\ There are 5 local labels, numbered 0 to 4.
\ Each local label may be referenced from up to 10 locations.
\
decimal
also assembler definitions

headerless
20 constant #references-max
10 constant #labels-max

#labels-max  #references-max *  /n* buffer: references
#labels-max /n* buffer: local-labels
#labels-max /n* buffer: next-references

: >reference  ( index -- adr )  /n* #references-max *  references +  ;

: >label  ( index -- adr )  local-labels swap na+  ;

: >next-reference  ( index -- adr )  next-references swap na+  ;

: resolve-forward-references  ( label# -- )
   dup >next-reference @
   [ also forth ] swap [ previous ] >reference

   ?do  i @  >resolve  /n +loop
;

\ Erase all forward references from this label
: clear-label  ( label# -- )  dup >reference  swap >next-reference  !   ;

headers
: L:  ( label# -- )
   dup resolve-forward-references       ( label# )
   dup >label   over >next-reference !  ( label# )
   dup clear-label                      ( label# )
   >label   <mark [ also forth ] swap [ previous ] !
;

: B:  ( label# -- adr )   \ Find the address of a backward reference
   >label @  <resolve
;

: F:  ( label# -- adr )   \ Remember a forward reference
   >mark
   over >next-reference @  !
   /n [ also forth ] swap [ previous ] >next-reference +!
   here   \ the address we leave is a dummy
;

headerless
: init-labels  ( -- )
   #labels-max  0   do  i clear-label  loop
;

init-labels

[ifexist] do-label-hook

' init-labels is do-label-hook

[else]

where ." Bootstrap code.." cr
\ Bootstrapping..

also forth definitions
: code code [ also assembler ] init-labels [ previous ] ;
: label label [ also assembler ] init-labels [ previous ] ;
previous definitions

[then]


previous definitions
