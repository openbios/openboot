\ guarded.fth 1.1 02/05/02
\ Copyright 1985-1994 Bradley Forthware
\ Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright Use is subject to license terms.

\ A version that knows about multi-segment dictionaries can be installed
\ if such dictionaries exist.
: (in-dictionary?  ( adr -- )  origin here between  ;
headers
defer in-dictionary? ' (in-dictionary? is in-dictionary?

defer .error#
: .error  ( error# -- )
   dup  -13  =  if
      show-error
      drop abort-message type
      ."  ?"
   else
      dup  -2 =  if
	 show-error
	 drop abort-message type
      else
	 dup -1 =  if
	    drop
	 else
	    show-error
	    dup in-dictionary?  if  count type  else  .error#  then
	 then
      then
   then
   cr
;
: guarded  ( acf -- )  catch  ?dup  if  .error  then  ;
