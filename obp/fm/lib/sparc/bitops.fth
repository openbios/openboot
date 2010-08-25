\ bitops.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ id bitops.fth 1.1 88/06/02
 
code bitset  ( bit# array -- )
			\ Adr in tos
   sp       scr  pop	\ Bit# in scr
   h# 80    sc1  move	\ Mask
   scr 7    sc2  and	\ Bit Shift count
   scr 3    sc4  srl    \ Byte offset in sc4
   tos sc4  sc3  ldub   \ Get the byte
   sc1 sc2  sc1  srl    \ Interesting bit in sc1
   sc1 sc3  sc3  or	\ Set the appropriate bit
   sc3  tos sc4  stb    \ Put the byte back
   sp       tos  pop	\ Clean up stack
c;
code bitclear ( bit# array -- )
			\ Adr in tos
   sp       scr  pop	\ Bit# in scr
   h# 80    sc1  move	\ Mask
   scr 7    sc2  and	\ Bit Shift count
   scr 3    sc4  srl    \ Byte offset in sc4
   tos sc4  sc3  ldub   \ Get the byte
   sc1 sc2  sc1  srl    \ Interesting bit in sc1
   sc3 sc1  sc3  andn	\ Clear the appropriate bit
   sc3  tos sc4  stb    \ Put the byte back
   sp       tos  pop	\ Clean up stack
c;
code bittest ( bit# array -- flag )
			\ Adr in tos
   sp       scr  pop	\ Bit# in scr
   h# 80    sc1  move	\ Mask
   scr 7    sc2  and	\ Bit Shift count
   scr 3    sc4  srl    \ Byte offset in sc4
   tos sc4  sc3  ldub   \ Get the byte
   sc1 sc2  sc1  srl    \ Interesting bit in sc1
   sc1 sc3  sc3  andcc	\ Clear the appropriate bit
   0<>  if
   false    tos  move	\ Expect false (delay slot)
      true  tos  move	\ True
   then
c;
