\ unixedit.fth 2.4 95/08/30
\ Copyright 1985-1990 Bradley Forthware

\ To make the line editor handle ^U and ^W just like Unix normally does

only forth hidden also forth also keys-forth definitions

headers
: ^u beginning-of-line kill-to-end-of-line ;
: ^w erase-previous-word ;
: ^r retype-line ;
: del erase-previous-character ;
: ^c accepting?  if  ^u  then  ^x ;
only forth also definitions
