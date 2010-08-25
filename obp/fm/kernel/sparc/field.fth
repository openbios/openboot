\ field.fth 2.6 94/09/05
\ Copyright 1985-1990 Bradley Forthware

\ field creates words which add their offset within the structure
\ to the base address of the structure

: struct  ( -- 0 )  0  ;

: field  \ name  ( offset size -- offset+size )
   create over l, +
\  does> l@ + ;
   ;code  ( struct-adr -- field-adr )
\t32  apf       scr  ld     \ Get the offset
\t16  apf       scr  lduh   \ Get the high word of the offset
\t16  apf 2+    sc1  lduh   \ Get the low word of the offset
\t16  scr d# 16 scr  sll    \ Multiply by 2^^16
\t16  scr sc1   scr  add    \ Merge the two halves
      scr tos   tos  add    \ Return the structure member address
c;
