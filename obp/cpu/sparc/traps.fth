\ traps.fth 2.6 94/05/04
\ Copyright 1985-1990 Bradley Forthware

hex

headers
code %i6!  ( n -- )  tos %i6 move  sp tos pop  c;
code %i7!  ( n -- )  tos %i7 move  sp tos pop  c;
code %o6!  ( n -- )  tos %o6 move  sp tos pop  c;
code %o6@  ( n -- )  tos sp push  %o6 tos move  c;
code tbr@  ( -- adr )  tos sp push  tos rdtbr  c;
code tbr!  ( adr -- )  tos 0  wrtbr  sp tos pop  c;
code psr@  ( -- n )  tos sp push  tos rdpsr  c;
code psr!  ( n -- )  tos 0  wrpsr  sp tos pop  c;
code wim@  ( -- n )  tos sp push  tos rdwim  c;
code wim!  ( n -- )  tos 0  wrwim  sp tos pop  c;
code y@  ( -- n )  tos sp push  tos rdy  c;
code y!  ( n -- )  tos 0 wry  sp tos pop  c;
: cwp!  ( window# -- )  psr@  h# 1f invert and  or  psr!  ;
: cwp@  ( -- window# )  psr@  h# 1f and  ;
: pil@  ( -- priiority )  psr@  h# f00 and  8 >>  ;
: pil!  ( priority -- )  8 <<  psr@  h# f00 invert and  or  psr!  ;
alias spl pil!  ( priority -- )
headerless

: traps-on   ( -- )  psr@ h# 20 or         psr!  ;
: traps-off  ( -- )  psr@ h# 20 invert and psr!  ;

: setl4  ( n -- setlow sethi )
   dup 0a >> ( n hibits ) h# 29000000 +  ( n sethi )
   swap h# 3ff and h# a8052000 +  swap
;

h# 10 constant /vector
: vector-adr  ( vector# -- adr )  /vector *  tbr@ h# ffff.f000 and  +  ;

defer vector-l! ( l adr -- )  ' l! is vector-l!
headers

: vector!  ( handler-adr trap# -- )
   vector-adr                        ( handler trap-entry-adr )
   swap setl4                        ( trap-entry-adr setlow sethi )
   2 pick vector-l!                  ( trap-entry-adr setlow )
   over la1+ vector-l!               ( trap-entry-adr )	\ handler %l4 set
   h# 81c52000 over 2 la+ vector-l!  ( trap-entry-adr )	\ %l4 0  %g0 jmpl
   h# a1480000 over 3 la+ vector-l!  ( trap-entry-adr )	\ %l0 rdpsr
   drop
;

\ Assumes handler was installed with vector!
: vector@  ( trap# -- handler-adr )
   vector-adr                    ( trap-adr )
   dup l@  h# 0a <<              ( trap-adr hibits )
   swap la1+ l@  h# 3ff and  or  ( handler-adr )
;
