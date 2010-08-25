\ fcmdcpl.fth 2.5 95/04/19
\ Copyright 1985-1990 Bradley Forthware

\ Command completion interface for the Forth line editor

only forth also hidden also command-completion definitions

headerless
: install-fcmd
   ['] end-of-word               is find-end
   ['] insert-character          is cinsert
   ['] erase-previous-character  is cerase
;
install-fcmd

only forth also command-completion also keys-forth definitions

headers
: ^` expand-word ;	\ Control-space or control-back-tick
: ^| expand-word ;	\ Control-vertical-bar or control-backslash
: ^} do-show ;		\ Control-right-bracket
: ^? do-show ;		\ Control-question-mark
h# 7f last @ name>string drop 1+ c!   	\ Hack hack

only forth also definitions

