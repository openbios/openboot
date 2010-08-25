\ savedstk.fth 2.2 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ Converts stack addresses to the address of the corresponding location
\ in the stack save areas.

decimal
only forth also hidden also forth definitions

headerless
: rssave-end  ( -- adr )  rssave rs-size +  ;
: pssave-end  ( -- adr )  pssave ps-size +  ;

: in-return-stack?  ( adr -- flag )  rp0 @ rs-size -  rp0 @   between  ;
: in-data-stack?  ( adr -- flag )  sp0 @ ps-size -  sp0 @   between  ;

headers
\ Given an address within the stack, translate it to the corresponding
\ address within the saved stack area.
: >saved  ( adr -- save-adr )
   dup  in-data-stack?               ( adr flag )
   if  sp0 @ -  pssave-end +  then   ( adr' )
   dup  in-return-stack?             ( adr flag )
   if  rp0 @ -  rssave-end +  then   ( adr'' )
;
