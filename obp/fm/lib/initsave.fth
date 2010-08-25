\ initsave.fth 1.1 94/09/01
\ Copyright 1985-1990 FirmWorks  All rights reserved

: $find-name  ( name -- acf )
   $find  0= if  ." Can't find " type  cr  abort  then
;
: init-save  ( 'init-environment -- )
                 $find-name is init-environment
   " init"       $find-name is do-init
   " (cold-hook" $find-name is cold-hook

   here fence a!			\ Protect the dictionary
;
