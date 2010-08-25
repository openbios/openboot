\ cold.fth 2.6 94/09/11
\ Copyright 1985-1994 Bradley Forthware

\ Some hooks for multitasking
\ Main task points to the initial task.  This usage is currently not ROM-able
\ since the user area address has to be later stored in the parameter field
\ of main-task.  It could be made ROM-able by allocating the user area
\ at a fixed location and storing that address in main-task at compile time.

defer pause  \ for multitasking
' noop  is pause

defer init-io    ( -- )
defer do-init    ( -- )
defer cold-hook  ( -- )
defer init-environment  ( -- )

[ifndef] run-time
: (cold-hook  (s -- )
   [compile] [
;

' (cold-hook  is cold-hook
[then]

: cold  (s -- )
   decimal
   init-io			  \ Memory allocator and character I/O
   do-init			  \ Kernel
   ['] init-environment guarded	  \ Environmental dependencies
   ['] cold-hook        guarded	  \ Last-minute stuff

   process-command-line

   \ interactive? won't work because the fd hasn't been initialized yet
   (interactive?  if  title  then

   quit
;

[ifndef] run-time
headerless
: single  (s -- )  \ Turns off multitasking
   ['] noop ['] pause (is
;
headers
: warm   (s -- )  single  sp0 @ sp!  quit  ;
[then]
