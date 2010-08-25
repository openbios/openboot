\ lmove.fth 2.4 94/05/30
\ Copyright 1985-1990 Bradley Forthware

code lmove  (s from-addr to-addr cnt -- )
   sp 1 /n*  scr   nget       \ Src into scr
   sp 0 /n*  sc1   nget       \ Dst into sc1

   scr tos  scr  add    \ Src = src+cnt (optimize for low-to-high copy)
   sc1 tos  sc1  add    \ Dst = dst+cnt
   sc1 4    sc1  sub    \ Account for the position of the addcc instruction
   %g0 tos  tos  subcc  \ Negate cnt

   <> if
      nop
      begin
         scr tos   sc2  ld         \ (delay) Load byte
         tos 4     tos  addcc      \ (delay) Increment cnt
      >= until
         sc2   sc1 tos  st         \ Store byte
   then   

   sp 2 /n*  tos    nget      \ Delete 3 stack items
   sp 3 /n*  sp     add     \   "
c;
code wmove  (s from-adr to-adr #bytes -- )
   sp 1 /n*   scr   nget       \ Src into scr
   sp 0 /n*   sc1   nget       \ Dst into sc1

   scr tos  scr  add    \ Src = src+cnt (optimize for low-to-high copy)
   sc1 tos  sc1  add    \ Dst = dst+cnt
   sc1 2    sc1  sub    \ Account for the position of the addcc instruction
   %g0 tos  tos  subcc  \ Negate cnt

   <> if
      nop
      begin
         scr tos   sc2  lduh       \ (delay) Load byte
         tos 2     tos  addcc      \ (delay) Increment cnt
      >= until
         sc2   sc1 tos  sth        \ Store byte
   then   

   sp 2 /n*  tos    nget    \ Delete 3 stack items
   sp 3 /n*  sp     add     \   "
c;
