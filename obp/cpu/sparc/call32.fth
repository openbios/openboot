\ call32.fth 1.2 95/04/19
\ Copyright 1985-1990 Bradley Forthware

\ From Forth, call the C subroutine whose address is on the stack

code call32  ( [ arg5 .. arg0 ] adr -- [ arg5 .. arg0 ] result )
   %o6 /entry-frame %o6   save
   %o6 V9_SP_BIAS   %o6   add
   %o0                    rdpstate
   %o0    h# 10     %o0   or
   %o0    0               wrpstate

   sp 0 /n*         %o0   nget
   sp 1 /n*         %o1   nget
   sp 2 /n*         %o2   nget
   sp 3 /n*         %o3   nget
   sp 4 /n*         %o4   nget
   sp 5 /n*         %o5   nget

   do-ccall               call
   tos              %l0   move

   %o0  0           tos   srl
   %o0                    rdpstate
   %o0  h# 10       %o0   andn
   %o0  0                 wrpstate
   %o6  V9_SP_BIAS  %o6   sub
   %g0  %g0         %g0   restore
   nop
c;
