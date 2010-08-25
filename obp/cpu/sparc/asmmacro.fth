id: @(#)asmmacro.fth 2.12 03/12/08 13:21:50
purpose: Assembly language macros related to the Forth implementation
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
\ Copyright 1985-1990 Bradley Forthware

\ These words are specific to the virtual machine implementation
: assembler  ( -- )  srassembler  ;

only forth also assembler also definitions

\ Forth Virtual Machine registers

\ Note that the Forth Stack Pointer (r1) is NOT the same register that
\ C uses for the stack pointer (r14).  The hardware does all sorts of
\ funny things with the C stack pointer when you do save and restore
\ instructions, and when the register windows overflow.

: base %g2  ;  : up  %g3  ;  : tos  %g4  ;
: ip   %g5  ;  : rp  %g6  ;  : sp   %g7  ;

: scr %l0  ;  : sc1  %l1 ;  : sc2  %l2 ;  : sc3 %l3  ;
: sc4 %l4  ;  : sc5  %l5 ;  : sc6  %l6 ;  : sc7 %l7  ;

\ C stack pointer is %o6
: spc %o7  ;	\ Saved Program Counter - set by the CALL instruction

\ Macros:

32\ : slln  ( rs1 rs2 rd -- ) sll  ;
32\ : srln  ( rs1 rs2 rd -- ) srl  ;
32\ : sran  ( rs1 rs2 rd -- ) sra  ;
32\ : nget  ( ptr off  dst -- )  ld  ;
32\ : nput  ( src off  ptr -- )  st  ;

64\ : slln  ( rs1 rs2 rd -- ) sllx  ;
64\ : srln  ( rs1 rs2 rd -- ) srlx  ;
64\ : sran  ( rs1 rs2 rd -- ) srax  ;
64\ : nput  ( src off  ptr -- )  stx  ;
64\ : nget  ( ptr off  dst -- )  ldx  ;

: put  ( src ptr -- )  0  swap  nput ;
: get  ( ptr dst -- )  0  swap  nget ;

: lget   ( ptr dst -- )  0 swap ld  ;
: lput   ( src ptr -- )  0 swap st  ;

: move  ( src dst -- )  %g0 -rot add    ;
: ainc  ( ptr -- )      dup /n swap add  ;
: adec  ( ptr -- )      dup /n swap sub  ;
: push  ( src ptr -- )  dup adec  put   ;
: pop   ( ptr dst -- )  over -rot get  ainc  ;
: test  ( src -- )      %g0 %g0 addcc   ;
: cmp   ( s1 s2 -- )    %g0     subcc   ;
: %hi   ( n -- n.hi )   h# 03ff invert land  ;
: %lo   ( n -- n.lo )   h# 03ff land  ;
: rtget ( srca srcb dst -- )
\t16  dup >r lduh r> ( dst )  tshift over sll
\t32  ld
;

\ Put a bubble in the pipeline to patch the load interlock bug
: bubble  ( nop )  ;

\ The next few words are already in the forth vocabulary;
\ we want them in the assembler vocabulary too
alias next  next
: exitcode  ( -- )
   previous
;
' exitcode is do-exitcode

alias end-code  end-code
alias c;  c;

: 'user  \ name  ( -- user-addressing-mode )
   up       ( reg# )
   '        ( acf-of-user-variable )
   >user#   ( reg# offset )
   dup h# 1000 [ also forth ] >= [ previous ] abort" user number too big"
;
: 'body  \ name  ( -- variable-apf-offset )
   '  ( acf-of-user-variable )  >body  origin-
;
: 'acf  \ name  ( -- variable-acf-offset )
   '  ( acf-of-user-variable )  origin-
;

\  If  'user  kicks you out -- or if you think it might -- use this:
\  It uses a  temp-register  to allow for a large user-offset.
\  If the user-offset is small enough, it acts like  'user
\
\  Oh!  And another nice thing about this:  If this is going to be part
\  of a "load" instruction (e.g., LD , LDX, NGET, etc.), the destination
\  register of that instruction can be used as the  temp-register ...
\
: 'userx  ( temp-reg -- user-addressing-mode ) \ <Name>
   dup up ' >user#			( temp-reg temp-reg user-reg# offset )
   dup h# 1000 [ also forth ] < if
      2swap 2drop exit					 (  user-reg# offset )
   then  [ previous ]			( temp-reg temp-reg user-reg# offset )
   \  Generate instruction(s) to load
   \  the offset into  temp-register .
   rot					( temp-reg user-reg# offset temp-reg )
   set					( temp-reg user-reg# )
;

: apf  ( -- reg offset )
\t16  sc1 2       \ code field is a 16-bit token
\t32  spc 8       \ code field is 2 instructions
;

: nops ( n -- )  0  ?do  nop  loop ;
: .align ( n -- )  here swap round-up here - 2 rshift nops  ;

: entercode  ( -- )  !csp align also assembler  ;
' entercode is do-entercode

only forth also definitions
