\ binhdr.fth 2.6 96/02/29
\ Copyright 1985-1990 Bradley Forthware

\ Header for Forth ".exe" file to be executed by the C wrapper program.
hex

only forth also hidden also
forth definitions
headerless

hidden definitions
h# 20 buffer: bin-header
: wstruct 0 ;
: wfield  \ name ( offset size -- offset' )
   create
   over w,  +
   does>     ( struct-base -- field-addr )
   w@ bin-header +
;
: long  4 wfield  ;

wstruct ( Binary header)
 long h_magic	(  0)		\ Magic Number
 long h_tlen    (  4)		\ length of text (code)
 long h_dlen	(  8)		\ length of initialized data
 long h_blen	(  c)		\ length of BSS unitialized data
 long h_slen	(  10)		\ length of symbol table
 long h_entry	(  14)		\ Entry address
 long h_trlen	(  18)		\ Text Relocation Table length
 long h_drlen	(  1c)		\ Data Relocation Table length
constant /bin-header ( 20)

: text-size  ( -- size-of-dictionary )  dictionary-size aligned  ;
headers

only forth also definitions
