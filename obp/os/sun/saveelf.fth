\ saveelf.fth 1.4 95/04/19
\ Copyright 1985-1991 Bradley Forthware

only forth also definitions
headerless

only forth also hidden also forth definitions

\ Save an image of the target system in the Unix file whose name
\ is the argument on the stack.

: text-base  ( -- )  origin  ;
: text-size  ( -- )  here text-base -  7 +  7 invert and  ;

\ \ Adds "text-size" to all the symbols in the data segment, because the
\ \ linker expects data segment addresses to start at the end of the text
\ \ segment.
\ : adjust-data-symbols  ( -- )
\    symbol# @  1  ?do
\       i /sym* symbol-table +  dup sym_type c@   ( adr symbol-type )
\       h# 1e and  6 =  if
\          sym_value  text-size swap +!
\       else
\          drop
\       then
\    loop
\ ;

\ This is a hack way to create a "common" symbol to cause BSS space to
\ be allocated at the end of the image.  This saves PROM space by not
\ requiring unitialized parts of the user area image to be stored in the
\ data segment.  The following line creates a very simple symbol table
\ entry with just one entry "_foo", of type "common", whose size will be
\ set later when it is determined (the size field is at offset 8).
\ The array "symbol" will later be copied into a file called "userbss.o"
\ The bytes are as follows (see /usr/include/nlist.h):
\ 0 - offset into string table for this symbol's name entry
\ 4 - symbol type (1000000 == "common")
\ 8 - symbol value (set later to the bss size)
\   (String table begins at offset c)
\ c - string table size (including padding)
\ 10 - The string "_foo", null terminated
\ 15 - padding to align to a longword boundary

: ,cstring  ( adr len -- )
   here over allot  swap move  0 c,
;

hex

0 value default-elf-header

0 value section-headers
0 value /section-headers
0 value section-names
0 value /section-names

: >section  ( sec# -- adr )  /elf32-sheader *  section-headers  +  ;
: !name  ( sec# -- )  here section-names -  swap >section st32_name l!  ;

: lalign  ( -- )  here /l round-up here - allot  ;    \ longword align

lalign
here is default-elf-header

   7f c,  ascii E c,  ascii L c,  ascii F c,    \ 0-3 Magic number
    1 c,        2 c,        1 c,                \ 4,5,6  32-bit, big-endian, V1
    0 c,  0 c,  0 c,  0 c,  0 c,  0 c,  0 c,  0 c,  0 c,    \ 7-15 Reserved
    1 w,        2 w,        1 l,                \ 16,18,20 relocatable,SPARC,V1
    0 l,        0 l,                            \ 24,28 no entry, no phdr
    /elf32-header l,        0 l,                \ 32,36 shdr offset, no flags
    /elf32-header w,                            \ 40 ehdr size
    0 w,        0 w,                            \ 42,44 no phdr, no phdr
    /elf32-sheader w,                           \ 46 shdr size
    9 w,                                        \ 48 #sections
    1 w,                                        \ 50 section name table sec#

here is section-headers
\ nam type  flags  addr  offs  size  link  info  align  entsize

 0 l,  0 l,  0 l,  0 l,  0 l,  0 l,  0 l,  0 l,  0 l,   0 l,  \ 0 Null

 0 l,  3 l,  0 l,  0 l,  0 l,  0 l,  0 l,  0 l,  1 l,   0 l,  \ 1 shnames

 0 l,  1 l,  6 l,  0 l,  0 l,  0 l,  0 l,  0 l,  4 l,   0 l,  \ 2 text

 0 l,  1 l,  3 l,  0 l,  0 l,  0 l,  0 l,  0 l,  4 l,   0 l,  \ 3 data

 0 l,  8 l,  3 l,  0 l,  0 l,  0 l,  8 l,  0 l,  4 l,   0 l,  \ 4 bss

 0 l,  4 l,  0 l,  0 l,  0 l,  0 l,  7 l,  2 l,  4 l,   c l,  \ 5 rela.text

 0 l,  4 l,  0 l,  0 l,  0 l,  0 l,  7 l,  3 l,  4 l,   c l,  \ 6 rela.data

 0 l,  2 l,  2 l,  0 l,  0 l,  0 l,  8 l,  3 l,  4 l,  10 l,  \ 7 syms

 0 l,  3 l,  2 l,  0 l,  0 l,  0 l,  0 l,  0 l,  1 l,   0 l,  \ 8 strtab

here section-headers -  is /section-headers

here is section-names

0 !name   " " ,cstring                  \ Required null entry
1 !name   " .shstrtab"     ,cstring
2 !name   " .text"         ,cstring
3 !name   " .data"         ,cstring
4 !name   " .bss"          ,cstring
5 !name   " .rela.text"    ,cstring
6 !name   " .rela.data"    ,cstring
7 !name   " .symtab"       ,cstring
8 !name   " .strtab"       ,cstring
here section-names - is /section-names
          " " ,cstring                  \ Terminating entry

\ : /headers  ( -- n )  /elf32-header /section-headers +  /section-names +  ;

: !loc  ( offset size sec# -- offset' )
   2dup >section >sh32_size l!

   \ SHT_NOBITS occupies no space in the file
   >r r@ >section >sh32_type l@  8 =  if  drop 0  then   ( offset size )

   bounds  r> >section >sh32_offset l!                   ( offset' )
;

headers
: save-obj  ( str -- )
   terminate-string-table

\   #align  p" _userbss"  external-common  user-size  #user @ -
\   add-sized-symbol

   new-file

   /elf32-header /section-headers +     ( first-offset )

   /section-names        1 !loc   \ Section name table size
   text-size             2 !loc   \ Text size
   #user @               3 !loc   \ Data size
   user-size  #user @ -  4 !loc   \ BSS size
   /relocation-table     5 !loc   \ Text reloc. table size
   0                     6 !loc   \ Data reloc. table size
   /symbol-table         7 !loc   \ Symbol table size
   /string-table         8 !loc   \ String table size
   drop

   " stand-init-io" $find-name is init-io
   " stand-init"    init-save

   default-elf-header   /elf32-header      ofd @  fputs   \ ELF header
   section-headers      /section-headers   ofd @  fputs   \ Section headers
   section-names        /section-names     ofd @  fputs   \ Section name table

   text-base            text-size          ofd @  fputs
   up@                  #user @            ofd @  fputs

   relocation-table     /relocation-table  ofd @  fputs
   symbol-table         /symbol-table      ofd @  fputs
   string-table         /string-table      ofd @  fputs

   ofd @ fclose

;

only forth also definitions
