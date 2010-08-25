\ @(#)conf64.fth 1.3 01/05/18
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

only forth also definitions

warning @  warning off
: 16\ [compile] \ ; immediate
: 32\ [compile] \ ; immediate
: 64\ ; immediate
warning !

: \itc-t ( -- ) [compile] \  ; immediate
: \dtc-t ( -- )              ; immediate
: \ttc-t ( -- ) [compile] \  ; immediate
: \t8-t  ( -- ) [compile] \  ; immediate
: \t16-t ( -- ) [compile] \  ; immediate
: \t32-t ( -- )              ; immediate
