id: @(#)rstrace.fth 2.5 04/03/30
copyright: 1985-1990 Bradley Forthware
copyright: 1991-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Forth stack backtrace
\ Implements:
\ (rstrace  ( low-adr high-adr -- )
\    Shows the calling sequence that is stored in memory between the
\    two addresses.  This is assumed to be a saved return stack image.
\ \ rstrace  ( -- )
\ \    Shows the calling sequence that is stored on the return stack,
\ \    without destroying the return stack.

decimal
only forth also hidden also definitions
headerless
: .last-executed  ( ip -- )
   ip>token token@  ( acf )
   dup reasonable-ip?  if   .name   else   drop ." ??"   then
;
: .traceline  ( ipaddr -- )
   push-hex
   dup reasonable-ip?
   if    dup .last-executed ip>token .caller   else  d# 17 u.r  then   cr
   pop-base
;
: (rstrace  ( bottom-adr top-adr -- )
   do   i @  .traceline  exit? ?leave  /n +loop
;
headers
forth definitions
\ : rstrace  ( -- )  \ Return stack backtrace
\    rp@ rp0 @ u>  if
\       ." Return Stack Underflow" rp0 @ rp!
\    else
\       rp0 @ rp@ (rstrace
\    then
\ ;
only forth also definitions
