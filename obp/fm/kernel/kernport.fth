\  @(#)kernport.fth 2.9 03/07/17
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1993-1994 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright 2003 Sun Microsystems, Inc.  All Rights Reserved
\ Use is subject to license terms.

\ Some 32-bit compatibility words

\ These are for links that are just the same as addresses
/a constant /link
: link@  (s addr -- link )  a@  ;
: link!  (s link addr -- )  a!  ;
: link,  (s link -- )       a,  ;

headers

[ifndef] run-time

\itc : \itc ; immediate
\itc : \dtc  [compile] \ ; immediate
\itc : \ttc  [compile] \ ; immediate
\dtc : \itc  [compile] \ ; immediate
\dtc : \dtc ; immediate
\dtc : \ttc  [compile] \ ; immediate
\ttc : \itc  [compile] \ ; immediate
\ttc : \dtc  [compile] \ ; immediate
\ttc : \ttc ; immediate
\t8  : \t8  ; immediate
\t8  : \t16  [compile] \ ; immediate
\t8  : \t32  [compile] \ ; immediate
\t16 : \t8   [compile] \ ; immediate
\t16 : \t16 ; immediate
\t16 : \t32  [compile] \ ; immediate
\t32 : \t8   [compile] \ ; immediate
\t32 : \t16  [compile] \ ; immediate
\t32 : \t32 ; immediate
16\ : 16\  ; immediate
16\ : 32\  [compile] \  ; immediate
16\ : 64\  [compile] \  ; immediate
32\ : 16\  [compile] \  ; immediate
32\ : 32\  ; immediate
32\ : 64\  [compile] \  ; immediate
64\ : 16\  [compile] \  ; immediate
64\ : 32\  [compile] \  ; immediate
64\ : 64\  ; immediate
[then]
