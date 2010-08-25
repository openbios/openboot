\ reloc.fth 2.6 01/04/06
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Unix Relocation for SPARC
\    relocation-table  ( -- adr )         \ Base address of relocation table
\    /relocation-table  ( -- n )          \ Current size of relocation table
\    add-reference  ( adr name -- )       \ Relocate longword at adr to name
\    add-call  ( adr name -- )            \ Relocate call at adr to name
\    set-reference  ( adr name -- )	  \ Relocate sethi,or at adr to name

headerless
100 constant #relocations-max

struct  ( relocation-datum )
  /l field  r_address	\ address which is relocated
   3 field  r_sym#      \ sym# in high 24 bits, flags in low byte
  /c field  r_flags     \ flags:

\    unsigned int    r_extern  : 1;  /* if F, r_index==SEG#; if T, SYM idx */
\    int                       : 2;  /* <unused>                           */
\    enum reloc_type r_type    : 5;  /* type of relocation to perform      */

  /l field  r_addend    \ addend for relocation value
constant /reloc-struct

variable relocation#
: /reloc*  ( index -- offset )  /reloc-struct *  ;
: /relocation-table  ( -- n )  relocation# @  /reloc*  ;
#relocations-max /reloc*  constant /relocation-table-max
/relocation-table-max  buffer: relocation-table

overload: clear-symbol-table  ( -- )  clear-symbol-table  relocation# off  ;

: make-relocation  ( adr sym# offset type -- )
   2swap
   relocation# @  /reloc*  relocation-table + >r     ( offset type adr sym# )
   swap  r@ r_address l!                             ( offset type sym# )
   8 <<  r@ r_sym#    l!                             ( offset type )
   r@ r_flags c!          \ Set relocation type      ( offset )
   r> r_addend l!         \ Set offset               ( offset )
   1 relocation# +!
;

\ Longword reference
: $add-reference  ( adr name-adr,len -- )
   ?$add-symbol 0  sparc-32 make-relocation
;

\ Call instruction (offset is -adr because calls are relative)
: $add-call  ( adr name-adr,len -- )
   ?$add-symbol over negate  sparc-wdisp30 make-relocation
;

\ "set" (sethi + or) instruction
\ Used as follows:
\    here p" _foobar"  set-reference
\    0      %l0  sethi
\    %l0 0  %l0  or

: $set-reference-hi22  ( adr name-adr,len -- )
   ?$add-symbol                  ( adr sym# )
   0 sparc-hi22 make-relocation  (  )		\ high 22 bits
;
: $set-reference-lo10  ( adr name-adr,len -- )
   ?$add-symbol                  ( adr sym# )
   0 sparc-lo10 make-relocation  (  )		\ low 10 bits
;
: $set-reference  ( adr name-adr,len -- )
   3dup	$set-reference-hi22	( adr name-adr,len )
   rot 4 + -rot			( adr+4 name-adr,len )
   $set-reference-lo10		( adr name-adr,len )

;
headers
