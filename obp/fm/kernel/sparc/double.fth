id: @(#)double.fth 1.3 04/02/02 10:01:53
purpose: 
copyright: Copyright 2003-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1985-1994 Bradley Forthware
copyright: Use is subject to license terms.

code (dlit) ( -- d )
   tos sp push
    \t16   ip 0 tos lduh
    \t16   tos d# 16 tos slln   ip 2 scr lduh   tos scr tos add
64\ \t16   tos d# 16 tos sllx   ip 4 scr lduh   tos scr tos add
64\ \t16   tos d# 16 tos sllx   ip 6 scr lduh   tos scr tos add
    \t32   ip tos lget
64\ \t32   tos d# 32 tos sllx   ip /l scr ld    tos scr tos add
   ip ainc
   tos sp push
    \t16   ip 0 tos lduh
    \t16   tos d# 16 tos slln   ip 2 scr lduh   tos scr tos add
64\ \t16   tos d# 16 tos sllx   ip 4 scr lduh   tos scr tos add
64\ \t16   tos d# 16 tos sllx   ip 6 scr lduh   tos scr tos add
    \t32   ip tos lget
64\ \t32   tos d# 32 tos sllx   ip /l scr ld    tos scr tos add
   ip ainc
c;

\ Double-precision arithmetic
code dnegate  ( d# -- d#' )
( 0 L: ) mloclabel dneg1
   sp 0      scr   nget
   %g0 scr   scr   subcc
   %g0 tos   tos   subx
   scr       sp 0  nput
c;

code dabs  ( dbl.lo dbl.hi -- dbl.lo' dbl.hi' )
   tos  %g0  %g0  subcc
   ( 0 B: ) dneg1 0< brif
   nop
c;

\ Words that need to be defined in high-level belong in  fm/kernel/double.fth
\  : dmax  ( d1 d2 -- d3 )  2over 2over  d-  nip 0<  if  2swap  then  2drop  ;

code d+  ( x1 x2 -- x3 )
   sp 0 /n*  sc1   nget		\ x2.low
   sp 2 /n*  sc3   nget		\ x1.low
   sp 1 /n*  sc2   nget		\ x1.high
   sp 2 /n*  sp    add		\ Pop args
   sc3 sc1  sc1    addcc	\ x3.low
32\   sc2 tos  tos    addx	\ x3.high
64\   sc2 tos  tos    add	\ x3.high
64\   u>=  if annul  tos  1  tos  add
64\   then
   sc1      sp 0   nput		\ Push result (x3.high already in tos)
c;
code d-  ( x1 x2 -- x3 )
   sp 0 /n*  sc1   nget		\ x2.low
   sp 2 /n*  sc3   nget		\ x1.low
   sp 1 /n*  sc2   nget		\ x1.high
   sp 2 /n*  sp    add		\ Pop args
   sc3 sc1  sc1    subcc	\ x3.low
32\   sc2 tos  tos    subx	\ x3.high
64\   sc2 tos  tos    sub	\ x3.high
64\   u>=  if annul  tos  1  tos  sub
64\   then
   sc1      sp 0   nput		\ Push result (x3.high already in tos)
c;
