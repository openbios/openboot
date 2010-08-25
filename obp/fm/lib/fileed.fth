\ fileed.fth 2.7 99/05/04
\ Copyright 1985-1994 Bradley Forthware

\ Command line editing.  See "install-line-editing" for functions
\ implemented and key bindings

only forth also hidden also
hidden definitions

decimal

headerless

\ Variables and values describing the state of the edit

0 value buf-start-adr   \ address of start of input buffer
nuser buflen            \ current size of input buffer
0 value bufmax          \ maximum size of input buffer

0 value line-start-adr  \ address of start of input buffer
nuser linelen           \ current size of input line

0 value #before         \ position of cursor within line

nuser line#

true value display?     \ Turns display update on or off
false value accepting?	\ Turns line number display on or off
false value deny-history? \ Turns off history access for security

\ Positonal information derived from the basic information

: #after        ( -- n )        linelen @ #before -  ;
: cursor-adr    ( -- adr )      line-start-adr  #before  +  ;
: after         ( -- adr len )  cursor-adr #after  ;
: buf-extent    ( -- adr len )  buf-start-adr  buflen @  ;
: buf#after     ( -- n )        buf-extent +  cursor-adr -  ;
: line-end-adr  ( -- adr )      after +  ;

: on-command-line?  ( -- flag )  \ True when cursor is on the last line
   accepting?  buf-extent +  line-end-adr =  and
;

: beep  ( -- )  display?  if  control G (emit  then  ;

\ Move backward n positions
: -chars  ( n -- )  0  ?do  display?  if  bs (emit  -1 #out +!  then  loop  ;

\ Move forward n positions (retyping the characters as we move over them)
: +chars  ( n -- )  display?  if  cursor-adr swap type  else  drop  then  ;

: .spaces  ( n -- )  display?  if  spaces  else  drop  then  ;

\ Redisplay the remainder of the line, clearing out "#deleted" spaces
\ at then end.  This is used after having deleted "#deleted" characters
\ at the cursor position.
: .trailing  ( #deleted -- )
   #after +chars  dup .spaces  -chars  #after -chars
;

\ Move forward "#chars" positions, but stop at the end of the line.
: forward-characters  ( #chars -- )
   #after min  dup +chars  #before +  is #before
;

\ Move backward "#chars" positions, but stop at the beginning of the line.
: backward-characters  ( #chars -- )
   #before min  dup -chars  #before swap -  is #before
;

81 buffer: kill-buffer

\ Deletes "#chars" characters after the cursor.  This affects the characters
\ in the buffer, but does not update the screen display.  It will delete
\ newline characters the same as any others.

: (erase-characters)  ( #chars -- )
   >r
   r@ 1 >  if  cursor-adr r@  kill-buffer  place  then
   cursor-adr  dup r@ +  swap  buf#after r@ -  cmove  \ Remove from buffer
   r> negate buflen +!
;

\ Inserts characters from "adr len" into the buffer, up to the amount
\ of space remaining in the buffer.  #inserted is the number that
\ were actually inserted.  Does not update the display.

: (insert-characters)  ( adr len -- #inserted )
   dup buflen @ +  bufmax  <=  if      ( adr len )
      dup buflen +!   dup linelen +!   ( adr len )
      cursor-adr   2dup +              ( adr len  src-addr dst-addr )
      buf#after 3 pick -  cmove>       ( adr len  )
      tuck cursor-adr  swap cmove      ( len=#inserted )
   else
      2drop 0                          ( 0 )
   then
;

\ Finds the line length.  Used after moving to a new line.  Internal.

: update-linelen  ( -- )
   buf#after  0  ?do
      cursor-adr  i ca+ c@  newline =  ?leave
      1 linelen +!
   loop
;
: set-linelen  ( -- )  0 linelen !  update-linelen  ;

: (to-command-line)  ( -- )
   0 is #before
   begin
      line# @ 0<
   while
      line-end-adr  1+  is line-start-adr
      set-linelen
      1 line# +!
   repeat
;

: ?copyline  ( -- )
   line# @  0<  if
      #before  line-start-adr  linelen @             ( cursor adr len )
      (to-command-line)                              ( cursor adr len )
      #after  if
         #after (erase-characters)
         0 linelen !
      then                                           ( cursor adr len )
      (insert-characters) drop                       ( cursor )
      is #before
   then
;

\ Erases characters within a line and redisplays the rest of the line.
\ "#chars" must not be more than "#after"

: erase-characters  ( #chars -- )
   ?copyline  dup (erase-characters)  dup negate linelen +!  .trailing
;

\ Inserts characters from "adr len" into the buffer, and redisplays
\ the rest of the line.

: insert-characters  ( adr len -- )
   ?copyline
   (insert-characters)  ( #inserted )  forward-characters  0 .trailing
;

nuser ch	\ One-element array used to convert character to "adr len"
: insert-character  ( char -- )  ch c!  ch 1 insert-characters  ;

: forward-character  ( -- )  1 forward-characters  ;

: backward-character  ( -- )  1 backward-characters  ;

: erase-next-character  ( -- )  #after 1 min  erase-characters  ;

: erase-previous-character  ( -- )
   #before 1 min  dup backward-characters  erase-characters
;

: beginning-of-line  ( -- )  #before backward-characters  ;

: end-of-line  ( -- )  #after forward-characters  ;

: beginning-of-file  ( -- )
   0 line# !
   buf-start-adr is line-start-adr
   0 is #before
   set-linelen
;

\ EMACS-style "kill-line".  If executed in the middle of a line, kills
\ the rest of the line.  If executed at the end of a line, kills the
\ "newline", thus joining the next line to the end of the current one.

: kill-to-end-of-line  ( -- )
   #after  ?dup  if
      erase-characters				\ Kill rest of line
   else
      accepting? 0=  if
         buf#after 1 min  (erase-characters)	\ Join lines
         update-linelen  0 .trailing
      then
   then
;

\ Displays a line number.
: .num  ( n -- )
   accepting?  display? 0=  or  if
      drop
   else
      push-decimal
      (cr  4 u.r  ." : "
      pop-base
   then
;

\ Displays the current line number.
: .line#  ( -- )  line# @  .num  ;

\ Redisplays the current line
: retype-line  ( -- )
   cr  .line#  line-start-adr  #before  type  0 .trailing
;

\ Locates the beginning of the previous (blank-delimited) word.
\ Doesn't move the cursor or change the display.  Internal.

: find-previous-word  ( -- adr )
   line-start-adr  dup cursor-adr 1-  ?do   ( linestart )
      i c@  bl <>  if  drop i leave  then
   -1 +loop
   ( nonblank-adr )
   line-start-adr  dup  rot  ?do   ( linestart )
      i c@  bl =  if  drop i 1+  leave  then
   -1 +loop
;

\ Locates the beginning of the next (blank-delimited) word.
\ Doesn't move the cursor or change the display.  Internal.

: find-next-word  ( -- adr )
   line-end-adr  dup  cursor-adr  ?do  ( bufend-adr )
      i c@  bl =  if  drop i leave  then
   loop
   line-end-adr  dup  rot  ?do  ( bufend-adr )
      i c@  bl <>  if  drop i leave  then
   loop
;

\ Displays a line in-place, erasing any characters left over from the
\ line that was previously displayed there.  Leaves the cursor at
\ the end of the line.  Internal.

: display-line  ( previous-length -- )
   0 is #before                 \ Cursor to beginning of line  ( prev-len )

   \ Find the end of the line
   set-linelen                                                 ( prev-len )

   \ Display the line
   display?  if                                                ( prev-len )
      .line#                                                   ( prev-len )
      after type                                               ( prev-len )
      linelen @  -  0 max  dup .spaces  -chars                 ( )
   else                                                        ( prev-len )
      drop                                                     ( )
   then

   linelen @  is #before	\ Leave cursor at the end of the line
;

: last-line?  ( -- flag )  line-end-adr  buf-extent +  >=  ;

\ Goes to the next line, if there is one, and scrolls the display.
: next-line  ( -- )
   accepting? deny-history?  and  if  exit  then
   last-line? 0=  if
      beginning-of-line   #after   ( previous-length )
      line-end-adr  1+  is line-start-adr
      1 line# +!
      \ Scroll if editing a file
      accepting? 0=  display? and  if  drop cr 0  then
      display-line
   then
;

\ Goes to the previous line, displaying it "in-place" on the same screen line.
: previous-line  ( -- )
   accepting? deny-history?  and  if  exit  then
   buf-start-adr  line-start-adr  <  if
      beginning-of-line   #after   ( previous-length )
      buf-start-adr  line-start-adr 1-  2dup  =  if
         is line-start-adr  drop
      else
         do
            i is line-start-adr
            i -1 ca+ c@  newline =  ?leave
         -1 +loop
      then
      -1 line# +!
      display-line
   then
;

\ : forward-lines  ( #lines -- )   0  ?do  next-line  loop  ;
\ : backward-lines  ( #lines -- )   0  ?do  previous-line  loop  ;


\ This is used by the command completion package; it ought to be elsewhere,
\ and it also should find the end of the word without going there.
: end-of-word  ( -- )
   after bounds  ?do
      i c@  bl =  ?leave  forward-character
   loop
;
: forward-word  ( -- )  find-next-word cursor-adr -  forward-characters  ;
: backward-word  ( -- )
   cursor-adr find-previous-word -  backward-characters
;
: erase-next-word  ( -- )  find-next-word cursor-adr -  erase-characters  ;
: erase-previous-word  ( -- )
   cursor-adr  backward-word  cursor-adr -  erase-characters
;
: quote-next-character  ( -- )  key insert-character  ;
: split-line  ( -- )
   accepting? 0=  if
      newline ch c!  ch 1 (insert-characters)  if
         #after                ( previous-#after )
         #before linelen !     ( previous-#after )
         .trailing             \ Erase the rest of the line
      then
   else
      beep
   then
;
: new-line  ( -- )  split-line  next-line  ;
: list-file  ( -- )
   accepting? deny-history? and  if  exit  then
   cr
   0  dup .num
   buf-extent  bounds  ?do
      i c@  dup  newline =  if
          drop cr  exit? ?leave  1+ dup .num
      else
          emit
      then
   loop
   drop
   retype-line
;
: yank  ( -- )  kill-buffer count insert-characters  ;

headers
