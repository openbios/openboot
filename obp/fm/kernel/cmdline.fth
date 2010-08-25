\ cmdline.fth 1.4 02/05/02
\ Copyright 1993-1994 Bradley Forthware, Inc.  All Rights Reserved.
\ Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ Get the arguments passed from the program

\ Returns the command line argument indexed by arg#, as a string.
\ In most systems, the 0'th argument is the name of the program file.
\ If the arg#'th argument doesn't exist, returns 0.
: >arg  ( arg# -- false | arg-adr arg-len true )
   dup #args >=  if  ( arg# )
      drop false
   else              ( arg# )
      args swap na+ @  cscount true
   then
;

variable arg#

\ Get the next argument from the command line.
\ Returns 0 when there are no more arguments.
\ arg# should be set to 1 before the first call.
\ argument number 0 is usually the name of the program file.
: next-arg  ( -- false  | arg-adr arg-len true )
   arg# @  >arg  dup  if  1 arg# +!  then
;
defer cmdline-file	' 2drop is cmdline-file


: bootstrap-file ( str,len -- )
   ?dup if
      d# 46 d# 45 fsyscall	( )		\ grab whole file
      2>r 2r@ evaluate		( )
      2r> sys-free-mem		( )
   else				( adr )
      drop			( )
   then				( )
;
\ ' bootstrap-file  is  cmdline-file		\ No bootstrap yet!

: process-argument  ( adr len -- )
   2dup  " -s"  $=  if       ( adr len )
      2drop next-arg  0= ( ?? ) abort" Missing argument after '-s'"
      evaluate               ( ?? )
   else                      ( adr len )
   2dup  " -b" $=  if	     ( adr len )
      2drop next-arg 0= abort" Missing argument after '-b'"
      bootstrap-file	     ( )
   else
   2dup  " -x" $=  if	     ( adr len )
      2drop \ prepare-xref     ( )
   else
   2dup  " -"  $=  if        ( adr len )      
      2drop
      interact
   else                      ( adr len )
      cmdline-file 
   then then then then
;

: process-command-line  ( -- )
   #args  1 <=  if  exit  then
   1 arg# !
   begin  next-arg  while  ( adr len )
      ['] process-argument  catch  ?dup  if  .error  bye  then
   repeat
   bye
;
