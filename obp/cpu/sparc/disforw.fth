id: @(#)disforw.fth 2.31 06/04/21 17:08:22
purpose: SPARC disassembler - prefix syntax
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Copyright 1985-1990 Bradley Forthware

\ lddf  disassembler needs to specify f register, not i register
\  ldxfsr  is not properly disassembled
headers
vocabulary disassembler
also disassembler also definitions

headerless

64\ true  constant sparc-v9?
32\ false constant sparc-v9?

string-array real-regs
," %g0"  ," %g1"  ," %g2"  ," %g3"
," %g4"  ," %g5"  ," %g6"  ," %g7"
," %o0"  ," %o1"  ," %o2"  ," %o3"
," %o4"  ," %o5"  ," %o6"  ," %o7"
," %l0"  ," %l1"  ," %l2"  ," %l3"
," %l4"  ," %l5"  ," %l6"  ," %l7"
," %i0"  ," %i1"  ," %i2"  ," %i3"
," %i4"  ," %i5"  ," %i6"  ," %i7"
end-string-array

defer regs  ' real-regs is regs

string-array op2s
(  0 ) ," add"     ," and"     ," or"       ," xor"
(  4 ) ," sub"     ," andn"    ," orn"      ," xnor"
(  8 ) ," addx"    ," mulx"    ," umul"     ," smul"
(  c ) ," subx"    ," udivx"   ," udiv"     ," sdiv"
( 10 ) ," addcc"   ," andcc"   ," orcc"     ," xorcc"
( 14 ) ," subcc"   ," andncc"  ," orncc"    ," xnorcc"
( 18 ) ," addxcc"  ," ???"     ," umulcc"   ," smulcc"
( 1c ) ," subxcc"  ," ???"     ," udivcc"   ," sdivcc"
( 20 ) ," taddcc"  ," tsubcc"  ," taddcctv" ," tsubcctv"
( 24 ) ," mulscc"  ," sll"     ," srl"      ," sra"
( 28 ) ," rdasr"   ," rdpsr"   ," rdpr"     ," rdtbr"
( 2c ) ," movcc"   ," sdivx"   ," popc"     ," movr"
( 30 ) ," wrasr"   ," wrpsr"   ," wrpr"     ," wrtbr"
( 34 ) ," fpop1"   ," fpop2"   ," cpop1"    ," cpop2"
( 38 ) ," jmp"     ," rett"    ," ticc"     ," iflush"
( 3c ) ," save"    ," restore" ," ???"
end-string-array

string-array op3s
(  0 ) ," ld"      ," ldub"       ," lduh"   ," ldd"
(  4 ) ," st"      ," stb"        ," sth"    ," std"
(  8 ) ," ldsw"    ," ldsb"       ," ldsh"   ," ldx"
(  c ) ," ???"     ," ldstub"     ," stx"    ," swapl"
( 10 ) ," lda"     ," lduba"      ," lduha"  ," ldda"
( 14 ) ," sta"     ," stba"       ," stha"   ," stda"
( 18 ) ," ldswa"   ," ldsba"      ," ldsha"  ," ldxa"
( 1c ) ," ???"     ," ldstba"     ," stxa"   ," swapa"
( 20 ) ," ldf"     ," ldfsr"      ," ldqf"   ," lddf"
32\ ( 24 ) ," stf"     ," stfsr"      ," stdfq"  ," stdf"
64\ ( 24 ) ," stf"     ," stfsr"      ," stqf"   ," stdf"
( 28 ) ," ???"     ," ???"        ," ???"    ," ???"
( 2c ) ," ???"     ," prefetch"   ," ???"    ," ???"
( 30 ) ," ldfa"    ," ???"        ," ldqfa"  ," lddfa"
( 34 ) ," stfa"    ," ???"        ," stqfa"  ," stdfa"
( 38 ) ," ???"     ," ???"        ," ???"    ," ???"
( 3c ) ," casa"    ," prefetcha"  ," casxa"  ," ???"
end-string-array

string-array  fiops	\ Op-field - 0xc0
," ???"     ," fstoir"  ," fdtoir"  ," fxtoir"
," fitos"   ," ???"     ," fdtos"   ," fxtos"
," fitod"   ," fstod"   ," ???"     ," fxtod"
," fitox"   ," fstox"   ," fdtox"   ," ???"
," ???"     ," fstoi"   ," fdtoi"   ," fxtoi"
end-string-array

string-array  f2ops	\ Op-field - 0x40
," ???"     ," fadds"   ," faddd"   ," faddx"
," ???"     ," fsubs"   ," fsubd"   ," fsubx"
," ???"     ," fmuls"   ," fmuld"   ," fmulx"
," ???"     ," fdivs"   ," fdivd"   ," fdivx"
end-string-array

string-array  f2ops+	\ Op-field - 0x60
," ???"     ," ???"     ," ???"     ," ???"
," ???"     ," ???"     ," ???"     ," ???"
," ???"     ," fsmuld"  ," ???"     ," ???"
," ???"     ," ???"     ," fdmulx"  ," ???"
end-string-array

string-array  fcmpops	\ Op-field - 0x50
," ???"     ," fcmps"   ," fcmpd"   ," fcmpx"
," ???"     ," fcmpes"  ," fcmped"  ," fcmpex"
end-string-array

string-array conds	\ Conditional names for integer branches and traps
( 0 ) ," n"   ," e"    ," le"   ," l"    ," leu"  ," cs"  ," neg"  ," vs"
( 8 ) ," a"   ," ne"   ," gt"   ," ge"   ," gu"   ," cc"  ," pos"  ," vc"
end-string-array

string-array fconds	\ Conditional names for floating point branches
( 0 ) ," n"   ," ne"   ," lg"   ," ul"   ," l"    ," ug"  ," g"    ," u"
( 8 ) ," a"   ," e"    ," ue"   ," ge"   ," uge"  ," le"  ," ule"  ," o"
end-string-array

string-array cconds	\ Conditional names for coprocessor branches
( 0 ) ," n"   ," 123"  ," 12"   ," 13"   ," 1"    ," 23"  ," 2"    ," 3"
( 8 ) ," a"   ," 0"    ," 03"   ," 02"   ," 023"  ," 01"  ," 013"  ," 012"
end-string-array

string-array rconds	\ Conditional names for BPr MOVr and FMOVr
      ," ??"  ," z"    ," lez"  ," lz"   ," ??"   ," nz"  ," gz"   ," gez"
end-string-array

decimal
\ Generates a mask with #bits set in the low part.  4 >mask  yields  0000000f
variable instruction
variable end-found
variable display-offset  0 display-offset !
variable branch-target		\ Help for tracing/single-stepping
variable alternate?  alternate? off
variable max-branch-target	\  Help determine if end was found
false value annulled?

headers
variable pc
: pc@ ( -- adr ) pc @ ;
: pc! ( adr -- ) pc ! ;
: (inst@ ( adr -- opcode )   l@  ;
defer inst@  ' (inst@  is  inst@

: pc@l@ ( -- opcode ) pc@ inst@ ;

headerless

: 4u# ( n -- n' )     u# u# u# u#        ;
: 4u#. ( n -- n' )    4u#  ascii . hold  ;

headers

defer showaddr  ( addr -- )
: udis. ( n -- )
   <#
[ /n /l > [if] ]	\  Compile-time test; do we need two more of these?
   4u#.
   4u#.
[ [then] ]
   4u#.
   4u#
   u#>  type
;
' udis.  is showaddr
headerless

: +offset  ( adr -- adr' )  display-offset @  -  ;
: >mask  ( #bits -- mask )  1 swap << 1-  ;
: bits  ( right-bit #bits -- field )
   >mask
   instruction @ rot >> 		( mask shifted-instruction )
   and					( field )
;
: 5bits  ( right-bit -- field )  5 bits  ;
: rd   ( -- field )  d# 25 5bits  ;
: rs1  ( -- field )  d# 14 5bits  ;
: rs2  ( -- field )  0 5bits  ;
: shcnt ( -- field ) 0 6 bits  ;
: bit?  ( bit# -- f )  instruction @ 1 rot << and  ;
: bit13? ( -- flag )  d# 13 bit?  ;
: bit12? ( -- flag )  d# 12 bit?  ;
\ Display formatting
variable start-column
: op-col  ( -- )  start-column @  d# 12 +  to-column  ;

: .,  ( -- )  ." , "  ;
: .reg  ( n -- )    regs ".  ;
: .asreg ( n -- )  ." %r" .d  ;
: >freg ( n mask -- freg# )
   over and swap
   1 and 5 << or
;
: .(freg#) ( freg# -- )
   ." %f"  .d
;
: .freg  ( n -- )
   d# 19 2 bits  if
       h# 1e  >freg
   then
   .(freg#)
;
: .creg  ( n -- )  ." %c" .d  ;
: .frsrd  ( -- )  rs2 .freg  ., rd .freg  ;
: .3fregs  ( -- )  rs1 .freg  .,  .frsrd  ;
: op.3fregs  ( -- ) op-col .3fregs  ;
: .frs1rs2  ( -- )  rs1 .freg  ., rs2 .freg  ;
: .rd  ( -- )   rd .reg   ;
: op.rd ( -- )  op-col .rd ;
: sext ( n wid'  -- n' ) tuck << l->n swap >>a ;	\ Sign extend

\  Extract the Sign-Extended immediate field (starting at bit-position zero)
\      whose width is given.
: simm# ( wid -- n' )
   0 over bits			( wid n )
   d# 32 rot - 			( n wid' )
   sext
;
\  Three popular sizes of Sign-Extended immediate fields:
: immedop ( -- n )   d# 13 simm#  ;
: simm10  ( -- n )   d# 10 simm#  ;
: simm11  ( -- n )   d# 11 simm#  ;

: immasi ( -- asi )
   5 8 bits
;

\  Stuff the branch-target and update the max-branch-target
: branch-target! ( targ-addr -- )
   dup branch-target !			( targ-addr )
   max-branch-target @ umax max-branch-target !
;

\  An unconditional ("always") branch ends the disassembly
\  if there are no branch-targets forward of its location.
: ?end-found ( -- )
   pc@ max-branch-target @ >= end-found !
;

: .?asi ( -- )
   alternate? @  if
      bit13?  if ."  %asi"
      else
	 immasi (u.) type
      then
   then
;
: .rs1 ( -- )  rs1 .reg  ;
: .rs2 ( -- )  bit13?  if  immedop (u.) type   else  rs2 .reg  then  ;
: .src ( -- )  .rs1  .,  .rs2  .?asi  ;
: op.src ( -- )  op-col .src  ;
: .illegal ( -- )  ." Illegal instruction: " instruction @ u.  ;

: opcode  ( -- n )  d# 19 6 bits  ;

: .ea-sparc  ( -- )
   ." ["
   .rs1
   opcode h# 3d and h# 3c =  if
      ." ]"
      .?asi
      ., rs2 .reg
   else
      bit13?    if
         immedop  ?dup  if
            dup 0>  if  ."  + "  else  ."  - "  then  abs   (.) type
         then
      else
         rs2 ?dup  if  ."  + " .reg  then
      then
      ." ]"
      .?asi
   then
;

defer .impl-asi-ea  ' .ea-sparc is .impl-asi-ea
\  This may get re-vectored for variant implementations.

\  Non-implementation-dependent or reserved ASIs are:
\      10, 11, 18, 19, 80..83, and 88..bf
\  (Ref:  SPARC Arch. Manual, sec 6.3.1.3, Table 12)
: ea-sparc?  ( -- Use-.ea-sparc? )
   immasi dup				( asi asi )
   " "( 10 11 18 19 80 81 82 83 )"	\  Inconveniently-grouped-ASI-list
   rot scantochar <> nip		( asi match? )
   swap h# 88 h# bf  between
   or
;

: .ea ( -- )
   alternate? @ 0=
   bit13?     or
   ea-sparc?  or
   if    .ea-sparc   else   .impl-asi-ea   then
   alternate? off
;



\  The  condition-code  field may occur in either of two
\       bit-positions within an instruction.
\  Take the bit-position as a parameter and print the
\       integer conditional name
: .#cond ( bit# -- ) 4 bits  conds ".  ;
: .cond  ( -- )  d# 25 .#cond  ;
: .rcond  ( n -- )  rconds ".  ;

\  Likewise the floating point conditional name
: .#fcond ( bit# -- ) 4 bits fconds ".  ;

: .(op2) ( -- )  opcode op2s ". ;
: .op2 ( -- )    .(op2) op-col  ;

: .freg-double ( n -- )
   h# 3e  >freg  .(freg#)
;

: .freg-quad ( n -- )
   h# 3c  >freg  .(freg#)
;

: .frs1rs2-double  ( -- )  rs1 .freg-double  ., rs2 .freg-double  ;
: .3fregs-double  ( -- )  .frs1rs2-double ., rd .freg-double ;

: .freg-encode ( n -- )
   opcode  h# 2b  and  case
      h# 23 of  .freg-double  endof   \ double operation
      h# 22 of  .freg-quad    endof   \ quad
      swap .freg
   endcase
;

: .r/fd  ( -- )
   rd
   d# 23 2 bits
   sparc-v9?  if
      case
         2 of  .freg-encode  endof
         3 of  d# 19 4 bits
	       h# 0d and h# 0c =  if
		    .reg
	       else .freg-encode
	       then
	   endof	 \  CAS  special case
	 swap  .reg
      endcase
   else
      case
         2 of  .freg  endof
         3 of  .creg  endof
         swap  .reg
      endcase
   then
;
: .class3  ( -- )
   opcode dup op3s ".  op-col			( op-code )

   \ XXX Is the next line correct for the "ldc" class of instruction?
   dup h# 10 and  if  alternate? on  then

   dup  h# 3c = 					\  CASA
   over h# 3e = 					\  CASX
   or if  drop  
      ." [" .rs1 ." ] " .?asi ., .rs2 ., .rd
   else 					( op-code )
      dup  h# 0c and      4 =
      swap h# 2f and  h# 0e = or
      if  .r/fd  .,  .ea  else  .ea  ., .r/fd  then
   then 					( -- )
   alternate? off
;

: fp-op  ( -- n )  5 9 bits  ;
: op.frsrd ( -- )  op-col  .frsrd  ;
: .fpop1  ( -- )
   fp-op  h# c0  h# d3  between  if	\ Type conversion operators
      fp-op  h# c0 -  fiops ".   op.frsrd
   else
   fp-op  h# 40  h# 4f  between  if	\ Arithmetic operators
      fp-op  h# 40 -  f2ops ".   op.3fregs
   else
   fp-op  h# 60  h# 6f  between  if	\ More arithmetic operators
      fp-op  h# 60 -  f2ops+ ".  op.3fregs
   else
   fp-op  case				\ Miscellaneous operators
          1 of  ." fmovs"    op.frsrd  endof
          5 of  ." fnegs"    op.frsrd  endof
          9 of  ." fabss"    op.frsrd  endof
      h# 29 of  ." fsqrts"   op.frsrd  endof
      h# 2a of  ." fsqrtd"   op.frsrd  endof
      h# 2b of  ." fsqrtx"   op.frsrd  endof
      ." fpop???"
   endcase
   then then then
;
: .fpop2  ( -- )
   fp-op  h# 50 -  fcmpops ".  op-col  .frs1rs2
;

string-array membar-mask
   ," #LoadLoad "
   ," #StoreLoad "
   ," #LoadStore "
   ," #StoreStore "
   ," #Lookaside "
   ," #MemIssue "
   ," #Sync "
end-string-array

: .membar ( -- )
   ." membar" op-col
   immedop
   7 0 do
      dup 1 and  if
         i membar-mask ".
      then
   2/ loop drop
;

: .stbar ( -- )  ." stbar"  ;

: .wry ( -- )  ." wry"    op.src  ;
: .rdy ( -- )  ." rdy"    op.rd   ;

: .op2+src+dest ( -- ) .op2  .src ., .rd ;

: .op2-wra ( -- )  .op2+src+dest .asreg  ;
: .op2-rda ( -- )  .op2  rs1 .asreg ., .rd  ;

defer .impl-wrasr  ' .illegal is .impl-wrasr
defer .impl-rdasr  ' .illegal is .impl-rdasr

: .wrasr-v9 ( -- )
   rd d# 16 d# 31  between  if
      .impl-wrasr
   else
      rd   case
             0  of  .wry		    endof
             2  of  ." wrccr"  op.src  endof
             3  of  ." wrasi"  op.src  endof
             6  of  ." wrfprs" op.src  endof
         d# 15  of
            rs1  ( 0<> )  if  .illegal
	    else     bit13?  if
                  ." sigm"
	       else
                  .illegal
               then
            then
         endof
	 .illegal
      endcase
   then
;
: .wrasr-v8 ( -- )
   rd   (  0<>  )  if
      .op2-wra
   else
      .wry
   then
;
: .wrasr ( -- )  sparc-v9?  if  .wrasr-v9  else  .wrasr-v8  then  ;
: .rdasr-v9 ( -- )

   rs1 d# 16 d# 31  between  if
      .impl-rdasr
   else
      rs1   case
              0 of  .rdy		   endof
              2 of  ." rdccr"  op.rd  endof
              3 of  ." rdasi"  op.rd  endof
              4 of  ." rdtick" op.rd  endof
              5 of  ." rdpc"   op.rd  endof
              6 of  ." rdfprs" op.rd  endof
         d#  15 of
  	    rd  ( 0<> )  if  .illegal
	    else     bit13?  if
	          .membar
	       else
	          .stbar
	       then
            then
         endof
         .illegal
      endcase
   then
;
: .rdasr-v8 ( -- )
   rs1   case
          0  of  .rdy   endof
      d# 15  of
	 rd  ( 0<> )  if   .illegal
	 else              .stbar
	 then
      endof
      .op2-rda
   endcase
;

: .rdasr ( -- )  sparc-v9?  if  .rdasr-v9  else  .rdasr-v8  then  ;

: .shift ( -- ) 	\  Called when opcode is between h# 25 thru h# 27
   .(op2)  bit12?  if  ." x"  then
   op-col  .rs1 .,  shcnt  bit13?  if
      bit12?  if  h# 3f  else  h# 1f  then  and (u.) type
   else
      .reg
   then  ., .rd
;

string-array priv-regs
," tpc"       ," tnpc"      ," tstate"   ," tt"
," tick"      ," tba"       ," pstate"   ," tl"
," pil"       ," cwp"       ," cansave"  ," canrestore"
," cleanwin"  ," otherwin"  ," wstate"   ," fq"
end-string-array

: .rdpr ( -- )
   rs1 0 d# 15 between  if
      ." rd"  rs1 priv-regs ".  op.rd  exit
   then
   rs1 d# 16 =  if
      ." rdgl" op.rd  exit
   then
   rs1 d# 31 =  if
      ." rdver" op.rd
   else
      .illegal
   then 
;

: .wrpr ( -- )
   rd 0 d# 14 between  if
      ." wr"  rd priv-regs ". op.src  exit
   then
   rd d# 16 =  if
      ." wrgl" op.src
   else
      .illegal
   then
;

\ Depending upon the rcond field in the instruction, generate
\ appropriate instruction:
\ rcond=001b movrz;  rcond=010b movrlez; rcond=011b movrlz
\ rcond=101b movrnz; rcond=110b movrgz;  rcond=111b movrgez 
\ rcond=000b or 100b (reserved) movr???
: .movr ( -- )
   ." movr" d# 10 3 bits .rcond op-col .rs1 ., bit13?  if
      simm10 (u.)
   else
      .rs2
   then  .,  .rd
;
\  The  cc1|cc0  field may occur in either of two
\       bit-positions within an instruction.
\  Take the bit-position as a parameter and show the field
: .#xcc ( bit# -- )
   2 bits dup 2 =  if
      drop ." %xcc"
   else
      0=  if  ." %icc"  else ." ???"  then
   then  .,
;
\  Show the  cc1|cc0  field of a Class 0, Format 2
\      instruction, (branches Bicc BPcc, BPr, etc.)
\      where it occurs in bit-position d# 20 
: .cc ( -- )
   d# 20 .#xcc
;
\  Show the  cc1|cc0  field of a Class 2, Format 4
\      instruction, (traps Tcc  and  MOVcc, FMOVcc)
\      where it occurs in bit-position d# 11 
: .txcc ( -- )    d# 11 .#xcc  ;

\  Show the  Tcc  instruction
: .ticc  ( -- )
   ." t"  .cond    op-col  .txcc
   .rs1 ., bit13?  if
	\ Extract bits 0..10 as a "simm11" field.
	\    Bits 7..10 are reserved.

	\  Let's show what's actually there.
      simm11 (u.) type
		\  Alternatively, we could highlight an error, thus:
   \  simm11 dup (u.) type
   \  h# 780 and if   ."  "t"t\  Illegal Trap #" then

   else rs2 .reg
   then
;

\  Condition field of a MOVcc or MOVFcc instruction
: .(mov)cond ( -- )
   d# 14		\  bit-position where it occurs
   d# 18 bit? if      .#cond
   else        ." f" .#fcond
   then
;
: .movcc ( -- )
   ." mov"  .(mov)cond   op-col
   d# 18 bit? if  .txcc
   else  d# 11 2 bits ." %fcc" 1 .r .,
   then  bit13?  if
      simm11 (u.) type 
   else rs2 .reg
   then  ., .rd
;

: .popc ( -- )
   rs1  if
      .illegal
   else
      ." popc"  op-col .rs2  .,  .rd
   then
;

defer .impdep1  ' .illegal is .impdep1
defer .impdep2  ' .illegal is .impdep2

: .class2  ( -- )
   false is annulled?
   opcode  h# 38  h# 39  between  end-found  !
   opcode  h# 25  h# 27  between  if  .shift    exit  then
   opcode case
      h# 28  of  .rdasr     endof
      h# 29  of  .op2  .rd  endof \ RDPSR
      h# 2a  of
         sparc-v9?  if  .rdpr  else  ." rdwim"  op.rd  then
      endof
      h# 2b  of
	 sparc-v9?  if
	    ." flushw"
	 else
	    .op2  .rd  \ RDTBR
	 then
      endof
      h# 2c  of  .movcc  endof
      h# 2e  of  .popc   endof
      h# 2f  of  .movr   endof
      h# 30  of  .wrasr  endof
      h# 31  of
	 sparc-v9?  if
	    rd  case
	       0  of ." saved"     endof
	       1  of ." restored"  endof
	       2  of ." allclean"  endof
	       3  of ." otherw"    endof
	       4  of ." normalw"   endof
	       5  of ." invalw"    endof
	       .illegal
	    endcase
	 else
	    .op2  .src  \ WRPSR
	 then
      endof
      h# 32  of  
         sparc-v9?  if  .wrpr  else  ." wrwim" op.src  then
      endof
      h# 33  of  .op2  .src  endof  \ WRTBR
      h# 34  of  .fpop1      endof
      h# 35  of  .fpop2      endof
      h# 36 of
         sparc-v9?  if
	    .impdep1
	 else
	    .op2+src+dest
	 then
      endof
      h# 37 of
         sparc-v9?  if
            .impdep2
         else
            .op2+src+dest
         then
      endof
      h# 3a  of  .ticc       endof
      h# 3e  of
	 ?end-found end-found @ is annulled?
	 rd  case
	    0 of  ." done"   endof
	    1 of  ." retry"  endof
	    end-found off false is annulled?
	    .illegal
	 endcase
      endof
      ( default )  .op2+src+dest
   endcase
;
\  Given a signed immediate, show it as a displacement
\      Also works for a  call  instruction, which uses
\	   all but its upper two bits for the offset.
: .disp ( simm|call-instruction -- )
   2 <<		\  Convert longword offset to byte offset
   l->n 	\  Make sure it's sign-extended...
   pc@ +  +offset
   dup branch-target!		\  Might advance  max-branch-target
   showaddr
; 
: .disp22 ( -- )
   op-col  d# 22 simm# .disp
;
: .disp19 ( -- )
   d# 19 simm# .disp
;
: .disp16 ( -- )
   0 d# 14 bits d# 20 2 bits d# 14 << or		( n=16bits )
   d# 16	( n wid' )  \  wid=16 which happens to equal wid' (32 - wid)
   sext 	\ Sign extend
   .disp
;
: .sethi  ( -- )
   ." sethi"   op-col  instruction @  d# 10 << n->l (u.) type  .,  .rd
;
: .call  ( -- )
   ." call"  op-col
   instruction @  .disp
   end-found on  false is annulled?
;

\  Extract the condition field of a Bcc, BPcc, FBcc or CBcc instruction
\  For unconditional ("always") branch, check for end of disassembly
: (bra)cond@ ( -- condition-code )
   d# 25 4 bits 			( condition-code )
   dup 8 = if   ?end-found  then	(  )	\  cc = 8 ==> "always"
;

\  Display the "annulled" field (bit 29) of a branch instruction.
\  Also, if the branch that ends the disassembly is annulled,
\  suppress displaying the -- possibly non-valid -- non-executed
\  delay-slot contents.
: .annul  ( -- )  d# 29 bit? dup is annulled?  if  ." ,a"  then  ;

\  Common routine to print the condition-field extracted above,
\  after the appropriate condition-list's string-array has been
\  invoked.  Annul bit (29) is also shared with the Bcc, BPcc,
\  FBcc and CBcc instructions, but BPcc differs from the others
\  in that it uses 19-bit instead of 22-bit displacement.
\
: .(cond) ( p$addr -- )  ". .annul   ;

\  Common part of Bcc and BPcc
: .(bra)cond ( -- )      (bra)cond@   conds .(cond)  ;

: .bcc ( -- )    ." b"  .(bra)cond                     .disp22 ;
: .fbcc ( -- )  ." fb"   (bra)cond@  fconds .(cond)    .disp22 ;

: .predict ( -- ) d# 19 bit?  if  ." ,pt"  else ." ,pn"  then  ;
: .bpcc ( -- )  ." bp" .(bra)cond .predict  op-col .cc .disp19  ;

: .bpr  ( -- )
   ." bpr" d# 25 3 bits .rcond
   .annul .predict
   op-col  .rs1 ., .disp16
;
: .fbpfcc ( -- ) ." fbp %fcc XXX "  ;
: .cbcc ( -- )  ." cb"   (bra)cond@  cconds .(cond)    .disp22 ;

: .format2  ( -- )
   d# 22 3 bits
   case
      0  of  sparc-v9?  if  ." illtrap"  else  ." unimp"  then  endof
      1  of  sparc-v9?  if  .bpcc     else  .illegal  then      endof
      2  of                 .bcc                                endof
      3  of  sparc-v9?  if  .bpr      else  .illegal  then      endof
      4  of                 .sethi                              endof
      5  of  sparc-v9?  if  .fbpfcc   else  .illegal  then      endof
      6  of                 .fbcc                               endof
      7  of  sparc-v9?  if  .illegal  else  .cbcc     then      endof
   endcase
;
: disasm  ( 32b -- )
   instruction !
   d# 30 2 bits
   case
   0  of   .format2   endof
   1  of   .call      endof
   2  of   .class2    endof
   3  of   .class3    endof
   endcase
;
\  Common code for disassembler access, independent of vectoring of  inst@
: (dis1)  ( -- )
   ??cr
   pc@ +offset  showaddr  4 spaces  #out @  start-column !
   pc@l@ disasm  cr
   /l pc@ + pc!
;
: +(dis)  ( -- )
   push-hex
   end-found off  max-branch-target off
   begin   (dis1)  end-found @  exit? or  until
   annulled? 0= if  (dis1)  then	\ Disassemble the delay instruction too
   pop-base
;
: (dis)  ( adr -- )
   pc!
   +(dis)
;

headers
forth definitions
alias disasm disasm
: dis1  ( -- )
   ['] (inst@ is inst@
   (dis1)
;

: +dis  ( -- )
   ['] (inst@ is inst@
   +(dis)
;
: dis  ( adr -- )
   ['] (inst@ is inst@
   (dis)
;

headerless
alias (dis dis
headers

previous previous definitions
