\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: impldis.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)impldis.fth 1.4 06/04/21
purpose: Implementation-dependent disassembler extensions for SpitFire
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

also disassembler also definitions

headerless

string-array spit-gx-logical-ops	\ Op-field - 0x60
(  0 ) ," fzero"	," fzeros"	," fnor"	," fnors"
(  4 ) ," fandnot2"	," fandnot2s"	," fnot2"	," fnot2s"
(  8 ) ," fandnot1"	," fandnot1s"	," fnot1"	," fnot1s" 
(  c ) ," fxor"		," fxors"	," fnand"	," fnands" 
( 10 ) ," fand"		," fands"	," fxnor"	," fxnors" 
( 14 ) ," fsrc1"	," fsrc1s"	," fornot2"	," fornot2s" 
( 18 ) ," fsrc2"	," fsrc2s"	," fornot1"	," fornot1s" 
( 1c ) ," for"		," fors"	," fone"	," fones" 
end-string-array

string-array spit-gx-addsub-ops		\ Op-field - 0x50
(  0 ) ," fpadd16"	," fpadd16s"	," fpadd32"	," fpadd32s"
(  4 ) ," fpsub16"	," fpsub16s"	," fpsub32"	," fpsub32s"
end-string-array

string-array spit-gx-other-ops
(  0 ) ," edge8"	," ???"		," edge8l"	," ???"
(  4 ) ," edge16"	," ???"		," edge16l"	," ???"
(  8 ) ," edge32"	," ???"		," edge32l"	," ???"
(  c ) ," ???"		," ???"		," ???"		," ???"
( 10 ) ," array8"	," ???"		," array16"	," ???"
( 14 ) ," array32"	," ???"		," array16"	," ???"
( 18 ) ," alignaddr"	," ???"		," alignaddrl"	," ???"
( 1c ) ," ???"		," ???"		," ???"		," ???"
( 20 ) ," fcmple16"	," ???"		," fcmpne16"	," ???"
( 24 ) ," fcmple32"	," ???"		," fcmpne32"	," ???"
( 28 ) ," fcmpgt16"	," ???"		," fcmpeq16"	," ???"
( 2c ) ," fcmpgt32"	," ???"		," fcmpeq32"	," ???"
( 30 ) ," ???"		," fmul8x16"	," ???"		," fmul8x16au"
( 34 ) ," ???"		," fmul8x16al"	," fmul8sux16"	," fmul8ulx16"
( 38 ) ," fmuld8sux16"	," fmuld8ulx16"	," fpack32"	," fpack16"
( 3c ) ," ???"		," fpackfix"	," pdist"	," ???"
( 40 ) ," ???"		," ???"		," ???"		," ???"
( 44 ) ," ???"		," ???"		," ???"		," ???"
( 48 ) ," faligndata"	," ???"		," ???"		," fpmerge"
( 4c ) ," ???"		," fexpand"	
end-string-array

string-array spit-rd/wr-asrs		\ Reg-field - 0x10
(  0 ) ," %pcr" 	  ," %pic"	      ," %dcr"		," %gsr"
(  4 ) ," %set_softint"	  ," %clear_softint"  ," %softint"	," %tick_cmpr"
(  8 ) ," %stick"	  ," %stick_cmpr"
end-string-array

: .spit-rdasr ( -- )
   rs1  h# 10 -
   dup   0    3 between 		( indx good1? )
   over  6    9 between or 		( indx good? )
   if
      ." rdasr"  op-col  spit-rd/wr-asrs ".  ., .rd
   else
      drop   .illegal
   then
;
: .spit-wrasr ( -- )
   rd  h# 10 -
   dup   0    9 between 		( indx good? )
   if
      ." wrasr" op-col .src .,  spit-rd/wr-asrs ".
   else
      drop   .illegal
   then
;

: spit-opf ( -- n )  5 9 bits  ;
: .frd ( -- ) rd .freg ;
: .frd-double ( -- )  rd .freg-double ;

\  Print both the given reg and  rd  as floating-doubles
 : .f(reg+rd)-double ( reg -- )
   .freg-double ., .frd-double
;
: .f(rs2+rd)-double ( -- )
   rs2 .f(reg+rd)-double
;
: .frs1.frd ( -- )
   rs1 .freg ., .frd 
;
: .2fregs+frd-double ( -- )
   .frs1rs2 ., .frd-double
;

\  For cases where Bit 0 of opcode distinguishes between
\      single and double op:
 : .3fregs?double ( spit-opf -- )
   1 and  if			\  bit 0 of opcode is 0 then double op
     (  )  .3fregs
   else         ( )
     (  )  .3fregs-double
   then         ( )
;

\   Already tested whether  spit-opf h# 60 h# 7f between
: .spit-gx-logical ( spit-opf -- )
   h# 60 -
   dup spit-gx-logical-ops ". op-col
   case
	    0 of   .frd-double			endof	\ fzero
	    1 of   .frd				endof	\ fzeros
	    6 of       .f(rs2+rd)-double 	endof	\ fnot2
	    7 of   .frsrd			endof	\ fnot2s
	h#  a of   rs1 .f(reg+rd)-double  	endof	\ fnot1
	h#  b of       .frs1.frd		endof	\ fnot1s
	h# 14 of   rs1 .f(reg+rd)-double	endof	\ fsrc1
	h# 15 of       .frs1.frd		endof	\ fsrc1s
	h# 18 of       .f(rs2+rd)-double 	endof	\ fsrc2
	h# 19 of   .frsrd			endof	\ fsrc2s
	h# 1e of   .frd-double			endof	\ fone
	h# 1f of   .frd				endof	\ fones
        dup .3fregs?double
   endcase
;

\   Already tested whether  spit-opf h# 50 h# 57 between
: .spit-gx-addsub ( spit-opf -- )
   h# 50 -
   dup   spit-gx-addsub-ops ". op-col
   .3fregs?double
;

   \  Support routines:  Common-special cases in the  .spit-gx-others  group
   : .spit-gx-others+op ( spit-opf -- )
	 spit-gx-other-ops ". op-col
   ;
   : .spit-gx-fpack ( spit-opf -- )
      .spit-gx-others+op rs2 .freg-double ., .frd
   ;

\  Group routines:  Collect identically-treated "opf" values
\      and handle appropriately.

\  Each of the following four support routines compares the given
\      SpitFire-Floating-OP code value against a known set.
\  If found, the routine prints the corresponding string from the
\       .spit-gx-others  array, "does the right thing" with the rest
\      of field, and returns a  true , telling the caller that it's done.
\  Otherwise, the routine leaves the "OPF" on the stack with a  false
\      and the caller can then proceed to try the next set.

	\   Value:    String:
	\      0 	edge8
	\      2 	edge8l
	\      4 	edge16
	\      6 	edge16l
	\      8 	edge32
	\  h#  a 	edge32l
	\  h# 10 	array8
	\  h# 12 	array16
	\  h# 14 	array32
	\  h# 18 	alignaddr
	\  h# 1a 	alignaddrl
: ?spit-gx-edge/array? ( spit-opf -- spit-opf false | true )
   dup " "( 00 02 04 06 08 0a 10 12 14 18 1a)"
   rot scantochar <> nip if
      .spit-gx-others+op .src ., .rd
      true  exit
   then  false
;

	\   Value:    String:
	\  h# 20 	fcmple16
	\  h# 22 	fcmpne16
	\  h# 24 	fcmple32
	\  h# 26 	fcmpne32
	\  h# 28 	fcmpgt16
	\  h# 2a 	fcmpeq16
	\  h# 2c 	fcmpgt32
	\  h# 2e 	fcmpeq32
: ?spit-gx-fcmp? ( spit-opf -- spit-opf false | true )
   dup " "( 20 22 24 26 28 2a 2c 2e)"
   rot scantochar <> nip if
      .spit-gx-others+op .frs1rs2-double ., .rd
      true  exit
   then  false
;

	\   Value:    String:
	\  h# 33 	fmul8x16au
	\  h# 35 	fmul8x16al
	\  h# 38 	fmuld8sux16
	\  h# 39 	fmuld8ulx16
	\  h# 4b 	fpmerge
: ?spit-gx-2fregs+frd-double? ( spit-opf -- spit-opf false | true )
   dup " "( 33 35 38 39 4b)"
   rot scantochar <> nip if
      .spit-gx-others+op .2fregs+frd-double
      true  exit
   then  false
;

	\   Value:    String:
	\  h# 36 	fmul8sux16
	\  h# 37 	fmul8ulx16
	\  h# 3a 	fpack32
	\  h# 3e 	pdist
	\  h# 48 	faligndata
: ?spit-gx-others+3fregs-double? ( spit-opf -- spit-opf false | true )
   dup " "( 36 37 3a 3e 48)"
   rot scantochar <> nip if
      .spit-gx-others+op .3fregs-double
      true  exit
   then  false
;

: .spit-gx-others ( spit-opf -- )
    ?spit-gx-edge/array?		if exit then
    ?spit-gx-fcmp?			if exit then
    ?spit-gx-2fregs+frd-double? 	if exit then
    ?spit-gx-others+3fregs-double?	if exit then
   dup
   case
	h# 31 of  .spit-gx-others+op
		  rs1 .freg ., .f(rs2+rd)-double	endof	\ fmul8x16
	h# 3b of  .spit-gx-fpack			endof	\ fpack16
	h# 3d of  .spit-gx-fpack			endof	\ fpackfix	
	h# 4d of  .spit-gx-others+op				\ fexpand
		  rs2 .freg ., .frd-double		endof
	.illegal drop
   endcase
;
	
: .spit-impdep1 ( -- )
   spit-opf
   dup        h# 60 h# 7f  between  if
            .spit-gx-logical
   else
      dup     h# 50 h# 57  between  if
            .spit-gx-addsub
      else
         dup      0 h# 4d  between  if
	    .spit-gx-others
	 else
	            h# 80 = if
	      ." shutdown"
	   else
	      .illegal
	   then
	 then
      then
   then
;

: .spit-impdep2 ( -- )
   .illegal
;

: .spit-asi-ea ( -- )
   immasi dup h# c0 h# c5  between
         swap h# c8 h# cd  between  or
      opcode  h# 37 =
   and if 
      ." [" .rs1 ." ]" .rs2 ., 5 8 bits (u.) type
   else
      .ea-sparc
   then
;

' .spit-wrasr    is .impl-wrasr
' .spit-rdasr    is .impl-rdasr
' .spit-impdep1  is .impdep1
' .spit-impdep2  is .impdep2
' .spit-asi-ea   is .impl-asi-ea

previous previous definitions

headers
