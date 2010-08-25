\ stubs.fth 2.7 01/05/18
\ Copyright 1985-1990 Bradley Forthware
\ Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

\ stubs.fth -- stubby words until source straightens out

: dispose ;
: start-module ;  : end-module ;
: light ; immediate
: dark  ; immediate
: headerless0 ;

resident
: headers ;
: headerless ;
: external ;
