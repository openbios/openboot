\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mmumiss.fth
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
id: @(#)mmumiss.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

0 >mmu-defer per-cpu-defer: va>tte-data

headerless

: null-va>tte-data ( vadr ctx -- false )  2drop false  ;

stand-init: Initialising the per CPU miss handler
   ['] null-va>tte-data  ['] va>tte-data 3 perform-action
;

: va>tte-installed?  ( -- flag )
   addr va>tte-data
   dup x@ 0<> swap
   token@ ['] null-va>tte-data  <> and
;

: prom-virt? ( vadr -- flag )
   dup monvirtbase RAMtop between  ( vadr flag )
   swap vpt-base u>= or        ( flag )
;
: (set-tte-soft ( tte virt -- tte' )
   prom-virt?  if  >tte-soft  then
;
' (set-tte-soft is set-tte-soft

: find-prom-tte ( virtual -- phys-lo phys-hi )
   dup pgmap@  dup valid-tte?  if  ( va tte )
      tuck tte>size 1- and     ( tte offset )
      s>d rot tte> d+          ( phys-lo phys-hi )
   else                        ( tte )
      drop -1 -1               ( -1 -1 )
   then                        ( phys-lo phys-hi )
;

headers
: find-client-tte ( vadr context# -- tte vadr' true -or- false )
   dup 0=  if			   ( vaddr context# )
      over  vpt-base u>=  if  2drop false  exit  then
   then				   ( vaddr context# )

   va>tte-installed?  if           ( vadr context# )
      2dup  va>tte-data  if        ( vadr context# tte )
	 rot swap dup tte>size     ( context# vadr tte size )
	 rot swap round-down       ( context# tte vadr )
	 \ Merge VA and CTX#
	 rot or                    ( tte vadr" )
      else                         ( vadr context# )
	 2drop  false  exit
      then                         ( tte vadr )
   else                            ( vadr context# )
      \ We can't handle contexts other than 0
      if  drop false  exit  then   ( vadr )
      dup pgmap@ tuck valid-tte?  0=  if      ( tte vadr )
	 2drop false  exit
      then                         ( tte vadr )
   then  true                      ( tte vadr true )
;

headerless
: (>physical) ( virt -- phys-lo phys-hi )
   dup prom-virt?  if  find-prom-tte exit  then
   dup 0  find-client-tte  if ( virt tte virt'  )
      drop tuck  tte>size     ( tte virt size )
      1-  and                 ( tte offset )
      s>d  rot  tte> d+       ( phys-lo phys-hi )
   else                       ( virt )
      drop -1 -1              ( -1 -1 )
   then                       ( phys-lo phys-hi )
;
' (>physical) is >physical

headers
: map? ( vadr -- )
   dup prom-virt?  if             ( vadr )
      dup pgmap@                  ( vadr tte )
   else                           ( vadr )
      dup 0  find-client-tte  if  ( vadr tte vadr' )
	 drop                     ( vadr tte )
      else                        ( vadr )
	 false                    ( vadr inv-tte )
      then                        ( vadr tte )
   then  (.map)                   (  )
;

headerless
: resolve-immu-miss ( vadr -- ok? )
   va>va,ctx  find-client-tte  if  ( tte vadr )
      itlb-tar-dir!  true          ( ok )
   else                            (  )
      false                        ( flag )
   then                            ( ok? )
;

: resolve-dmmu-miss ( vadr -- ok? )
   va>va,ctx  find-client-tte  if  ( tte vadr )
      dtlb-tar-dir!  true          ( flag )
   else                            (  )
      false                        ( flag )
   then                            ( ok? )
;

code dmmu-miss-return  ( ok? -- )
   tos				%l1	move
   %g0  h# 38			%l5	add
   %l5  %g0  h# 20		%l5	ldxa	\ CPU struct PA
   0 >dmmu-miss-state		%l0	set
   %l0  %l5			%g5	add	\ CPU save area
   %l1				%g0	cmp
   restore-cpu-state		0<>	brif
   %g0				%g4	move
   %g0  2			%g4	add	\ restore and come here
   restore-cpu-state		always	brif
   %g7					rdpc
   %g0  2				wrgl
   0 >dmmu-miss-state		%g1	set
   small-forth-save-state	always	brif
					nop
c;

code immu-miss-return  ( ok? -- )
   tos				%l1	move
   %g0  h# 38			%l5	add
   %l5  %g0  h# 20		%l5	ldxa	\ CPU struct PA
   0 >immu-miss-state		%l0	set
   %l0  %l5			%g5	add	\ CPU save area
   %l1				%g0	cmp
   restore-cpu-state		0<>	brif
   %g0				%g4	move
   %g0  2			%g4	add	\ restore and come here
   restore-cpu-state		always	brif
   %g7					rdpc
   %g0  2				wrgl
   0 >immu-miss-state		%g1	set
   small-forth-save-state	always	brif
					nop
c;

headers
defer dmmu-miss-enter-hook ( adr -- adr )
defer dmmu-miss-exit-hook  ( ok? -- ok? )
defer immu-miss-enter-hook ( adr -- adr )
defer immu-miss-exit-hook  ( ok? -- ok? )
headerless

' noop to dmmu-miss-enter-hook
' noop to dmmu-miss-exit-hook
' noop to immu-miss-enter-hook
' noop to immu-miss-exit-hook

: immu-miss-handler  ( vadr -- )
   immu-miss-enter-hook  ( vadr )
   resolve-immu-miss     ( ok? )
   immu-miss-exit-hook   ( ok? )
   immu-miss-return      (  )
;

: dmmu-miss-handler  ( vadr -- )
   dmmu-miss-enter-hook  ( vadr )
   resolve-dmmu-miss     ( ok? )
   dmmu-miss-exit-hook   ( ok? )
   dmmu-miss-return      (  )
;

label dmmu-miss-start ( -- vadr )
   %g0  h# 38			%g1	add
   %g1  %g0  h# 20		%g1	ldxa		\ CPU struct PA
   0 >dmmu-miss-state		%g5	set
   %g5  %g1			%g5	add		\ DMMU stacks
   %g0				%g6	move		\ Small Save
   save-cpu-state		always	brif
   %g7					rdpc

   \ We are now in a normal TL=0, IE=1, CWP=0 environment
   \ Set up Forth Machine
   0 >dmmu-miss-state		%l0	set
   'body dmmu-miss-handler	%l7	set
   setup-small-forth-engine	always	brif	nop
end-code

label immu-miss-start ( -- vadr )
   %g0  h# 38			%g1	add
   %g1  %g0  h# 20		%g1	ldxa		\ CPU struct PA
   0 >immu-miss-state		%g5	set
   %g5  %g1			%g5	add		\ DMMU stacks
   %g0				%g6	move		\ Small Save
   save-cpu-state		always	brif
   %g7					rdpc

   \ We are now in a normal TL=0, IE=1, CWP=0 environment
   \ Set up Forth Machine
   0 >dmmu-miss-state		%l0	set
   'body immu-miss-handler	%l7	set
   setup-small-forth-engine	always	brif	nop
end-code

headerless

label immu-miss-trap
   %g0  h# 30			%g5	add		\ scratch offset
   %g0  h# 10			%g6	add		\ CONTEXT offset
   %g0  %g5 h# 20		%g4	ldxa		\ MMU INFO PTR
   %g4  %g6 memory-asi		%g1	ldxa		\ Context
   %g0  h# 08			%g6	add		\ FAULT offset
   %g4  %g6 memory-asi		%g4	ldxa		\ %g4 = Fault Address.
   %g1  %g0			%g0	subcc
   immu-miss-start 0<>			brif
   %o7				%g5	move		\ save %o7
   tte-lookup				call
   nop							\ (delay) can use??
   \ %g3 = TTE
   \ %g4 = VA
   %g3	%g0			%g0	subcc
   immu-miss-start 0>=			brif
   %g5				%o7	move		\ restore link
   %g3  d# 59			%g1	sllx		\ soft[0]==1 ?
   immu-miss-start 0>=			brif
   %g3  7			%g1	and		\ (delay)
   %g1  3			%g1	mulx
   %g1  d# 13			%g1	add
   %g4	%g1			%g4	srlx
   %g4  %g1			%g4	sllx		\ VA aligned
   %o0				%g7	move
   %o1				%g6	move
   %o2				%g5	move
   %g4				%o0	move		\ VA
   %g0				%o1	move		\ CTX
   %o3				%g4	move
   %g3				%o2	move		\ TTE
   %g0  2			%o3	add		\ ITLB
   %g0 map-addr-htrap# always		htrapif
   %o0  %g0			%g0	subcc		\ Test error code
   save-state 0<>			brif		\ Abort if non-zero
   nop							\ (delay)
   %g7				%o0	move
   %g6				%o1	move
   %g5				%o2	move
   %g4				%o3	move
					retry
end-code

label dmmu-miss-trap
   %g0  h# 30			%g5	add		\ scratch offset
   %g0  h# 50			%g6	add		\ CONTEXT offset
   %g0  %g5 h# 20		%g4	ldxa		\ MMU INFO PTR
   %g4  %g6 memory-asi		%g1	ldxa		\ Context
   %g0  h# 48			%g6	add		\ FAULT offset 
   %g4  %g6 memory-asi		%g4	ldxa		\ %g4 = Fault Address.
   %g1  %g0			%g0	subcc
   dmmu-miss-start 0<>			brif
   %o7				%g5	move		\ save %o7 (delay)
   tte-lookup				call
   nop							\ (delay) can use??
   \ %g3 = TTE
   \ %g4 = VA
   %g3	%g0			%g0	subcc
   dmmu-miss-start 0>=			brif
   %g5				%o7	move		\ restore link (delay)
   %g3  d# 59			%g1	sllx		\ soft[0]
   dmmu-miss-start 0>=			brif
   %g3  7			%g1	and		\ (delay)
   %g1  3			%g1	mulx
   %g1  d# 13			%g1	add
   %g4	%g1			%g4	srlx
   %g4  %g1			%g4	sllx		\ VA aligned
   %o0				%g7	move
   %o1				%g6	move
   %o2				%g5	move
   %g4				%o0	move		\ VA
   %g0				%o1	move		\ CTX
   %o3				%g4	move
   %g3				%o2	move		\ TTE
   %g0  1			%o3	add		\ DTLB
   %g0 map-addr-htrap# always		htrapif
   %o0  %g0			%g0	subcc		\ Test error code
   save-state 0<>			brif		\ Abort if non-zero
   nop							\ (delay)
   %g7				%o0	move
   %g6				%o1	move
   %g5				%o2	move
   %g4				%o3	move
					retry
end-code
