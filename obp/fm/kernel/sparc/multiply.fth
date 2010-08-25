id: @(#)multiply.fth 2.6 94/06/18
purpose: 
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright 1985-1990 Bradley Forthware

decimal

\ --- 32*32->64 bit unsigned! multiply ----------------------------------
\            y  rs2     y  rd
code um*   ( u1 u2 -- ud[lo hi] )
   sp 0 /n*    %l0    nget             \ l0 <- n1(y)      get multiplyer 
					\   (save original y for later)
   %l0 %g0             wry              \ y  <- n1       multiplyer
					\
   tos %g0      %l3    or               \ l3 <- n2(rs2)  multiplicand
					\   (save original rs2 for later)
					\
   tos %l0      %l1    or               \ l2 <- n1.or.n2 (any hi bits)
   %l1 h# fff   %g0    andncc           \ cc <- fffff000.and.(n1.or.n2)
   0=  if                               \ if neither terms have any 
					\    hi 1's then set do short way.
   %g0 %g0      %l2    andcc            \ N=0, V=0, %l2=0; Neg, oVerflow, 
					\   part-product (delay slot)
					\
      %l2 tos      %l2    mulscc        \ 1   001
      %l2 tos      %l2    mulscc        \ 2   003
      %l2 tos      %l2    mulscc        \ 3   007
      %l2 tos      %l2    mulscc        \ 4   00f
      %l2 tos      %l2    mulscc        \ 5   01f
      %l2 tos      %l2    mulscc        \ 6   03f
      %l2 tos      %l2    mulscc        \ 7   07f
      %l2 tos      %l2    mulscc        \ 8   0ff
      %l2 tos      %l2    mulscc        \ 9   1ff
      %l2 tos      %l2    mulscc        \ 10  3ff
      %l2 tos      %l2    mulscc        \ 11  7ff
      %l2 tos      %l2    mulscc        \ 12  fff
      %l2 tos      %l2    mulscc        \ 13 1fff

      %g0 %g0      tos    and           \ x[hi]-(TOS) <- 0; (msd)
                   %l1    rdy           \ l1  <- y (write over saved y 
					\   [not needed for short multiply])
      %l2 d# 12    %l2    sll           \ l2  <- part-prod << 12; 
					\   msd result (low bits have 
					\   good data)
      %l1 d# 20    %l1    srl           \ l1  <- y         >> 20; 
					\   msd result (hi  bits have 
					\   good data)
					\
   else                                 \ else do full 32 bit multiply
      %l1 %l2      %l1    or            \ l1  <- mst+lsd 32 bit result (delay)

      %l2 tos      %l2    mulscc        \ 1
      %l2 tos      %l2    mulscc        \ 2
      %l2 tos      %l2    mulscc        \ 3
      %l2 tos      %l2    mulscc        \ 4
      %l2 tos      %l2    mulscc        \ 5
      %l2 tos      %l2    mulscc        \ 6
      %l2 tos      %l2    mulscc        \ 7
      %l2 tos      %l2    mulscc        \ 8
      %l2 tos      %l2    mulscc        \ 9
      %l2 tos      %l2    mulscc        \ 10
      %l2 tos      %l2    mulscc        \ 11
      %l2 tos      %l2    mulscc        \ 12
      %l2 tos      %l2    mulscc        \ 13
      %l2 tos      %l2    mulscc        \ 14
      %l2 tos      %l2    mulscc        \ 15
      %l2 tos      %l2    mulscc        \ 16
      %l2 tos      %l2    mulscc        \ 17
      %l2 tos      %l2    mulscc        \ 18
      %l2 tos      %l2    mulscc        \ 19
      %l2 tos      %l2    mulscc        \ 20
      %l2 tos      %l2    mulscc        \ 21
      %l2 tos      %l2    mulscc        \ 22
      %l2 tos      %l2    mulscc        \ 23
      %l2 tos      %l2    mulscc        \ 24
      %l2 tos      %l2    mulscc        \ 25
      %l2 tos      %l2    mulscc        \ 26
      %l2 tos      %l2    mulscc        \ 27
      %l2 tos      %l2    mulscc        \ 28
      %l2 tos      %l2    mulscc        \ 29
      %l2 tos      %l2    mulscc        \ 30
      %l2 tos      %l2    mulscc        \ 31
      %l2 tos      %l2    mulscc        \ 32
      %l2 %g0      tos    mulscc        \ final iteration only shifts; 
					\   move to TOS (delay slot).
					\
      %l3 %g0      %g0    orcc          \ was original rs2 negative
      0< if
      			  nop		\ (delay slot) can't put mulscc 
					\   here because N and V flags
					\   must not be changed.
					\
        %l0 tos     tos     add         \ if so add original y to 
					\   result to adjust for 
					\   signed multiply.
					\
      then
                   %l1    rdy           \ get lsd
   then
   %l1        sp 0 /n*  nput		\ x[lo]-(UTOS) <- lsd=l1 (delay slot)
c;

: *  ( n1 n2 -- n3 )  um* drop  ;
