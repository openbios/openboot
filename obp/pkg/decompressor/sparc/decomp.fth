\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: decomp.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)decomp.fth 1.2 01/04/06
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless

\ In:
\   scr = decomp data ptr
\   sc1 = src addr
\   sc2 = #bytes remaining
\ Out:
\   tos = byte|-1
\
label decomp-getabyte
   scr  0 >source-addr  sc1  ld		\ scr = src addr
   scr  0 >source-size  sc2  ld		\ sc1 = #bytes left
   sc2  1  sc2 subcc
   0>= if
      %g0  -1   tos  add		\ (delay)
      sc1  %g0  tos  ldub		\ get data
      sc1    1  sc1  add
      sc1  scr  0 >source-addr st	\ update src pointer
   then
   retl
   sc2  scr  0 >source-size  st		\ update #bytes left (delay)
end-code

\
\ Forth Version of assembler routine
\
code decomp-getbyte ( data-buffer -- byte|-1 )
   decomp-getabyte call    tos  scr move
c;

code decomp-putbyte ( byte buffer -- )
   tos  sc1  move
   sp   scr  pop
   sp   tos  pop
   sc1  0 >dest-addr sc2  ld		\ get dest address
   scr  sc2  %g0  stb			\ write data
   sc2    1  sc2  add
   sc2  sc1  0 >dest-addr st		\ update ptr
c;

\ In:
\   tos
\ Scratch:
\   scr, sc1, sc2	- by getabyte
\   sc3, sc4, sc5	- by getcode
\ Out:
\   tos
\
code decomp-getcode ( bits buffer -- code )
   tos  scr  move			\ preserve buffer ptr
   sp   sc3  pop
   scr  0 >getcode-offset   sc4 ld	\ get previous offset
   scr  0 >getcode-oldcode  sc5 ld	\ get previous code

\ Watch the 'if' trick coming up.

   begin
      decomp-getabyte  call nop
      tos -1  %g0 subcc
      <>  if  but
         tos  sc4  sc1  sll		\ (byte << r_off)	(delay)
         sc4    8  sc4  add		\ r_off += 8
         sc4  sc3       cmp
   >= until
      sc5  sc1  sc5  add		\ code += (byte << r_off) (delay)

   sc5  sc3  sc1  srl			\ (code >> bits)
   sc4  sc3  sc2  sub			\ r_off - bits
   sc1  scr  0 >getcode-oldcode  st	\ getcode_oldcode = (code >> bits)
   sc2  scr  0 >getcode-offset   st	\ getcode_offset = (r_off - bits)

   %g0    1  scr  sub
   scr  sc3  scr  sllx			\ mask = (-1 << bits)
   sc5  scr  tos  andn			\ tos = tos & ~mask
   then
c;
