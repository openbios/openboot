\ arcbpsup.fth 2.3 90/09/03
\ Copyright 1985-1990 Bradley Forthware

\ System-architecture-dependent definitions for breakpoints.
\ Version for running as a Unix user process.

: unix-breakpoint-trap?  ( -- flag )
   [ also hidden ]   exception l@  [ signals ]  SIGILL =   [ previous ]
;

code flush-instruction  ( adr -- )
   tos 0  iflush
   sp tos pop
c;
  
: unix-op!  ( op adr -- )  dup flush-instruction l!  ;

: install-unix-bp  ( -- )
   h# 0000.0000 is breakpoint-opcode		\ An illegal instruction
   ['] unix-breakpoint-trap? is breakpoint-trap?
   ['] l@ is op@  ['] unix-op! is op!
;
install-unix-bp

: unix-init  ( -- )  unix-init  install-unix-bp  ;
