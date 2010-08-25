\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mmu.fth
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
id: @(#)mmu.fth 1.32 05/02/16
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ We define this now, until mixed-page support is ready
[define] MMU-8K-ONLY?

\ Public Interfaces:
\   pgmap@ ( va -- tte|0 )
\   pgmap! ( tte virt -- )
\   set-tte-soft ( tte virt -- tte' )
\   vpt-walker ( acf -- )
\   map-page ( pa.lo pa.hi va -- )
\   unmap-page ( virt -- )
\   map-pages ( pa.lo pa.hi virtual size -- )
\   unmap-pages ( va len -- )
\   >mmu-boundaries ( va len size -- va' len' )
\   >page-boundaries ( va len -- va' len' )

headerless

#vabits d# 64 = if  -1  else  1 #vabits lshift 1-  then  constant va-mask

pageshift tteshift -	constant vptshift
0 1 #vabits pageshift - tteshift + lshift - constant vpt-base
0 vpt-base -		constant vpt-size

\ For example, in a 44 bit va space, the vpt-base is at ffff.fffc.0000.0000
\ The vpt address of a tte mapping any va is found by:
\   apply va-mask to the va
\   shift page bits off va (all adrs in same page correspond to same tte)
\   shift tte bits back on va (each tte is 8 bytes in vpt)
\   add result to vpt-base
\
\ The above method is used to get the tte for both non-vpt and vpt addresses.
\ The lower pages of the vpt itself are mapped by tte's higher in the vpt.
\ The next level of pages in the vpt holding tte's for the first level are
\ themselves mapped by tte's in the vpt-root page at ffff.ffff.ffff.c000.
\ The vpt-root page is not mapped by a vpt entry, it is locked in the dtlb.

\ These two defers are executed during the performance-critical path
\ of mapping, but are not re-vectored at run-time.  They appear to
\ be being defined here as DEFERs either to workaround the lack of
\ forward-definitions, or because their resolutions differ by platform.
\ Arguably, they should be PATCHed-over where they're resolved...

defer allocate-page ( -- pa.lo pa.hi )
defer set-tte-soft ( tte virt -- tte' )  ' drop is set-tte-soft

\ This is a code saving measure, it does not obey any of the standard
\ ABI conventions as it trashes the locals!!  Do not call this routine
\ from outside this file.
\ On entry:
\	tos is holding the VA
\ On exit:
\	scr	= pgmap
\	sc1	= segment
\	sc2	= region
\	sc5	= region-tte
label pgmap-common
   va-mask  sc1		sc2	setx
   tos  sc2		scr	and	\ VA & va-mask

   scr  pageshift	scr	srlx	\ VA -> vpt offset
   vpt-base	sc1	sc3	setx
   scr  tteshift	scr	sllx
   scr	sc3		scr	add	\ pgmap

   scr  sc2		sc1	and
   sc1  pageshift	sc1	srlx
   sc1	tteshift	sc1	sllx
   sc1  sc3		sc1	add	\ vpt-segment

   sc1  sc2		sc5	and
   sc5  pageshift	sc2	srlx
   sc2	tteshift	sc2	sllx
   sc2  sc3		sc2	add	\ vpt-region

   retl
   sc2  %g0		sc5	ldx
end-code

headers

\ this routine returns 0 for an invalid VA.
\ the VPT is scanned from region->segment->pgmap before the
\ access is done.
code pgmap@ ( va -- tte|0 )
   pgmap-common			call
				nop 	\ (delay)
   \ Validate the region
   sc5  %g0		%g0	subcc
   0< if				\ region valid?
      %g0  %g0		tos	add	\ (delay) Invalid

      \ Validate the segment
      sc1  %g0		sc5	ldx
      sc5  %g0		%g0	subcc
      0< if				\ segment valid?
         %g0  %g0	tos	add	\ (delay) Invalid
         scr  %g0	tos	ldx	\ get tte
      then
   then
c;

headerless

\ get vpt address of tte for va
code >vpt ( va -- adr )
   va-mask  sc1		scr	setx
   tos  scr		tos	and
   tos  pageshift	tos	srlx
   vpt-base	sc1	scr	setx
   tos  tteshift	tos	sllx
   tos	scr		tos	add
c;

\ this routine is the primitive pagemap stuffer.
\ If it returns 0 then this segment and region are fine.
\ if the region needs creation then the tte,va,3 and true are returned.
\ if the segment needs updating then tte,va,2,true are returned
\ returning non-zero means it required high level assistance.
code ((pgmap!)) ( tte va -- 0|tte,va,2,-1|tte,va,3,-1 )
   pgmap-common			call
				nop	\ (delay)

   \ Validate the region
   sc5  %g0		%g0	subcc
   0>= if				\ region valid?
      %g0  3		sc4	add	\ (delay) map-region required.
      tos		sp	push
      sc4		sp	push
   else
      %g0  1		tos	sub	\ (delay) map needs assistance

      \ Validate the segment
      sc1  %g0		sc5	ldx
      sc5  %g0		%g0	subcc
      0>= if				\ segment valid?
         %g0  2		sc4	add	\ (delay) map-segment required.
         tos		sp	push
         sc4		sp	push
      else
         %g0 1		tos	sub	\ (delay) map needs assistance

         \ Pop the tte and stuff the entry
         sp		sc4	pop
         %g0  %g0	tos	add	\ All done.
         sc4  scr	%g0	stx	\ store the tte.
      then
   then
c;

: (pgmap!) ( tte va -- )
   recursive				( tte va )
   ((pgmap!)) if			( tte va index )
      over swap				( tte va va index )
      0 ?do >vpt loop			( tte va va' )
      allocate-page			( tte va va' pa.lo pa.hi )
      >tte >tte-soft			( tte va va' tte' )
      swap x!				( tte va )
      (pgmap!)				( )
   then
;

\ From this point onwards we are presenting the higher level MMU routines.
\ No-one should be calling routines defined before this point - except
\ pgmap@, and >vpt

headers

: .vpt ( vpt -- )
   <#
   u# u# u# u# ascii . hold
   u# u# u# u# ascii . hold
   u# u# u# u# ascii . hold
   u# u# u# u#
   u#> type
;

\ root vpt page which is locked in tlb never misses
0 >vpt >vpt >vpt constant vpt-root

: .vpts ( va --  )
   pagesize round-down
   >vpt dup .vpt cr
   >vpt dup .vpt cr
   >vpt .vpt cr
;

headerless

\ NOTE:
\ The final 2drop is patched at RUNTIME by enable-map-flushing
\ this code is in a performance path which is why it is not
\ using a variable/value/defer to switch this feature on/off.
: (common-mapper) ( va tte len -- )
   >r swap						( tte va )
   r@ 0 ?do  2dup i + (pgmap!) pagesize +loop		( tte va )
   nip r>						( va len )
   \ patched to flush-tlb-range
   2drop
;

headers

\ The virtual memory node calls into this routine to 'modify' entries..
: pgmap! ( tte virt -- )
   tuck 				( va tte va )
   set-tte-soft				( va tte' )
   pagesize (common-mapper)		( )
;

headerless

\ round pa.lo and va down
code >tte-boundaries ( pa.lo pa.hi va round -- va pa.lo pa.hi )
   tos  1		scr	sub
   sp			tos	pop			\ VA
   tos  scr		tos	andn			\ VA'
   sp			sc1	pop
   sp			sc2	pop
   sc2  scr		sc2	andn			\ pa.lo'
   tos			sp	push
   sc2			sp	push
   sc1			tos	move
c;

\ round the region to enclose the appropriate page restrictions.
code >mmu-boundaries ( va len size -- va' len' )
   sp			scr	pop		\ len
   sp			sc1	pop		\ va
   tos	1		tos	sub		\ mask
   sc1	tos		sc2	andn		\ round-down
   sc2			sp	push
   scr	sc1		scr	add		\ top VA
   scr  tos		scr	add		\ add size-1
   scr  tos		scr	andn		\ round-down
   scr  sc2		tos	sub
c;

: >page-boundaries ( va len -- va' len' ) pagesize >mmu-boundaries ;

headers

: map-page ( pa.lo pa.hi va -- )
   pagesize >tte-boundaries			( va' pa.lo' pa.hi )
   >tte swap pgmap!				( )
;

headerless

\ this assumes you have correctly aligned all the args!!
: (map-pages) ( pa.lo pa.hi va len -- )
   >r pagesize >tte-boundaries			( va pa.lo pa.hi )
   rot r>					( pa.lo pa.hi va len )
   bounds  ?do					( pa.lo pa.hi )
      2dup i -rot				( pa.lo pa.hi va pa.lo pa.hi )
      >tte					( pa.lo pa.hi va tte )
      over set-tte-soft				( pa.lo pa.hi va tte' )
      swap (pgmap!)				( pa.lo pa.hi )
      swap pagesize + swap			( pa.lo' pa.hi )
   pagesize +loop				( pa.lo' pa.hi )
   2drop					( )
;

headers

: unmap-page ( virt -- )
   dup pgmap@ 0 >tte-valid invert and over pgmap!  ( virt )
   flush-cache-page			      (  )
;

headerless

depend-load MMU-8K-ONLY? ${BP}/cpu/sparc/ultra/mmu-policy/8k-pages.fth

headerless

\ Call this once OBPs internal mappings are complete, this will then
\ enable the tlb flushing code for mapping.
\ We use patch because this code is all in the performance path.
: enable-map-flushing ( -- )
   ['] flush-tlb-range ['] 2drop		( acf1 acf2 )
   2dup						( acf1 acf2 acf1 acf2 )
   ['] (common-mapper) (patch			( acf1 acf2 )
   ['] map-pages (patch				( )
;

transient
alias deallocate-segment  drop  ( vadr -- )
alias ?allocate-segment   drop  ( vadr -- )
resident

headerless
: (.map)  ( vadr tte -- )
   dup tte>size            ( vadr tte size )
   rot dup ." VA:" .x cr   ( tte size vadr )
   swap 1- and             ( tte offset )
   over  .tlb  cr          ( tte offset )
   over tte>  drop  or     ( tte padr )
   swap valid-tte?  if     ( padr )
      ." PA:" .x           (  )
   else                    ( padr )
      ." Invalid"  drop    (  )
   then                    (  )
;

\ We set this to change the default translation behaviour so we can
\ reuse the same vpt-walker for .trans and the translation property.
\ This defer is set by any map activity; it is critical to performance.
\ Speeding up the application of IS to a kernel native defer shows up
\ here as a significant performance win.
defer vpt-data-fn ( ?? va len tte -- ?? ) ' 3drop is vpt-data-fn

struct
   /x  field >vpt-va
   /x  field >vpt-size
   /x  field >vpt-tte
constant /prev-vpt-data

/prev-vpt-data ualloc user prev-vpt-data

: vpt-data@ ( -- a b c )
   prev-vpt-data >r
   r@ >vpt-va x@
   r@ >vpt-size x@
   r> >vpt-tte x@
;
: vpt-data! ( a b c -- )
   prev-vpt-data >r
   r@ >vpt-tte x!
   r@ >vpt-size x!
   r> >vpt-va x!
;

: prev-tte-invalid ( -- )	0 prev-vpt-data >vpt-tte x! ;
: prev-tte-valid? ( -- flag )	prev-vpt-data >vpt-tte x@ valid-tte? ;

: (vpt-pgmap) ( va -- )
   pagesize bounds do				( )
      i x@ valid-tte? if			( )
         i vpt-base -				( offset )
         vptshift lshift			( va )
         i x@ dup tte>size swap			( va size tte )
         2 pick 2 pick 1- and if		( va size tte )
            \ tte-size overlaps va so we merge
            3drop				( )
         else					( va size tte )
            prev-tte-valid? if			( va size tte )
               prev-vpt-data >r			( va size tte )
               2 pick r@ >vpt-va x@ -		( va size tte n )
               over tte> drop			( va size tte n pa.lo )
               r@ >vpt-tte x@ tte> drop -	( va size tte n n )
               = if				( va size tte )
                  \ merge sizes, because va and pa are contiguous.
                  drop nip			( size )
                  r> >vpt-size +!		( )
               else				( va size tte )
                  2>r >r			( )
                  vpt-data@ vpt-data-fn		( va size tte )
                  r> 2r> vpt-data!		( )
                  r> drop			( )
               then				( )
            else				( va size tte )
               \ save this va,tte for merging
               vpt-data!			( )
            then				( )
         then					( )
      else					( )
         prev-tte-valid? if			( )
            vpt-data@ vpt-data-fn		( )
         then					( )
         prev-tte-invalid			( )
      then					( )
   /x +loop					( )
;

: (vpt-segment) ( va -- )
   pagesize bounds do				( )
      i x@ valid-tte? if			( )
         i vptshift lshift			( va )
         (vpt-pgmap)				( )
      then					( )
   /x +loop					( )
;

\ walk the vpt and execute acf with va,len,tte on the stack
\ beginning at the vpt-root, iterate over each tte in that page;
\ for each valid tte, go to the page it maps and iterate over those tte's;
\ for each valid tte in those pages, again descend to the mapped page
\ and iterate over those tte's; these last map the remaining address space
: vpt-walker ( acf -- )
   is vpt-data-fn				( )
   prev-tte-invalid				( )
   vpt-root pagesize bounds do			( )
      i x@ valid-tte? if
         i vptshift lshift			( va )
         (vpt-segment)				( )
       then
   /x +loop
   prev-tte-valid? if
      vpt-data@ vpt-data-fn
   then
;
