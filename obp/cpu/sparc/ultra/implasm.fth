\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: implasm.fth
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
\ implasm.fth 1.2 01/04/06
purpose: 
copyright: Copyright 1988-2001 Sun Microsystems, Inc.  All Rights Reserved

\ This file can be empty if the processor does not have any implementation
\ specific instructions.


also srassembler definitions

headerless

: set-spit-opf  ( apf -- )  36 set-op2  w@  5 <<  addbits  ;

: sfop  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( frs1 frs2 frd )  ?freg rd  ?freg rs2  ?freg rs
;

: sfop2  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( frs2 frd )  ?freg rd  ?freg rs2 
;

: sfop3  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( frs1 frd )  ?freg rd ?freg rs
;

: sfop4  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( rs1 rs2 rd )  ?ireg rd ?ireg rs2 ?ireg rs
;

: sfop5  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( frs1 frs2 rd )  ?ireg rd ?freg rs2 ?freg rs
;

: sfop6  \ name  ( opcode -- )
   createw,  does>  set-spit-opf  ( frd )  ?freg rd 
;

hex

headers

10 register %pcr
11 register %pic
12 register %dcr
13 register %gsr
14 register %set_softint
15 register %clear_softint
16 register %softint
17 register %tick_cmpr

000 sfop4 edge8				        002 sfop4 edge8l
004 sfop4 edge16			        006 sfop4 edge16l
008 sfop4 edge32			        00a sfop4 edge32l
010 sfop4 array8		                012 sfop4 array16
014 sfop4 array32
018 sfop4 alignaddr			        01a sfop4 alignaddrl
020 sfop5 fcmple16			        022 sfop5 fcmpne16
024 sfop5 fcmple32			        026 sfop5 fcmpne32
028 sfop5 fcmpgt16			        02a sfop5 fcmpeq16
02c sfop5 fcmpgt32			        02e sfop5 fcmpeq32
	                031 sfop  fmul8x16 	                       033 sfop  fmul8x16au
		        035 sfop  fmul8x16al    036 sfop  fmul8sux16   037 sfop  fmul8ulx16 
038 sfop  fmuld8sux16   039 sfop  fmuld8ulx16   03a sfop  fpack32      03b sfop2 fpack16
		        03d sfop2 fpackfix      03e sfop  pdist
048 sfop  faligndata    					       04b sfop  fpmerge
		        04d sfop2 fexpand
050 sfop  fpadd16       051 sfop  fpadd16s      052 sfop  fpadd32      053 sfop  fpadd32s
054 sfop  fpsub16       055 sfop  fpsub16s      056 sfop  fpsub32      057 sfop  fpsub32s
060 sfop6 fzero	        061 sfop6 fzeros	062 sfop  fnor	       063 sfop  fnors
064 sfop  fandnot2      065 sfop  fandnot2s     066 sfop2 fnot2	       067 sfop2 fnot2s
068 sfop  fandnot1      069 sfop  fandnot1s     06a sfop3 fnot1	       06b sfop3 fnot1s
06c sfop  fxor          06d sfop  fxors         06e sfop  fnand	       06f sfop  fnands
070 sfop  fand          071 sfop  fands         072 sfop  fxnor	       073 sfop  fxnors
074 sfop3 fsrc1         075 sfop3 fsrc1s        076 sfop  fornot2      077 sfop  fornot2s
078 sfop2 fsrc2         079 sfop2 fsrc2s        07a sfop  fornot1      07b sfop  fornot1s
07c sfop  for           07d sfop  fors          07e sfop6 fone	       07f sfop6 fones
080 sfop4 shutdown	

overload: shutdown  ( -- )  %g0 %g0 %g0 shutdown ;

previous definitions
