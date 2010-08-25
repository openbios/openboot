\ editcmd.fth 2.16 02/05/02
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

headers
forth definitions
vocabulary keys-forth
defer skey  ' key is skey  \ Perhaps override with an ekey-based word later

hidden definitions

headerless
tuser keys  ' keys-forth keys token!

d# 32 buffer: name-buf

: add-char-to-string  ( str char -- )
   over ( str char str )
   count dup >r ( str char addr len )
   + c!  ( str )
   r> 1+ swap c!
;
: add-char-to-name  ( str char -- )
   dup bl u<  if    ( str char )  \ control character so translate to ^ form
      over ascii ^ add-char-to-string  ( str char )
      ascii a 1- +  ( str char' )  add-char-to-string
  else
      \ Map the Delete key to the string "del"
      dup d# 127 =  if   drop  " del" rot $cat  exit  then

      \ Map the Unicode Control Sequence Identifier to the string "ESC["
      dup h# 9b =  if   drop  " esc-[" rot $cat  exit  then

      \ Map the out-of-band character into the string "ext"
      dup -1 =   if   drop  " ext" rot $cat  exit  then

      add-char-to-string
  then
;
defer not-found

nuser lastchar		\ most-recently-typed character
: do-command  ( prefix-string -- )
   name-buf "copy
   name-buf lastchar @  add-char-to-name
   name-buf count  keys token@ search-wordlist  ( false | cfa true )
   if  execute  else  not-found  then
;

defer printable-char
nuser finished		\ is the line complete yet?

: start-edit  ( bufadr buflen bufmax line# position display? -- )
   is display?
   >r
   line# !
   is bufmax  buflen !  is buf-start-adr
   buf-start-adr r> +  is line-start-adr

   0 is #before
   set-linelen
;
: finish-edit  ( -- length )  buflen @  ;
: edit-command-loop  ( -- )
   finished off
   begin
      skey lastchar !
      lastchar @
      dup  bl     h# 7e  between
      swap h# a0  h# fe  between  or
      if  lastchar @ printable-char  else  nullstring  do-command  then
   finished @  until
   cr
;
headerless

: edit-buffer  (s bufadr buflen bufmax line# position -- newlen )
   true start-edit

   0 display-line

   edit-command-loop

   finish-edit
;
: edit-file  (s addr len maxlen -- newlen )  0 0 edit-buffer  ;

d# 512  /tib 2* max  value hbufmax
hbufmax buffer: hbuf-adr
0 value hbuflen
: ensure-line-end  ( -- )
   \ Put a newline at the end of the last line if necessary
   hbuflen  if
      hbuf-adr hbuflen +  1-  c@  newline  <> if
         newline  hbuf-adr hbuflen +  c!
	 hbuflen 1+  is hbuflen
      then
   then
;
: make-room  ( needed -- )
   1+  hbufmax  hbuflen -  -  ( shortfall )
   dup  0>  if                ( shortfall )   \ Too little room at the end
      dup hbuf-adr +  hbuf-adr  hbuflen 3 pick -  move  ( shortfall )
      hbuflen swap - is hbuflen
   else
      drop
   then
\      hbuf-adr over +  hbufmax  rot -    ( adr remaining )
\      hbufmax -rot  bounds  ?do          ( next-line-adr )
\         i c@  newline =  if
\	    drop i 1+  hbuf-adr - leave
\         then
\      loop                               ( shortfall next-line-adr )
\      dup hbuf-adr
   ensure-line-end
;
: open-history  ( needed -- buf len maxlen line# position )
   make-room   ( )
   hbuf-adr  hbuflen  hbufmax  0  hbuflen
;
: xaccept  (s adr len -- actual )
   (interactive? 0=  if  sys-accept exit  then
   tuck dup hbufmax 1-  >  if    ( len adr len )
      0 swap  0 0                ( len adr 0 len 0 0 )
   else                          ( adr len )
      open-history               ( len adr  hbuf hlen hmax line# position )
   then

   true is accepting?
   edit-buffer  is hbuflen       ( len adr )
   false is accepting?

   swap linelen @ min  tuck      ( len' adr len' )
   line-start-adr  -rot move     ( len' )
;
: new-line-or-done  ( -- )
   accepting?  if
      finished on
      line# @ -1 < if  ?copyline  then
   else
      new-line
   then
;

: self-insert  ( -- )  lastchar @ insert-character  ;

headers
keys-forth also definitions

: ^f  forward-character  ;
: ^b  backward-character  ;
: ^a  beginning-of-line  ;
\ : ^c  finished on  ;
: ^e  end-of-line  ;
: ^d  erase-next-character  ;
: ^h  erase-previous-character  ;
: ^i  bl insert-character  ;
: ^j  new-line-or-done  ;
: ^k  kill-to-end-of-line  ;
: ^l  list-file  ;
: ^m  new-line-or-done  ;
: ^n  next-line  ;
: ^o  split-line  ;
: ^p  previous-line  ;
: ^q  quote-next-character  ;
: ^x  finished on  ;		\ XXX for testing
: ^y  yank  ;
: esc-y  yank  ;		\ XXX for testing

: ^{  key lastchar !  [""] esc- do-command  ;
: esc-o  only forth also definitions  beep beep beep  ;
: esc-h  erase-previous-word  ;
: esc-d  erase-next-word  ;
: esc-f  forward-word  ;
: esc-b  backward-word  ;
: esc-^h  erase-previous-word  ;
: esc-^d  erase-next-word  ;
: esc-^f  forward-word  ;
: esc-^b  backward-word  ;
: esc-del  erase-next-word  ;

\ ANSI cursor keys
: esc-[  key lastchar !  [""] esc-[ do-command  ;
: esc-[A previous-line  ;
: esc-[B next-line  ;
: esc-[C forward-character  ;
: esc-[D backward-character  ;
: esc-[P erase-previous-character  ;

hidden definitions
headerless
: emacs-edit
   ['] beep             is  not-found
   ['] insert-character is  printable-char
   ['] xaccept          is  accept
;
emacs-edit

[ifexist] xref-find-hook
' keys-forth ' lose ' $find-word (patch
[then]
forth definitions
chain: init  ( -- )  emacs-edit  ;
headers
