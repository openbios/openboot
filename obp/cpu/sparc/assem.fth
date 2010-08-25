\ @(#)assem.fth 2.29 06/02/16
\ Copyright 1985-1990 Bradley Forthware
\ copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

\ requires case.f
\ requires string-array.f

vocabulary srassembler
also srassembler definitions

headerless
alias lor  or	\ Because "or" gets redefined in the assembler
alias land and	\ Because "and" gets redefined in the assembler

defer here	\ For switching between resident and meta assembling
defer asm-allot	\ For switching between resident and meta assembling
defer asm@	\ For switching between resident and meta assembling
defer asm!	\ For switching between resident and meta assembling
defer /asm

\ Install as a resident assembler
: resident-assembler  ( -- )
   [ also forth ] ['] /l            [ previous ] is /asm
   [ also forth ] ['] here          [ previous ] is here
   [ also forth ] ['] allot         [ previous ] is asm-allot
   [ also forth ] ['] l@            [ previous ] is asm@
   [ also forth ] ['] instruction!  [ previous ] is asm!
;

resident-assembler


decimal

h#   1fff        constant immedmask
immedmask 1 +    constant immedbit
immedmask        constant maximmed
maximmed negate  constant minimmed
h#        1f constant regmask
h# 1000.0000 constant regmagic
h#        ff constant asimask

: reg  ( n -- )  regmagic + ;
: register  \ name  ( n -- )
   create w,  does> w@ reg
;

headers

 0 register %g0   1 register %g1   2 register %g2   3 register %g3
 4 register %g4   5 register %g5   6 register %g6   7 register %g7
 8 register %o0   9 register %o1  10 register %o2  11 register %o3
12 register %o4  13 register %o5  14 register %o6  15 register %o7
16 register %l0  17 register %l1  18 register %l2  19 register %l3
20 register %l4  21 register %l5  22 register %l6  23 register %l7
24 register %i0  25 register %i1  26 register %i2  27 register %i3
28 register %i4  29 register %i5  30 register %i6  31 register %i7

 0 register %r0    1 register %r1    2 register %r2    3 register %r3
 4 register %r4    5 register %r5    6 register %r6    7 register %r7
 8 register %r8    9 register %r9   10 register %r10  11 register %r11
12 register %r12  13 register %r13  14 register %r14  15 register %r15
16 register %r16  17 register %r17  18 register %r18  19 register %r19
20 register %r20  21 register %r21  22 register %r22  23 register %r23
24 register %r24  25 register %r25  26 register %r26  27 register %r27
28 register %r28  29 register %r29  30 register %r30  31 register %r31

64 register %f0   65 register %f1   66 register %f2   67 register %f3
68 register %f4   69 register %f5   70 register %f6   71 register %f7
72 register %f8   73 register %f9   74 register %f10  75 register %f11
76 register %f12  77 register %f13  78 register %f14  79 register %f15
80 register %f16  81 register %f17  82 register %f18  83 register %f19
84 register %f20  85 register %f21  86 register %f22  87 register %f23
88 register %f24  89 register %f25  90 register %f26  91 register %f27
92 register %f28  93 register %f29  94 register %f30  95 register %f31

097 register %f32  099 register %f34  101 register %f36  103 register %f38
105 register %f40  107 register %f42  109 register %f44  111 register %f46
113 register %f48  115 register %f50  117 register %f52  119 register %f54
121 register %f56  123 register %f58  125 register %f60  127 register %f62

128 register %asi 129 register %xcc 130 register %icc

headerless
: isimmed?  ( [ rs2 | imm ] -- f )  minimmed maximmed  between  ;
: ?freg  ( r -- r )
   dup  %f0 %f62 between 0=  abort" Floating point register required"
;
: ?ireg  ( r -- r )
   dup  %g0 %i7 between 0=  abort" Integer register required"
;
: setbits  ( opcode -- )  here  /asm asm-allot  asm!  ;
: opaddr  ( -- addr )  here /asm - ;
: tcc? ( -- flag )
   opaddr asm@ d# 19 rshift h# 3f and  b# 11.1010  =
;
: addbits  ( bits -- )  opaddr asm@ lor  opaddr asm!  ;
: clearbits ( bits -- )  invert opaddr asm@ and opaddr asm!  ;
: regset  ( reg shift -- )  swap regmask land  swap <<  addbits  ;
: rs  ( rs -- )  14 regset ;
: rd  ( rd -- )  25 regset ;
: rs2  ( rs2 -- ) 0 regset ;
: src  ( rs1 [ rs2 | imm ] -- )
   dup isimmed?  if   ( rs1 imm )
      immedmask land  immedbit lor  addbits
   else  ( rs1 rs2 )
      rs2
   then  ( rs1 )
   rs
;
: %asi? ( asi -- flag )  %asi =  ;
: asrc  ( rs1 [ rs2 | imm ] asi -- )
   dup %asi?  if                    ( rs1 imm asi )
      drop dup isimmed? 0=          ( rs1 imm flag )
      abort" Immediate must be used with alternate space instructions"
   else                             ( rs1 rs2 asi )
      asimask land  5 <<  addbits   ( rs1 rs2 )
      dup isimmed?                  ( rs1 rs2 flag )
      abort" Immediate fields can't be used with alternate space instructions"
   then
   src
;

: cas-src ( rs1 asi  -- )
   dup %asi?  if                    ( rs1 %asi )
      drop 			    ( rs1 )
      immedbit addbits		    ( rs1 )
   else                             ( rs1 asi )
      asimask land  5 <<  addbits   ( rs1 )
   then
   rs
;
: set-op  ( n class -- )  d# 30 <<  swap  d# 19  <<  +  setbits  ;
: wcreate  ( n -- )  create w,  [compile] does>  compile w@  ;  immediate
: set-op2  ( n -- )  2 set-op  ;
: w@set-op3  ( adr -- )  w@ 3 set-op  ;
: w@set-op2  ( adr -- )  w@ set-op2  ;
: createw,  ( n -- )  create w,  ;

\ Class 3 operations, loads and stores
: op3  ( opcode -- )
   createw,  does>  w@set-op3  ( rs1 [ rs2 | imm ] rd )  rd src
;

\ Load from alternate address space instructions
: opa  ( opcode -- )
   createw,  does>  w@set-op3  ( rs1 rs2 asi  rd )  rd asrc
;

\ For store instructions, where rd comes first
: sop3  ( opcode -- )
   createw,  does>  w@set-op3  ( rd rs1 [ rs2 | imm ] )  src rd
;

\ For store alternate instructions, where rd comes first
: sopa  ( opcode -- )
   createw,  does>  w@set-op3  ( rd  rs1 rs2 asi )  asrc rd
;

\ Class 3 operations, loads and stores
: op3a  ( opcode -- )
   createw,  does>  w@set-op3  ( rs1 rs2 asi rd )  rd rs2 cas-src
;

headers

hex
00 op3 lduw   04 sop3 st      08 op3 ldsw
01 op3 ldub   05 sop3 stb     09 op3 ldsb   0d op3 ldstub
02 op3 lduh   06 sop3 sth     0a op3 ldsh   0e sop3 stx
03 op3 ldd    07 sop3 std     0b op3 ldx    0f op3 swapl

00 op3 ld	\ V8 name for lduw

10 opa lda    14 sopa sta     18 opa ldswa
11 opa lduba  15 sopa stba    19 opa ldsba  1d opa ldstba
12 opa lduha  16 sopa stha    1a opa ldsha  1e sopa stxa
13 opa ldda   17 sopa stda    1b opa ldxa   1f opa swapa

20 op3 ldf    24 sop3 stf
21 op3 ldfsr  25 sop3 stfsr

32\ 22 op3 ldqf   26 sop3 stdfq
64\ 22 op3 ldqf   26 sop3 stqf                  2d op3  prefetch

23 op3 lddf   27 sop3 stdf

30 op3 ldfa
                                            3c op3a casa
32 opa ldqfa                                3d opa prefetcha
33 opa lddfa  36 sopa stqfa                 3e op3a casxa
34 sopa stfa  37 sopa stdfa

: stxfsr  %g1 -rot  stfsr ; : ldxfsr  %g1  ldfsr  ;
: stfsr   %g0 -rot  stfsr ; : ldfsr   %g0  ldfsr  ;

\ XXX should these be op3's instead of opa's???
\ 30 opa ldc    34 sopa stc   38 op3 ldc2   3c op3 stc2
\ 31 opa ldcsr  35 sopa stcsr 39 op3 ldc3   3d op3 stc3
\               36 sopa stdcq
\ 33 opa lddc   37 sopa stdc

28 op3 ldf2   2c sop3 stf2  \ V8 Only
29 op3 ldf3   2d sop3 stf3  \ V8 Only

headerless
\ Class 2 operations, arithmetic and logical
: op2  ( opcode -- )
   createw,  does>  w@set-op2  ( rs1 [ rs2 | imm ] rd )  rd src
;
\ For store instructions, where rd comes first
: sop2  ( opcode -- )
   createw,  does>  w@set-op3  ( rd rs1 [ rs2 | imm ] )  src rd
;

\ Fixed source
: dstop2  ( opcode -- )
   createw,  does>  w@set-op2  ( rd )  rd
;
\ Fixed destination
: srcop2  ( opcode -- )
   createw,  does>  w@set-op2  ( rs1 [ rs2 | imm ] )  src
;
headers

00 op2 add       08 op2 addc       10 op2 addcc     18 op2 addccc
01 op2 and       09 op2 mulx       11 op2 andcc
02 op2 or        0a op2 umul       12 op2 orcc      1a op2 umulcc
03 op2 xor       0b op2 smul       13 op2 xorcc     1b op2 smulcc
04 op2 sub       0c op2 subc       14 op2 subcc     1c op2 subccc
05 op2 andn      0d op2 udivx      15 op2 andncc
06 op2 orn       0e op2 udiv       16 op2 orncc     1e op2 udivcc
07 op2 xnor      0f op2 sdiv       17 op2 xnorcc    1f op2 sdivcc

20 op2 taddcc    28 op2 rdasr      30 op2 wrasr     38 op2    jmpl
21 op2 tsubcc                    ( saved/restored ) 39 op2    return
22 op2 taddcctv  2a op2 rdpr       32 op2 wrpr      ( Tcc )
23 op2 tsubcctv  ( flushw )                         ( iflush )
24 op2 mulscc    ( MOVcc  )        ( FPop1 )        3c op2    save
25 op2 sll       2d op2 sdivx      ( FPop2 )        3d op2    restore
26 op2 srl       2e op2 popc       ( IMPDEP1 )      ( done/retry )
27 op2 sra       ( MOVr )          ( IMPDEP2 )

29 dstop2 rdpsr  \ V8 Only
2a dstop2 rdwim  \ V8 Only
2b dstop2 rdtbr  \ V8 Only
31 srcop2 wrpsr  \ V8 Only
32 srcop2 wrwim  \ V8 Only
33 srcop2 wrtbr  \ V8 Only
39 op2    rett   \ V8 Only

 1 constant #LoadLoad
 2 constant #StoreLoad
 4 constant #LoadStore
 8 constant #StoreStore
10 constant #Lookaside
20 constant #MemIssue
40 constant #Sync

: membar ( imm -- ) %o7 swap %g0  rdasr ;

\ rd is always 0 for return
: return ( rs1 { rs2 | imm } -- )  %g0 return  ;

\ rs2 is always %g0 for RDASR Instruction
: rdasr ( rs1 rd -- )  %g0 swap rdasr  ;

\ rs2 is always %g0 for RDPR Instruction
: rdpr ( rs1 rd -- )  %g0 swap rdpr  ;

alias addx    addc    \ 08 op2 addx    SPARC V8 name
alias subx    subc    \ 0c op2 subx    SPARC V8 name
alias addxcc  addccc  \ 18 op2 addxcc  SPARC V8 name
alias subxcc  subccc  \ 1c op2 subxcc  SPARC V8 name


: sllx  sll 1000 addbits ; \ V9
: srlx  srl 1000 addbits ; \ V9
: srax  sra 1000 addbits ; \ V9

: rdy ( rd -- )  %g0 swap rdasr  ; \ Special case of RDASR
: wry ( rs1 [ rs2 | imm ] -- )  %g0  wrasr  ;  \ Special case of WRASR

: rdccr ( rd -- )  %g2 swap rdasr  ; \ Special case of RDASR
: wrccr ( rs1 [ rs2 | imm ] -- )  %g2  wrasr  ;  \ Special case of WRASR

: rdasi ( rd -- )  %g3 swap rdasr  ; \ Special case of RDASR
: wrasi ( rs1 [ rs2 | imm ] -- )  %g3  wrasr  ;  \ Special case of WRASR

: rdtick ( rd -- )  %g4 swap rdasr  ; \ Special case of RDASR

: rdpc ( rd -- )  %g5 swap rdasr  ; \ Special case of RDASR

: rdfprs ( rd -- )  %g6 swap rdasr  ; \ Special case of RDASR
: wrfprs ( rs1 [ rs2 | imm ] -- )  %g6  wrasr  ;  \ Special case of WRASR

: popc ( [ rs2 | imm ] rd -- )  %g0 -rot  popc  ; \ V9
: flushw   ( -- )  2b set-op2  ;         \ V9
: saved    ( -- )  31 set-op2  %g0 rd  ; \ V9
: restored ( -- )  31 set-op2  %g1 rd  ; \ V9
: done     ( -- )  3e set-op2  %g0 rd  ; \ V9
: retry    ( -- )  3e set-op2  %g1 rd  ; \ V9

headerless
: wrpr: ( rd --)  \ name
   create c,  does>  c@ %g0 lor ( rs1 rs2 rd )  wrpr
;
: rdpr: ( rs1 --)  \ name
   create c,  does>  c@ %g0 lor ( rd rs1 )  swap  rdpr
;
headers

d#  0 wrpr: wrtpc         ( rs1 [ rs2 | imm ] -- )
d#  1 wrpr: wrtnpc        ( rs1 [ rs2 | imm ] -- )
d#  2 wrpr: wrtstate      ( rs1 [ rs2 | imm ] -- )
d#  3 wrpr: wrtt          ( rs1 [ rs2 | imm ] -- )
d#  4 wrpr: wrtick        ( rs1 [ rs2 | imm ] -- )
d#  5 wrpr: wrtba         ( rs1 [ rs2 | imm ] -- )
d#  6 wrpr: wrpstate      ( rs1 [ rs2 | imm ] -- )
d#  7 wrpr: wrtl          ( rs1 [ rs2 | imm ] -- )
d#  8 wrpr: wrpil         ( rs1 [ rs2 | imm ] -- )
d#  9 wrpr: wrcwp         ( rs1 [ rs2 | imm ] -- )
d# 10 wrpr: wrcansave     ( rs1 [ rs2 | imm ] -- )
d# 11 wrpr: wrcanrestore  ( rs1 [ rs2 | imm ] -- )
d# 12 wrpr: wrcleanwin    ( rs1 [ rs2 | imm ] -- )
d# 13 wrpr: wrotherwin    ( rs1 [ rs2 | imm ] -- )
d# 14 wrpr: wrwstate      ( rs1 [ rs2 | imm ] -- )

d#  0 rdpr: rdtpc         ( rd -- )
d#  1 rdpr: rdtnpc        ( rd -- )
d#  2 rdpr: rdtstate      ( rd -- )
d#  3 rdpr: rdtt          ( rd -- )
d#  4 rdpr: rdtick        ( rd -- )
d#  5 rdpr: rdtba         ( rd -- )
d#  6 rdpr: rdpstate      ( rd -- )
d#  7 rdpr: rdtl          ( rd -- )
d#  8 rdpr: rdpil         ( rd -- )
d#  9 rdpr: rdcwp         ( rd -- )
d# 10 rdpr: rdcansave     ( rd -- )
d# 11 rdpr: rdcanrestore  ( rd -- )
d# 12 rdpr: rdcleanwin    ( rd -- )
d# 13 rdpr: rdotherwin    ( rd -- )
d# 14 rdpr: rdwstate      ( rd -- )
[ifndef] SUN4V
d# 31 rdpr: rdver         ( rd -- )
[then]

: ,%icc ( -- )
   tcc?  if  h# 1800  else  h# 30.0000  then
   clearbits
;
: ,%xcc ( -- )
   ,%icc  tcc?  if  h# 1000  else  h# 20.0000  then
   addbits
;

: trapif ( src cond -- )
   h# 3a set-op2  addbits
   dup isimmed? if h# 7f land then
   src
64\  ,%xcc 
;

: iflush  ( src -- )       3b set-op2  src  ;
: stbar   ( -- )           %o7  %g0  rdasr  ;
\ This really should be a sethi instruction, because the %g0 can generate
\ a pipeline dependency interlock resulting in a wasted cycle.
\ : nop  %g0 %g0 %g0 add  ;

\ Floating-point operations

headerless
: set-opf  ( apf -- )  34 set-op2   w@  5 <<  addbits  ;
: ffop  \ name  ( opcode -- )
  createw,  does>  set-opf  ( frs frd )  ?freg rd  ?freg rs2
;
headers

0c9 ffop fstod   0cd ffop fstox
0c6 ffop fdtos   0ce ffop fdtox
0c7 ffop fxtos   0cb ffop fxtod

001 ffop fmovs   002 ffop fmovd   003 ffop fmovq
005 ffop fnegs   006 ffop fnegd   007 ffop fnegq
009 ffop fabss   00a ffop fabsd   00b ffop fabsq
029 ffop fsqrts  02a ffop fsqrtd  02b ffop fsqrtx

0c4 ffop fitos   0c8 ffop fitod   0cc ffop fitox

0c1 ffop fstoir  0c2 ffop fdtoir  0c3 ffop fxtoir
0d1 ffop fstoi   0d2 ffop fdtoi   0d3 ffop fxtoi

headerless
: f2op  \ name  ( opcode -- )
  createw,
  does>  set-opf  ( frs1 frs2 frd )   ?freg rd  ?freg rs2  ?freg rs
;
headers
041 f2op fadds   042 f2op faddd   043 f2op faddx
045 f2op fsubs   046 f2op fsubd   047 f2op fsubx
049 f2op fmuls   04a f2op fmuld   04b f2op fmulx
04d f2op fdivs   04e f2op fdivd   04f f2op fdivx

headerless
: fcmpop  \ name  ( opcode -- )
   createw,   does>  set-opf    ( frs1 frs2 )
   1 d# 19 <<  addbits          ( frs1 frs2 apf )
   ?freg rs2  ?freg rs
;
headers
051 fcmpop fcmps   052 fcmpop fcmpd   053 fcmpop fcmpx
055 fcmpop fcmpes  056 fcmpop fcmped  057 fcmpop fcmpex

headerless
hex
: cond  ( bits -- )  createw,  does>  w@  d# 25 <<  ;

headers
\ Condition names.  There are more of these near the end of the file.

8 cond always 0 cond never c cond hi   4 cond ls
d cond cc     5 cond cs    9 cond ne   1 cond eq
f cond vc     7 cond vs    e cond pl   6 cond mi
b cond ge     3 cond lt    a cond gt   2 cond le

headerless
: -cond  ( condition -- not-condition )
   h# 1000.0000 [ also forth ] xor [ previous ]
;

: op0   ( op -- )   d# 22 << setbits  ;
headers
: unimp  ( -- )  0 op0  ;
: sethi  ( value rd -- )  4 op0  rd  n->l d# 10 >>  addbits  ;
: nop ( -- )  0 %g0 sethi  ;
headerless
: fits-immediate-field?  ( value -- flag )
   h# ffff.f000 l->n h# 0000.0fff  between
;
headers
: setuw  ( value rd -- )
   over  n->l fits-immediate-field?  if
      \ The value is small enough to omit the sethi instruction
\      h# 1fff land  %g0 swap add
      %g0  rot h# 1fff land  rot  or
   else
      \ We have to use sethi for the high-order bits
      2dup sethi   ( value rd )
      swap h# 0000.03ff land tuck  ( masked-value rd masked-value )
      if    tuck or	\ Merge in the low bits
      else  2drop	\ No need to merge in low-order zeroes
      then
   then
;
alias set setuw

: setsw ( value rd -- )
   2dup  set        ( value rd )
   swap 0<  if      ( rd )
      %g0 over sra  (  )
   else             ( rd )
      drop
   then
;
: setx ( value reg rd -- )
   rot dup fits-immediate-field?  if  ( reg rd value )
      %g0 swap rot  or  drop  exit    (  )
   then                               ( reg rd value )
   dup d# 32 >> ?dup  if              ( reg rd value value-hi )
      2over drop tuck setuw           ( reg rd value reg )
      over n->l  if                   ( reg rd value reg )
	 d# 32 over  sllx             ( reg rd value )
      else                            ( reg rd value reg )
	 2over  d# 32 swap sllx  drop ( reg rd value reg )
      then                            ( reg rd value )
      n->l tuck  if                   ( reg val-lo rd )
	 tuck  setuw                  ( reg rd )
	 tuck  or                     (  )
      else                            ( reg value rd )
	 3drop                        (  )
      then                            (  )
   else                               ( reg rd value )
      swap  setuw  drop               (  )
   then                               (  )
;

: ret  ( -- )  %i7 8  %g0  jmpl  ;
: retl  ( -- )  %o7 8  %g0  jmpl  ;

: ,a     ( -- )  h# 2000.0000 addbits  ;
: ,pt    ( -- )  h# 0008.0000 addbits  ;
: ,pn    ( -- )  h# 0008.0000 clearbits  ;
alias annul ,a

headerless
: offset-22  ( target-adr branch-adr -- masked-displacement )
   - 2 >>a
   dup h# -001f.ffff  h# 001f.ffff  between
   0= abort" displacement out of 22-bit range"
   h# 3f.ffff land
;
\ All longword displacements are guaranteed to be in a 30 bit range
: offset-30  ( destination-adr branch-adr -- masked-displacement )
   - 2 >>a
   h# 3fff.ffff land
;
: branch:  \ name  ( op -- )
   createw,
   does> w@  ( adr condition type )  op0  addbits  opaddr offset-22 addbits
;

: offset-16  ( target-adr branch-adr -- disp16lo disp16hi )
   - 2 >>a
   dup h# -0000.7fff  h# 0000.7fff  between
   0= abort" displacement out of 16-bit range"
   h# 0.ffff land
   dup h# 0.3fff land swap
   d# 13 >> d# 20 <<  lor
;

: offset-19  ( target-adr branch-adr -- masked-displacement )
   - 2 >>a
   dup h# -0007.ffff  h# 0007.ffff  between
   0= abort" displacement out of 19-bit range"
   h# 07.ffff land
;
: %icc? ( reg -- flag )  %icc =  ;
: %xcc? ( reg -- flag )  %xcc =  ;
: bpcc:  \ name ( op -- )
   createw,
   does> w@                      ( [ icc | xcc ] adr cond type )
      op0                   ( [ icc | xcc ] adr cond )
      addbits               ( [ icc | xcc ] adr )
      opaddr offset-19 addbits  ( [ icc | xcc ] )
      dup %icc?  if
	 drop  ,%icc
      else
	 dup %xcc?  if
	    drop  ,%xcc
	 else
	    ??cr ." Bad CC register " .x cr
	 then
      then
      ,pt
;
: bpr:  \ name  ( rcond -- )
   createw,
   does> w@				( rs1 adr condition )
      3 op0				( rs1 adr condition )
      d# 25 << addbits			( rs1 adr )
      opaddr  ( rs1 target-adr branch-adr )
      offset-16 addbits  rs  ,pt
;

: offset-19/22 ( target-adr branch-adr -- displacement )
   dup asm@ d# 22 >> 7 land 1 =  if  offset-19  else  offset-22  then
;
headers
2 branch: brif   ( adr condition -- ) \ Integer Cond. Codes
6 branch: brfif  ( adr condition -- ) \ Floating Point Cond. Codes
7 branch: brcif  ( adr condition -- ) \ Coprocessor Cond. Codes

: branch!  ( target-adr branch-adr -- )
   tuck offset-22 3080.0000 + swap asm!
;

1 bpcc: bprif   ( [ icc | xcc ] adr cond -- ) \ Prediction reg. Integer CC
5 bpcc: bprfif  ( [ icc | xcc ] adr cond -- ) \ Prediction reg. Floating CC
: bpra ( [ icc | xcc ] adr -- )  always bprif  ;

: bra  ( adr -- )  always brif  ;

1 bpr: brz     2 bpr: brlez    3 bpr: brlz
5 bpr: brnz    6 bpr: brgz     7 bpr: brgez

: call  ( adr -- )  h# 4000.0000 setbits  opaddr offset-30 addbits  ;

: but  ( mark1 mark2 -- mark2 mark1 )  swap  ;

64\ : brif   ( adr condition -- )  %xcc -rot bprif  ;

headerless
: <mark  ( -- <mark )  here  ;
: >mark  ( -- >mark )  here  ;
: >resolve  ( >mark -- )
   here over         ( >mark here >mark )
   offset-19/22      ( >mark displacement )
   over asm@ +       ( >mark opcode )
   swap asm!         (  )
;

\ >+resolve is used when the resolution follows a branch,
\ so the delay slot must be skipped
: >+resolve  ( >mark -- )
   here la1+ over    ( >mark here+4 >mark )
   offset-19/22      ( >mark displacement )
   over asm@ +       ( >mark opcode )
   swap asm!         (  )
;
: <resolve  ( -- )  ;
headers

\ Define these last to delay overloading of the forth versions

hex
1 cond =      1 cond 0=
2 cond <=     2 cond 0<=
3 cond <
4 cond u<=
5 cond u<
              6 cond 0<
9 cond <>     9 cond 0<>
a cond >      a cond 0>
b cond >=
c cond u>
d cond u>=
              e cond 0>=


: if     ( cond -- >mark )             >mark  here  rot -cond  brif  ;
: ahead  ( -- >mark )                  never if  ;
: then   ( >mark -- )                  >resolve  ;
: else   ( >mark -- >mark1 )           ahead  but  >+resolve  ;
: begin  ( -- <mark )                  <mark  ;
: while  ( <mark cond -- <mark >mark ) if  but  ;
: until  ( <mark cond -- )             -cond brif  ;
: again  ( <mark -- )                  bra  ;
: repeat ( <mark >mark -- )            again >+resolve  ;

previous definitions
