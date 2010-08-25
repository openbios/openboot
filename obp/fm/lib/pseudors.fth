id: @(#)pseudors.fth 1.4 03/12/08 13:22:25
purpose: 
copyright: Copyright 1995-2001 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1994 FirmWorks  All Rights Reserved
copyright: Use is subject to license terms.

headerless
d# 64  circular-stack: pseudo-rs
: >pr  ( n -- ) pseudo-rs push ;
: pr>  ( -- n ) pseudo-rs pop  ;
: pr@  ( -- n ) pseudo-rs top@ ;
: 2>pr ( m n -- )  swap  >pr >pr ;
: 2pr> ( -- m n ) pr>  pr>  swap ;
: 2pr@ ( -- m n ) pr>  pr@  swap dup >pr ;
headers
: >r  ( n -- )
   state @  if  compile >r  else  >pr  then
; immediate
: r>  ( -- n )
   state @  if  compile r>  else  pr>  then
; immediate
: r@  ( -- n )
   state @  if  compile r@  else  pr@  then
; immediate
: 2>r  ( m n -- )
   state @  if  compile 2>r  else  2>pr  then
; immediate
: 2r>  ( -- m n )
   state @  if  compile 2r>  else  2pr>  then
; immediate
: 2r@  ( -- m n )
   state @  if  compile 2r@  else  2pr@  then
; immediate

