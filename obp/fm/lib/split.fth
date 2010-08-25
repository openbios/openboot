id: @(#)split.fth 2.3 95/04/19
purpose: 
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved
\ Copyright 1985-1990 Bradley Forthware

headers
: lbsplit ( l -- b.lo b.1 b.2 b.hi )  lwsplit >r wbsplit r> wbsplit  ;
: bljoin  ( b.lo b.1 b.2 b.hi -- l )  bwjoin  >r bwjoin  r> wljoin   ;

64\ : xwsplit ( x -- w.lo w.2 w.3 w.hi )  xlsplit >r lwsplit r> lwsplit  ;
64\ : wxjoin  ( w.lo w.2 w.3 w.hi -- x )  wljoin  >r wljoin  r> lxjoin   ;

64\ : xbsplit ( x -- b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi )
64\    xlsplit >r lbsplit r> lbsplit
64\ ;
64\ : bxjoin ( b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi -- x )
64\    bljoin  >r bljoin  r> lxjoin
64\ ;
