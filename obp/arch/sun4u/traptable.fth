\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: traptable.fth
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
id: @(#)traptable.fth 1.18 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

also assembler definitions

headers
transient

: window-spill ( -- )
   %o6  1  %g0 andcc				\ 1
   0<>  if  %g0 h# 80  wrasi			\ 2,3
      %l0  %o6 V9_SP_BIAS d#  0 na+  %asi  stxa	\ 4
      %l1  %o6 V9_SP_BIAS d#  1 na+  %asi  stxa	\ 5
      %l2  %o6 V9_SP_BIAS d#  2 na+  %asi  stxa	\ 6
      %l3  %o6 V9_SP_BIAS d#  3 na+  %asi  stxa	\ 7
      %l4  %o6 V9_SP_BIAS d#  4 na+  %asi  stxa	\ 8
      %l5  %o6 V9_SP_BIAS d#  5 na+  %asi  stxa	\ 9
      %l6  %o6 V9_SP_BIAS d#  6 na+  %asi  stxa	\ 10
      %l7  %o6 V9_SP_BIAS d#  7 na+  %asi  stxa	\ 11
      %i0  %o6 V9_SP_BIAS d#  8 na+  %asi  stxa	\ 12
      %i1  %o6 V9_SP_BIAS d#  9 na+  %asi  stxa	\ 13
      %i2  %o6 V9_SP_BIAS d# 10 na+  %asi  stxa	\ 14
      %i3  %o6 V9_SP_BIAS d# 11 na+  %asi  stxa	\ 15
      %i4  %o6 V9_SP_BIAS d# 12 na+  %asi  stxa	\ 16
      %i5  %o6 V9_SP_BIAS d# 13 na+  %asi  stxa	\ 17
      %i6  %o6 V9_SP_BIAS d# 14 na+  %asi  stxa	\ 18
      %i7  %o6 V9_SP_BIAS d# 15 na+  %asi  stxa	\ 19
   else  nop					\ 20,21
      %o6  0           %o6   srl		\ 22
      %l0  %o6 0 /n*   %asi  stda		\ 23
      %l2  %o6 1 /n*   %asi  stda		\ 24
      %l4  %o6 2 /n*   %asi  stda		\ 25
      %l6  %o6 3 /n*   %asi  stda		\ 26
      %i0  %o6 4 /n*   %asi  stda		\ 27
      %i2  %o6 5 /n*   %asi  stda		\ 28
      %i4  %o6 6 /n*   %asi  stda		\ 29
      %i6  %o6 7 /n*   %asi  stda		\ 30
   then
   saved					\ 31
   retry					\ 32
;

: window-fill ( -- )
   %o6  1  %g0 andcc				\ 1
   0<>  if  %g0 h# 80  wrasi			\ 2,3
      %o6 V9_SP_BIAS d#  0 na+  %asi  %l0  ldxa	\ 4
      %o6 V9_SP_BIAS d#  1 na+  %asi  %l1  ldxa	\ 5
      %o6 V9_SP_BIAS d#  2 na+  %asi  %l2  ldxa	\ 6
      %o6 V9_SP_BIAS d#  3 na+  %asi  %l3  ldxa	\ 7
      %o6 V9_SP_BIAS d#  4 na+  %asi  %l4  ldxa	\ 8
      %o6 V9_SP_BIAS d#  5 na+  %asi  %l5  ldxa	\ 9
      %o6 V9_SP_BIAS d#  6 na+  %asi  %l6  ldxa	\ 10
      %o6 V9_SP_BIAS d#  7 na+  %asi  %l7  ldxa	\ 11
      %o6 V9_SP_BIAS d#  8 na+  %asi  %i0  ldxa	\ 12
      %o6 V9_SP_BIAS d#  9 na+  %asi  %i1  ldxa	\ 13
      %o6 V9_SP_BIAS d# 10 na+  %asi  %i2  ldxa	\ 14
      %o6 V9_SP_BIAS d# 11 na+  %asi  %i3  ldxa	\ 15
      %o6 V9_SP_BIAS d# 12 na+  %asi  %i4  ldxa	\ 16
      %o6 V9_SP_BIAS d# 13 na+  %asi  %i5  ldxa	\ 17
      %o6 V9_SP_BIAS d# 14 na+  %asi  %i6  ldxa	\ 18
      %o6 V9_SP_BIAS d# 15 na+  %asi  %i7  ldxa	\ 19
   else  nop					\ 20,21
      %o6 0            %o6  srl			\ 22
      %o6 0 /n*  %asi  %l0  ldda		\ 23
      %o6 1 /n*  %asi  %l2  ldda		\ 24
      %o6 2 /n*  %asi  %l4  ldda		\ 25
      %o6 3 /n*  %asi  %l6  ldda		\ 26
      %o6 4 /n*  %asi  %i0  ldda		\ 27
      %o6 5 /n*  %asi  %i2  ldda		\ 28
      %o6 6 /n*  %asi  %i4  ldda		\ 29
      %o6 7 /n*  %asi  %i6  ldda		\ 30
   then
   restored					\ 31
   retry					\ 32
;

: level-interrupt ( -- )
   save-state always brif nop
;

: set-RED-vector ( vector# vadr -- )
   over  begin-trap    ( vector# offset )
   here - 2 >> h# 3080.0000 + l,
   nop nop
   ( vector# )
   dup dup 1+ end-trap  2drop
;

previous definitions

assembler alias set-vector set-vector  forth

resident

\ Set all Trap Types to save-state
\ Selected Trap Types will be replaced later
h# 400   2  do  i save-state set-vector  loop

\ 001 Power On Reset
\ 002 Watchdog Reset
\ 003 XIR
\ 004 SIR
\ 005 RED
\ 006 Reserved
h# 007 begin-trap
( 01 )  nop
( 02 )  nop
( 03 )  nop
( 04 )  nop
( 05 )  nop
( 06 )  nop \ prom-cold-code always brif
( 07 )  nop
( 08 )  nop
h# 008 end-trap
\ 006 .. 007 *** Reserved
\ 008        Instruction Access Exception
\ 009        Instruction Access MMU Miss   *** Unused in Sun4u
\ 00a        Instruction Access Error
\ 00b .. 00f *** Reserved
\ 010        Illegal Instruction
\ 011        Privileged Opcode
\ 012        Unimplemented LDD
\ 013        Unimplemented STD
\ 014 .. 01f *** Reserved
\ 020        FP Disabled
\ 021        FP Exception IEEE 754
\ 022        FP Exception Other
\ 023        Tag Overflow
h# 024 begin-trap	\ Clean Window
   %l0          rdcleanwin
   %l0 1   %l0  add
   %l0 0        wrcleanwin
   %g0 0   %l0  or
   %g0 0   %l1  or
   %g0 0   %l2  or
   %g0 0   %l3  or
   %g0 0   %l4  or
   %g0 0   %l5  or
   %g0 0   %l6  or
   %g0 0   %l7  or
   %g0 0   %o0  or
   %g0 0   %o1  or
   %g0 0   %o2  or
   %g0 0   %o3  or
   %g0 0   %o4  or
   %g0 0   %o5  or
   %g0 0   %o6  or
   %g0 0   %o7  or
   retry
   align80
h# 028 end-trap	\ Clean Window
\ 028        Division by Zero
\ 029        Internal Processor Error
\ 030        Data Access Exception
\ 031        Data Access MMU Miss   *** Unused in Sun4u
\ 032        Data Access Error
\ 033        Data Access Protection  *** Unused in Sun4u
\ 034        Memory Address not Aligned
\ 035        LDDF Memory Address not Aligned
\ 036        STDF Memory Address not Aligned
\ 037        Privileged Action
\ 038        LDQF Memory Address not Aligned
\ 039        STQF Memory Address not Aligned
\ 03a .. 03f *** Reserved
\ 040        Async Data Error
h# 041 begin-trap  level-interrupt h# 042 end-trap \ Interrupt Level 1
h# 042 begin-trap  level-interrupt h# 043 end-trap \ Interrupt Level 2
h# 043 begin-trap  level-interrupt h# 044 end-trap \ Interrupt Level 3
h# 044 begin-trap  level-interrupt h# 045 end-trap \ Interrupt Level 4
h# 045 begin-trap  level-interrupt h# 046 end-trap \ Interrupt Level 5
h# 046 begin-trap  level-interrupt h# 047 end-trap \ Interrupt Level 6
h# 047 begin-trap  level-interrupt h# 048 end-trap \ Interrupt Level 7
h# 048 begin-trap  level-interrupt h# 049 end-trap \ Interrupt Level 8
h# 049 begin-trap  level-interrupt h# 04a end-trap \ Interrupt Level 9
h# 04a begin-trap  level-interrupt h# 04b end-trap \ Interrupt Level 10
h# 04b begin-trap  level-interrupt h# 04c end-trap \ Interrupt Level 11
h# 04c begin-trap  level-interrupt h# 04d end-trap \ Interrupt Level 12
h# 04d begin-trap  level-interrupt h# 04e end-trap \ Interrupt Level 13
h# 04e begin-trap  level-interrupt h# 04f end-trap \ Interrupt Level 14
h# 04f begin-trap  level-interrupt h# 050 end-trap \ Interrupt Level 15
\ 050 .. 05f *** Reserved				512 Bytes
\ 060        Vector Interrupt    *** Sun4u
\ 061        PA Watchpoint       *** Sun4u
\ 062        VA Watchpoint       *** Sun4u
\ 063        Corrected ECC Error *** Sun4u
\ 064 .. 067 Instruction Access MMU Miss  *** Sun4u
\ 068 .. 06b Data Access MMU Miss         *** Sun4u
\ 06c .. 06f Data Access Protection       *** Sun4u
\ 070 .. 07f Fast ECC Error               *** Sun4u ( US-III )
h# 080  begin-trap  window-spill  h# 084 end-trap  \ Spill 0 Normal
h# 084  begin-trap  window-spill  h# 088 end-trap  \ Spill 1 Normal
h# 088  begin-trap  window-spill  h# 08c end-trap  \ Spill 2 Normal
h# 08c  begin-trap  window-spill  h# 090 end-trap  \ Spill 3 Normal
h# 090  begin-trap  window-spill  h# 094 end-trap  \ Spill 4 Normal
h# 094  begin-trap  window-spill  h# 098 end-trap  \ Spill 5 Normal
h# 098  begin-trap  window-spill  h# 09c end-trap  \ Spill 6 Normal
h# 09c  begin-trap  window-spill  h# 0a0 end-trap  \ Spill 7 Normal
h# 0a0  begin-trap  window-spill  h# 0a4 end-trap  \ Spill 0 Other
h# 0a4  begin-trap  window-spill  h# 0a8 end-trap  \ Spill 1 Other
h# 0a8  begin-trap  window-spill  h# 0ac end-trap  \ Spill 2 Other
h# 0ac  begin-trap  window-spill  h# 0b0 end-trap  \ Spill 3 Other
h# 0b0  begin-trap  window-spill  h# 0b4 end-trap  \ Spill 4 Other
h# 0b4  begin-trap  window-spill  h# 0b8 end-trap  \ Spill 5 Other
h# 0b8  begin-trap  window-spill  h# 0bc end-trap  \ Spill 6 Other
h# 0bc  begin-trap  window-spill  h# 0c0 end-trap  \ Spill 7 Other
h# 0c0  begin-trap  window-fill   h# 0c4 end-trap  \ Fill 0 Normal
h# 0c4  begin-trap  window-fill   h# 0c8 end-trap  \ Fill 1 Normal
h# 0c8  begin-trap  window-fill   h# 0cc end-trap  \ Fill 2 Normal
h# 0cc  begin-trap  window-fill   h# 0d0 end-trap  \ Fill 3 Normal
h# 0d0  begin-trap  window-fill   h# 0d4 end-trap  \ Fill 4 Normal
h# 0d4  begin-trap  window-fill   h# 0d8 end-trap  \ Fill 5 Normal
h# 0d8  begin-trap  window-fill   h# 0dc end-trap  \ Fill 6 Normal
h# 0dc  begin-trap  window-fill   h# 0e0 end-trap  \ Fill 7 Normal
h# 0e0  begin-trap  window-fill   h# 0e4 end-trap  \ Fill 0 Other
h# 0e4  begin-trap  window-fill   h# 0e8 end-trap  \ Fill 1 Other
h# 0e8  begin-trap  window-fill   h# 0ec end-trap  \ Fill 2 Other
h# 0ec  begin-trap  window-fill   h# 0f0 end-trap  \ Fill 3 Other
h# 0f0  begin-trap  window-fill   h# 0f4 end-trap  \ Fill 4 Other
h# 0f4  begin-trap  window-fill   h# 0f8 end-trap  \ Fill 5 Other
h# 0f8  begin-trap  window-fill   h# 0fc end-trap  \ Fill 6 Other
h# 0fc  begin-trap  window-fill   h# 100 end-trap  \ Fill 7 h# Other
\ 100 .. 17f Trap Instruction
h# 170 begin-trap
( 00 )	done
( 01 )	nop
( 02 )	nop
( 03 )	nop
h# 171 end-trap
\ 180 .. 1ff *** Reserved 		4 K
\ 200 .. 201 *** Unused ( V8 Reset )
\ 201 .. 209 *** Unused
\ 20a        Instruction Access Error
\ 20b .. 231 Unused					1 K
\ 232        Data Access Error
\ 233 .. 260 Unused					1 K
\ 260        Vector Interrupt    *** Sun4u
\ 261        PA Watchpoint       *** Sun4u
\ 262        VA Watchpoint       *** Sun4u
\ 263        Corrected ECC Error *** Sun4u
\ 264 .. 267 Instruction Access MMU Miss  *** Sun4u
h# 264 begin-trap
( 01 )   immu-miss-trap always brif annul
( 02 )   nop
( 03 )   nop
( 04 )   nop
( 05 )   nop
( 06 )   nop
( 07 )   nop
( 08 )   nop
h# 268 end-trap
\ 26c .. 26f Data Access Protection       *** Sun4u
\ 070 .. 07f Fast ECC Error               *** Sun4u ( US-III )
\ 280 .. 2bf Unused  ( Window Spill )			2 K
\ 2c0 .. 2ff Unused  ( Window Fill )			2 K
\ 300 .. 3ff Unused  ( Trap Instruction )		8 K

headers

[ifdef] SUN4V
h# 009 immu-miss-trap set-vector
h# 031 dmmu-miss-trap set-vector
[then]

h# 064 immu-miss-trap set-vector

[ifdef] SUN4V
h# 068 dmmu-miss-trap set-vector
h# 268 dmmu-miss-trap set-vector
[else]
h# 068 dmmu-miss-trap-TL=1 set-vector
h# 268 dmmu-miss-trap-TL>1 set-vector
[then]
