\ array.fth 2.3 90/09/03
\ Copyright 1985-1990 Bradley Forthware

forth definitions
headerless
: array  \ name  ( #elements -- )
\   create /n* allot   does>  swap na+	\ not ROMable
   /n* buffer:  does> do-buffer  swap na+    \ buffer: action plus  "swap na+"
;
headers
