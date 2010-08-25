\ hidden.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ This is a vocabulary that can be used to contain implementation words
\ that shouldn't appear in the forth dictionary.  It would nice to have
\ the option to compile such words headerless to save space, but that
\ feature will have to wait till later.  (Besides, headerless words make
\ the decompiler less useful).

only forth also definitions
vocabulary hidden

