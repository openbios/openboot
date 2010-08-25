\ call.fth 2.5 94/05/30
\ Copyright 1985-1990 Bradley Forthware

\ From Forth, call the C subroutine whose address is on the stack

code call  ( [ arg5 .. arg0 ] adr -- [ arg5 .. arg0 ] result )
   \ Pass up to 6 arguments
   sp 0 /n*   %o0   nget
   sp 1 /n*   %o1   nget
   sp 2 /n*   %o2   nget
   sp 3 /n*   %o3   nget
   sp 4 /n*   %o4   nget
   sp 5 /n*   %o5   nget

   do-ccall         call
   tos        %l0   move

   %o0    tos  move	\ Return subroutine result
c;
