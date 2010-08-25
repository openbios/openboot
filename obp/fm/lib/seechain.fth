\ seechain.fth 2.7 95/04/19
\ Copyright 1985-1990 Bradley Forthware

\ Recursively decompile initialization chains.
\
\ (see-chain)   ( acf -- )
\ see-chain  \ name  ( -- )

only forth also hidden also forth definitions
headers
: (see-chain)  ( acf -- )
   dup definer ['] defer =  if  behavior  then  ( acf )
   begin                                        ( acf )
      dup  definer  ['] :  =  exit? 0=  and     ( acf cont? )
   while                                        ( acf )
       dup .x dup (see) >body                   ( apf )
       dup token@ dup ['] (") =  if             ( apf acf' )
          drop ta1+ +str token@                 ( acf" )
       else                                     ( apf acf' )
          nip                                   ( acf' )
       then                                     ( acf"|acf' )
   repeat                                       ( acf"|acf' )
   drop                                         (  )
;
: see-chain  \ name  ( -- )
   '  ['] (see-chain)  catch  if  drop  then
;

only forth also definitions
