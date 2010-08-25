\ debug.fth 1.15 95/04/19
\ Copyright 1985-1990 Bradley Forthware

\ Debugger.  Thanks, Mike Perry, Henry Laxen, Mark Smeder.
\
\ The debugger lets you single step the execution of a high level
\ definition.  To invoke the debugger, type debug xxx where xxx is
\ the name of the word you wish to trace.  When xxx executes, you will
\ get a single step trace showing you the word within xxx that
\ is about to execute, and the contents of the parameter stack.
\ Debugging makes everything run slightly slower, even outside
\ the word being debugged.  see debug-off
\
\ debug name	Mark that word for debugging
\ stepping	Debug in single step mode
\ tracing	Debug in trace mode
\ debug-off	Turn off the debugger (makes the system run fast again)
\ resume	Exit from a pushed interpreter (see the f keystroke)
\
\ Keystroke commands while you're single-stepping:
\   d		go down a level
\   u		go up a level
\   c		continue; trace without single stepping
\   g		go; turn off stepping and continue execution
\   f		push a Forth interpreter;  execute "resume" to get back
\   q		abort back to the top level

only forth also definitions

hex
headerless
variable slow-next?  slow-next? off

only forth hidden also forth also definitions
bug also definitions
variable step? step? on
variable res
headers
: (debug)       (s low-adr hi-adr -- )  recursive
   \ Refuse to debug the kernel; it's too dangerous
   over  low-dictionary-adr  ['] (debug)  between
   abort" The source debugger cannot debug the Forth kernel."

   unbug   1 cnt !   ip> !   <ip !   pnext
   slow-next? @ 0=  if
      here  low-dictionary-adr  slow-next
      slow-next? on
   then
   step? on
;
headerless
: 'unnest   (s pfa -- pfa' )
   begin   dup ta1+  swap  token@ ['] unnest =  until
;

false value first-time?
headers
\ Enter and leave the debugger
forth definitions
: (debug  ( acf -- )
   dup colon-cf?  0= abort" Not a colon definition"
   >body dup 'unnest  (debug)  true is first-time?
;
bug definitions
headerless
\ Go up the return stack until we find the return address left by our caller
: caller-ip  ( -- ip )
   rp@  begin
      na1+ dup @  dup  in-dictionary?  if    ( rs-adr ip )
         ip>token token@  <ip @ body> =
      else
         drop false
      then
   until                                     ( rs-adr )
   @ ip>token
;
: up1  ( ip -- )
   caller-ip
   dup find-cfa   ( ip cfa )
   cr ." [ Up to " dup .name ." ]" cr  ( ip cfa )
   over token@ .name                   ( ip cfa )
   >body swap 'unnest (debug)
;
defer to-debug-window  ' noop is to-debug-window
defer restore-window   ' noop is restore-window
: .debug-short-help  ( -- )
   ." Stepper keys: <space> Down Up Continue Forth Go Help ? See $tring Quit" cr
;
: .debug-long-help  ( -- )
   ." Key     Action" cr
   ." <space> Execute displayed word" cr
   ." D       Down: Step down into displayed word" cr
   ." U       Up: Finish current definition and step in its caller" cr
   ." C       Continue: trace current definition without stopping" cr
   ." F       Forth: enter a subordinate Forth interpreter" cr
   ." G       Go: resume normal exection (stop debugging)" cr
   ." H       Help: display this message" cr
   ." ?       Display short list of debug commands" cr
   ." S       See: Decompile definition being debugged" cr
   ." $       Display top of stack as adr,len text string" cr
   ." Q       Quit: abandon execution of the debugged word" cr
;
d# 24 constant cmd-column
0 value rp-mark
: to-cmd-column  ( -- )  cmd-column to-column  ;
: (trace  ( -- )
   first-time?  if
      ??cr  ." : " <ip @ body> .name
      false is first-time?
      rp@ is rp-mark
   then
   begin
      step? @  if  to-debug-window  then
      cmd-column 2+ to-column  ." ( " .s ." )" cr   \ Show stack

      ['] noop is indent
      ip@ .token drop		  \ Show word name
      ['] (indent) is indent
      to-cmd-column

      step? @  key? or  if
         step? on  res off
         key dup bl <  if  drop bl  then  dup emit  upc
         restore-window
         case
            ascii D  of  ip@ token@
	                 ['] (debug catch  if  drop false  else  cr true  then
	                                                     endof \ Down
	    ascii U  of  up1                          true   endof \ Up
            ascii C  of  step? @ 0= step? !           true   endof \ Continue
            ascii F  of
               cr ." Type 'resume' to return to debugger" cr
               interact                               false
            endof						   \ Forth
            ascii G  of  <ip off  ip> off  cr         true   endof \ Go
            ascii H  of  cr .debug-long-help          false  endof \ Help
            ascii S  of  cr <ip @ body> (see)         false  endof \ Help
            ascii ?  of  cr .debug-short-help	      false  endof \ Help
            ascii $  of  space 2dup type cr to-cmd-column false endof \ String
            ascii Q  of  cr ." unbug" abort           true   endof \ Quit
            ( default )  true swap
         endcase
      else
         true
      then
   until
   ip@ token@  dup ['] unnest =  swap ['] exit =  or  if
      cr  true is first-time?
   then
   pnext
;
' (trace  'debug token!

headers

only forth bug also forth definitions

: debug  \ name (s -- )
   .debug-short-help
   ' (debug
;
: resume    (s -- )  true is exit-interact?  pnext  ;
: stepping  (s -- )  step? on  ;
: tracing   (s -- )  step? off ;
: debug-off (s -- )
   unbug here  low-dictionary-adr  fast-next slow-next? off
;

only forth also definitions
