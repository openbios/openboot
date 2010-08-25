\ aout.fth 2.4 97/01/23
\ Copyright 1985-1990 Bradley Forthware

\ Support for reading "a.out" (linker) files
\ This is system-dependent; this version is correct for Sun Microsystems'
\ implementation of 4.2 BSD.  Other systems may be more or less different
\ For instance, Masscomp splits the a_magic field into 2 16-bit words.
\ System V uses a "common object file format" which is much different.

decimal
headerless
struct  \ "a.out-header" structure - a.out header
  0  field a_magicword	    \ Alias for the next 4 bytes as a whole
  /c field a_toolversion
  /c field a_machtype
  /w field a_magic
  /l field a_text
  /l field a_data
  /l field a_bss
  /l field a_syms
  /l field a_entry
  /l field a_trsize
  /l field a_drsize
constant /a.out-header
/a.out-header buffer: a.out-header

\ Words which return the size in bytes of various components of the a.out file

: /text  ( -- size-of-text-segment )   a.out-header a_text l@ ;
: /data  ( -- size-of-data-segment )   a.out-header a_data l@ ;
: /bss   ( -- size-of-bss-segment )    a.out-header a_bss  l@ ;
: /syms  ( -- size-of-symbol-table )   a.out-header a_syms l@ ;
: /reloc ( -- size-of-relocation )     a.out-header a_trsize l@  
                                       a.out-header a_drsize l@  + ;
: entry-adr  ( -- load-address )       a.out-header a_entry l@ ;

\ Words which return the offset from the start of the a.out file of various
\ components of the a.out file

: text0  ( -- file-address-of-text ) /a.out-header ;
: data0  ( -- file-address-of-data ) text0 /text + ; 
: reloc0 ( -- file-address-of-relocation ) data0 /data + ; 
: syms0  ( -- file-address-of-symbols ) reloc0 /reloc + ; 
: string0 ( -- file-address-of-strings ) syms0 /syms + ; 

: ?magic  ( -- )
   a.out-header a_magic w@  h# 107 <>
   abort" Magic number is not (octal) 407"
;
: read-header  ( -- )
   a.out-header 4  ifd @  fgets  4 <> abort" Can't read the magic number"
   ?magic
   a.out-header 4 +  /a.out-header 4 -  ifd @ fgets
   /a.out-header 4 - <> abort" Can't read header"
;
headers
