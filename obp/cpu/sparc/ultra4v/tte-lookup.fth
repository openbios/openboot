\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tte-lookup.fth
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
id: @(#)tte-lookup.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ tte-lookup
\ 
\   You *MUST* preserve %o7 before calling this routine.
\   You have %g5 available for this purpose.
\
\   before calling this routine you *MUST* patch the first 4 nops
\   with instructions that result in %g7 having the PA of the VPT root.
\
\ In:
\   %g4 = VA to resolve
\ Out:
\   %g3 = tte or 0.
\   all other registers are trashed, except %g5
\
0 value vpt-patch-pt
label tte-lookup
   nop nop nop nop nop nop
   %g0  1			%g1	sub
   %g1  d# 64 pageshift -	%g2	srlx		\ page mask
   %g0				%g3	move
   %g1  #vabits pageshift - tteshift + %g1  sllx	\ %g1 = vpt-base
   %g4  %g1		 	%g0	subcc
   u<					if
      %g1  pageshift tteshift -	%g6	srax		\ %g6 = vpt
      %g4  pageshift tteshift - 3 * tteshift + %g1 srlx
      %g1  tteshift		%g1	sllx
      %g1  %g2			%g6	and		\ root VPT offset
      %g7  %g6 memory-asi	%g3	ldxa		\ L2 vpt tte
      %g3  %g0			%g0	subcc
      0<  if
	 %g4  pageshift tteshift - 2 * tteshift + %g1 srlx
         %g1  tteshift		%g1	sllx
         %g1  %g2		%g6	and		\ L2 VPT offset
	 %g3  d# 64 #vabits -	%g3	sllx
	 %g3  d# 64 #vabits -	%g3	srlx
	 %g3  %g2		%g7	andn		\ recover PA
         %g7  %g6 memory-asi	%g3	ldxa		\ L1 vpt tte
         %g3  %g0		%g0	subcc
         0<  if
	    %g4  pageshift	%g1	srlx
            %g1  tteshift	%g1	sllx
            %g1  %g2		%g6	and		\ L2 VPT offset
            %g3  d# 64 #vabits - %g3	sllx
	    %g3  d# 64 #vabits - %g3	srlx
	    %g3  %g2		%g7	andn		\ recover PA
	    retl
            %g7  %g6 memory-asi	%g3	ldxa		\ VA tte
         then
      then
   else
      nop
      %g4  %g6		 	%g0	subcc
      u<				if
         %g1  pageshift tteshift - %g6	srax		\ %g6 = vpt-L2
	 %g4  pageshift tteshift - 2 * tteshift + %g1 srlx
	 %g1  tteshift		%g1	sllx
	 %g1  %g2		%g6	and		\ root VPT offset
	 %g7  %g6 memory-asi	%g3	ldxa		\ L2 vpt tte
	 %g3  %g0		%g0	subcc
	 0<  if
	    %g4  pageshift	%g1	srlx
	    %g1  tteshift	%g1	sllx
	    %g1  %g2		%g6	and		\ L2 VPT offset
	    %g3  d# 64 #vabits - %g3	sllx
	    %g3  d# 64 #vabits - %g3	srlx
	    %g3  %g2		%g7	andn		\ recover PA
	    retl
	    %g7  %g6 memory-asi	%g3	ldxa		\ L1 vpt tte
	 then   
      else
         nop
	 %g0  1			%g6	sub
	 %g6  pageshift 1+	%g6	sllx		\ VPT root PA
	 %g4  pageshift		%g1	srlx
	 %g1  pageshift		%g3	sllx
	 %g3  %g6		%g0	subcc		\ in VPT root?
         0= if
	   %g1  tteshift	%g1	sllx		\ miss PFN
           here tte-lookup - is vpt-patch-pt
	   nop						\ TTE patched later!!
	   nop
	   nop
	   nop
	   nop						\ THESE WILL BE SWAPPED
	   retl						\ WATCHOUT!!
	   nop
         then
	 %g1  %g2		%g6	and		\ offset
	 retl
         %g7  %g6 memory-asi	%g3	ldxa		\ L2 vpt tte
      then
   then
   retl
   %g0				%g3	move		\ invalid
end-code

\ we have to assemble/patch the mmu lookup routines
\ this requires that the assembler be available..
\ this is horrible, but the vpt root access is in the fast path, and the tte
\ formation is ugly, so we patch the instructions as efficiently as
\ we can - including the swap of the retl to use the setx delay slot
: setup-root-vpt ( pa -- )
   here >r tte-lookup dp !
   [ also assembler ]
   ( n ) dup %g6 %g7 setx
   tte-lookup vpt-patch-pt + dp !
   >tte-cp >tte-cv >tte-writable >tte-soft >tte-priv >tte-valid
   %g6 %g3 setx
   here /l - dup l@ swap dp ! retl l,
   [ previous ]
   r> dp !
;

