id: @(#)elfsym.fth 1.6 95/05/31
purpose: 
copyright: Copyright 1992-1994 Sun Microsystems, Inc.  All Rights Reserved

\ symtab.fth 2.3 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ Creates an ELF-format symbol table.
\
\    add-symbol  ( value name type -- )   \ Adds a symbol to the symbol table
\    symbol-table  ( -- adr )             \ Base address of symbol table
\    /symbol-table  ( -- n )              \ Current size of symbol table
\    string-table  ( -- adr )             \ Base address of string table
\    /string-table  ( -- n )              \ Current size of string table
\    clear-symbol-table  ( -- )           \ Deallocates space used by tables
\    set-symbol-usage  ( adr -- )         \ Last symbol referenced at adr
\    find-symbol-usage  ( name -- adr )   \ Location where name is referenced

decimal

headerless
100 value #symbols-max
 15 constant avg-bytes/string

alias /sym /elf32-symbol

variable symbol#
0 value symbol-table
: /sym*  ( index -- offset )  /sym  *  ;	\ String offset, flags, value
: /symbol-table  ( -- n )  symbol# @  /sym*  ;
#symbols-max /sym*  constant /symbol-table-max

0 value symbol-used		\ Array of pointer to symbol references
#symbols-max /l*              constant /symbol-used

0 value string-table
#symbols-max avg-bytes/string *  /l +        constant /string-table-max

0 value /string-table

defer $add-symbol
: ?initialize-symbol-table  ( -- )    \ Allocate memory for tables if needed
   symbol-table 0=  if
      symbol# off
      /symbol-table-max   alloc-mem  is symbol-table
      /symbol-used        alloc-mem  is symbol-used
      /string-table-max   alloc-mem  is string-table
\      0 string-table c!  1 to /string-table	\ Skip the beginning null byte
      0  " "  0 $add-symbol                     \ Required null symbol entry
      0  " "  h# 0003.0003 $add-symbol  \ Data section
      0  " "  h# 0002.0003 $add-symbol  \ Text section
   then
;
: clear-symbol-table  ( -- )    \ Deallocate memory used by tables
   symbol-table 0<>  if
      string-table /string-table-max   free-mem
      symbol-used  /symbol-used        free-mem
      symbol-table /symbol-table-max   free-mem
      0 is symbol-table
   then
;
: omit-_  ( adr,len -- adr',len' )
   dup 1 >=  if
      over c@  ascii _  =  if
         1 /string
      then
   then
;
: >sym-offset  ( index -- offset )
   /sym*  symbol-table  +  st32_name  l@  ( string-table-offset )
;
: symname  ( index -- adr len )
   >sym-offset  string-table +  cscount
;
: $find-symbol  ( adr,len -- symbol# )  \ Symbol# is -1 if not found
   omit-_                    ( adr len sym# )
   -1  -rot                  ( sym# adr len )
   symbol# @  0  ?do         ( sym# adr len )
      2dup  i symname  $=  if  rot drop i -rot  leave  then   ( sym# adr len )
   loop    ( sym# adr len )
   2drop     ( sym# )
;
: $place-string  ( adr,len -- location )	\ Internal factor
   2dup $find-symbol dup -1 <>  if  ( adr,len )
      nip nip  >sym-offset  exit
   then                        ( adr,len -1 )
   drop                        ( adr,len )
   omit-_
   dup 1+  /string-table  +      ( adr len end-index )
   dup  /string-table-max  >=
   abort" String table overflow; increase /string-table-max"
   >r                            ( adr len )
   /string-table string-table +  swap cmove   ( )
   0  r@ 1- string-table +  c!
   /string-table
   r> is /string-table
;
\ Interesting values for $add-symbol's "type" argument

h# 0000.0010 constant undefined-external        \ Undef, global, STT_NOTYPE
h# 0002.0012 constant external-procedure        \ Text,  global, STT_FUNC
h# 0003.0011 constant external-variable         \ Data,  global, STT_OBJECT
h# fff2.0014 constant external-common           \ Common,global, STT_OBJECT

: $add-sized-symbol  ( value name,len type size -- )
   ?initialize-symbol-table
   symbol# @  #symbols-max >=
   abort" Symbol table overflow; increase #symbols-max"

   symbol-table  /symbol-table +     ( value name,len type size adr )
   >r                                ( value name type size )
   0 r@ st32_other c!                \ Clear boring field
   r@ st32_size l!                   ( value name,len type )
   dup r@ st32_info c!               ( value name,len type )
   d# 16 >> r@ st32_shndx w!         ( value name,len )
   rot  r@ st32_value l!             ( name,len )
   $place-string  r> st32_name l!    ( )
   1 symbol# +!
;
: ($add-symbol)  ( value name,len type -- )
   0 $add-sized-symbol
;
' ($add-symbol) is $add-symbol
: set-symbol-usage  ( adr -- )  symbol-used  symbol# @ 1-  la+  !  ;

: $find-symbol-usage  ( adr,len -- adr )
   $find-symbol  ( sym# )
   dup 0<  if  drop 0  else  symbol-used swap la+  l@  then
;

: ?$add-symbol  ( name$ -- sym# )
   2dup  $find-symbol                       ( name,len sym# )
   dup 0<  if                               ( name,len sym# )
      drop                                  ( name,len )
      0 -rot undefined-external $add-symbol ( )
      symbol# @ 1-                          ( sym# )
   else                                     ( name,len sym# )
      nip nip                               ( sym# )
   then                                     ( sym# )
;
: terminate-string-table  ( -- )  " " $place-string  drop  ;

0 is symbol-table
headers
