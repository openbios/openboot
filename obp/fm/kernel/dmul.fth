\ dmul.fth 1.1 95/03/04
\ Copyright 1994 FirmWorks

\ AB * CD = BD + (BC + DA)<<bits/half-cell + AC<<bits/cell
: half*  ( h1 h2 -- low<< high )  * split-halves  swap scale-up swap  ;
: um*  ( n1 n2 -- xlo xhi )
   split-halves   rot split-halves   ( b a d c )

   \ Easy case - high halves are both 0, so result is just BD
   2 pick over or  0=  if  drop nip * 0  exit  then

   3 pick 2 pick  * 0 2>r            ( b a d c )  ( r: d.low )

   \ Check for C = 0 and optimize if so
   dup  if			     ( b a d c )  ( r: d.low )
      \ C is not zero, so compute and add BC<<
      3 pick  over half*
      2r> d+ 2>r                     ( b a d c )  ( r: d.intermed )

      \ We are done with B
      2swap nip                      ( d c a )
      \ Check for A = 0 and optimize if so
      dup  if                        ( d c a )
         \ A is not zero, so compute and add DA<< and AC<<<
         rot over half*              ( c a da.low da.high )
         2r> d+ 2>r                  ( c a ) ( r: d.intermed' )
         * 0 swap 2r> d+
      else
         \ A is zero, so we are finished
         3drop  2r>
      then
   else
      \ C is zero, so all we have to do is compute and add DA<<
      drop rot drop                  ( a d )  ( r: d.low )
      half*                          ( low1 high1 )
      2r> d+
   then
;
