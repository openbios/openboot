\ exports.fth 2.6 94/09/06
\ Copyright 1985-1990 Bradley Forthware

\ Words to export Forth procedures and user variable to the linker.

\ needs "=               ../extensions/stringeq.fth
\ needs /sym             ../unix/nlist.fth
\ needs add-symbol       ../unix/symtab.fth
\ needs relocation-table ../unix/sparc/reloc.fth
\ needs add-call         ../unix/sparc/call.fth

: $export-procedure  ( adr name-adr,len -- )
   rot origin-   -rot  external-procedure $add-symbol
;
: $export-variable   ( adr name-adr,len -- )
   rot up@ -     -rot  external-variable  $add-symbol
;
