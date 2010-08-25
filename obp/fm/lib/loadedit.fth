\ loadedit.fth 2.10 94/10/30
\ Copyright 1985-1994 Bradley Forthware

\ Load file for command line editor.

start-module
fload ${BP}/fm/lib/fileed.fth
fload ${BP}/fm/lib/editcmd.fth	\ I emacs-edit
fload ${BP}/fm/lib/unixedit.fth
fload ${BP}/fm/lib/cmdcpl.fth
fload ${BP}/fm/lib/fcmdcpl.fth
end-module
