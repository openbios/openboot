\ moveslow.fth 1.5 93/10/21
\ Copyright 1985-1990 Bradley Forthware

\ Mike Saari's blazing `move' ...
\ This implements the MOVE instruction.  It is optimized
\ for speed, particularly when longword stores may be used.
\ This version omits the doubleword optimization for machines where
\ doubleword operations do not work.

code (move)  ( src dst cnt -- )
			\ tos = Count
   sp 1 /n*  scr   nget	\ scr = Src address
   sp 0 /n*  sc1   nget	\ sc1 = Dst address
			\ sc2 = Temp. data being transferred
			\ sc3 = src xor drc, low bits=0 indicates compatible
			\ sc4 = Working src in loops
			\       (also temp last+1 address)
			\ sc5 = Working dst in loops
			\ sc6 = Loop index

   scr sc1  %g0  subcc	\ Src > dst?
   > if			\ Then copy low-to-high
      scr sc1  sc3  xor		\ (delay) sc3 low bits=0 indicates compatible

      tos h# 10   %g0  subcc	\ Enough bytes to bother optimizing?
      >= if			\ Otherwise, just skip to byte move
         sc3 1    %g0  andcc	\ (delay) =0 if at least shortword aligned
         0= if			\ Otherwise, just skip to byte move

            scr 1   %g0  andcc		\ (delay) Not on halfword boundary?
            0<> if		\ Ensure halfword alignment (lower)
               scr 0  sc2  ldub		\ (delay) Load bottom byte
               sc2  sc1 0  stb		\ Store byte
               scr 1  scr  add		\ Advance by one byte
               sc1 1  sc1  add		\  "
               tos 1  tos  sub		\ Decrement count
            then

            sc3 2   %g0  andcc		\ =0 if at least longword aligned
            0= if			\ Otherwise, skip to halfword case

               scr 2  %g0  andcc	\ (delay) Not on longword boundary?
               0<> if			\ Ensure longword alignment (lower)
                  scr 0  sc2  lduh	\ (delay) Load bottom halfword
                  sc2  sc1 0  sth	\ Store halfword
                  scr 2  scr  add	\ Advance by one halfword
                  sc1 2  sc1  add	\  "
                  tos 2  tos  sub       \ Decrement count
               then

				\ Longword Copy Loop (low-to-high)
               tos 3    sc6  andn	\ Index w/ even multiples of 4
               scr sc6  scr  add	\ src = src+index
               scr   4  sc4  sub	\ Working src = src+index-4
               sc1 sc6  sc1  add	\ dst = dst+index
               sc1   4  sc5  sub	\ Working dst = dst+index-4
               %g0 sc6  sc6  subcc	\ Negate index
               begin
               < while
                  sc6 4     sc6  addcc	\ (delay) Increment index
                  sc4 sc6   sc2  ld	\ Load longword
               repeat
                  sc2   sc5 sc6  st	\ (delay) Store longword
               tos 3   tos   and	\ At end, adjust cnt for few remaining

            else 		\ Halfword Copy Loop (low-to-high)
               nop			\ (delay)
               tos 1  sc6  andn		\ Index w/ even multiples of 2
               scr sc6  scr  add	\ src = src+index
               scr   2  sc4  sub	\ Working src = src+index-2
               sc1 sc6  sc1  add	\ dst = dst+index
               sc1   2  sc5  sub	\ Working dst = dst+index-2
               %g0 sc6  sc6  subcc	\ Negate index
               begin
               < while
                  sc6 2     sc6  addcc	\ (delay) Increment index
                  sc4 sc6   sc2  lduh	\ Load halfword
               repeat
                  sc2   sc5 sc6  sth	\ (delay) Store halfword

               tos 1   tos   and	\ At end, adjust cnt for few remaining
            then
         then
      then	\ Now do a normal byte move for all remaining bytes (at top)

      \ Byte Copy Loop (low-to-high)
				\ (tos = index)
      scr tos  scr  add
      scr   1  sc4  sub		\ Working src = src+cnt-1
      sc1 tos  sc1  add
      sc1   1  sc5  sub		\ Working dst = dst+cnt-1
      %g0 tos  sc6  subcc	\ Negate index
      begin
      < while
         sc6 1     sc6  addcc	\ (delay) Increment cnt
         sc4 sc6   sc2  ldub	\ Load byte
      repeat
         sc2   sc5 sc6  stb	\ (delay) Store byte

   else  		\ Copy high-to-low case
      nop			\ (delay)
      tos h# 10   %g0  subcc	\ Enough bytes to bother optimizing?
      >= if			\ Otherwise, just skip to byte move
         sc3 1    %g0  andcc	\ (delay) =0 if at least shortword aligned
         0= if			\ Otherwise, just skip to byte move

            scr tos  sc4  add		\ (delay) Calculate last+1 address

            sc4 1    %g0  andcc		\ Not on halfword boundary? (at top)
            0<> if		\ Ensure halfword alignment (at top)
               sc4 -1   sc2  ldub	\ (delay) Load top byte
               tos 1    tos  sub	\ Decrement count
               sc2  sc1 tos  stb	\ Store byte
               sc4 1    sc4  sub	\ Recalculate last+1 address
            then

            sc3 2   %g0  andcc		\ =0 if at least longword aligned
            0= if		\ Otherwise, skip to halfword case

               sc4 2    %g0  andcc	\ (delay) Not on longword boundary? (at top)
               0<> if		\ Ensure longword alignment (at top)
                  sc4 -2   sc2  lduh	\ (delay) Load top halfword
                  tos 2    tos  sub	\ Decrement count
                  sc2  sc1 tos  sth	\ Store halfword
                  sc4 2    sc4  sub	\ Recalculate last+1 address
               then

				\ Longword Copy Loop (high-to-low)
               scr 4   sc4   add	\ Working src = src+4
               sc1 4   sc5   add	\ Working dst = dst+4
               tos 4   sc6   subcc	\ Loop index = cnt-4
               begin
               >= while
                  sc6 4     sc6  subcc	\ (delay) Decrement index
                  sc4 sc6   sc2  ld	\ Load longword
               repeat
                  sc2   sc5 sc6  st	\ (delay) Store longword

               tos 3   tos   and	\ At end, adjust cnt for few remaining

            else		\ Halfword Copy Loop (high-to-low)
               nop			\ (delay)
               scr 2   sc4   add	\ Working src = src+2
               sc1 2   sc5   add	\ Working dst = dst+2
               tos 2   sc6   subcc	\ Loop index = cnt-2
               begin
               >= while
                  sc6 2     sc6  subcc	\ (delay) Decrement index
                  sc4 sc6   sc2  lduh	\ Load halfword
               repeat
                  sc2   sc5 sc6  sth	\ (delay) Store halfword

               tos 1   tos   and	\ At end, adjust cnt for few remaining
            then
         then
      then	\ Now do a normal byte move for all remaining bytes (at bottom)

      \ Byte Copy Loop (high-to-low)
      scr 1     sc4  add	\ Working src = src+1
      sc1 1     sc5  add	\ Working dst = dst+1
      tos 1     tos  subcc	\ Loop index = cnt-1
      begin
      >= while
         tos 1     tos  subcc	\ (delay) Decrement index
         sc4 tos   sc2  ldub	\ Load byte
      repeat
         sc2   sc5 tos  stb	\ (delay) Store byte
   then

   sp 2 /n*  tos   nget	\ Delete 3 stack items
   sp 3 /n*  sp    add	\   "
c;
defer move
' (move) is move
