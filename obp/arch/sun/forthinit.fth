\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: forthinit.fth
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
id: @(#)forthinit.fth 1.4 03/06/12 14:13:30
purpose: 
copyright: Copyright 2000-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 value heap-base

: initial-mem ( -- adr,len )
   heap-base prom-main-task over - 
;
' initial-mem is initial-heap

\ In:
\    up, base
\    %o0 = memory base
\    %o1 = memory size or free-memory size if %o2 is non-zero.
\    %o2 = Non-standard layout flag.
\
\    non Zero %o2 means dont compute anything just use %o0,%o1 as base,len
\
\ Out:
\    sp, rp, up, base etc
\
label init-forth-environment
   \ Set the base register
   %g0  %g0		%g0	save

   %i2  %g0		%g0	subcc	\ Use non standard layout?
   0= if
      nop				\ (delay)

      %i0   %i1		%o1	add	\ Top of memory

      pagesize		%l1	set
      RAMsize-start	%l4	set
      ROMsize		%o2	set

      %o1   %o2		%o1	sub	\ remove OBPs dictionary
      %o1   %l4		%o1	sub	\ %o1 = Addr of User Area
      %o1   %l1		%o0	sub	\ %o0 = Addr of locked VPT
      %o0   %i0		%i1	sub	\ Size of unused memory in %i1
   then

   scr sc1 sc2 mutex-try-enter  prom-lock

   \ Clear the initial user segment
[ifdef] PreCleanedMemory

   \  Platforms (currently, only StarCat) that come up with
   \  memory pre-cleaned (e.g., by POST), still dirty-up the
   \  area used for scratch during decompression.
   \
   \  The following only works for platforms that have the
   \  decompression scratch area hard-coded at VA=0 and for
   \  which a range of physical memory -- hard-coded to a size
   \  of 1/2 meg -- extends through the initial user segment
   \  and the initial VPT.
   \
   \  See the platform-specific  reset.fth  file.

   0                    %l3     set
   h# 8.0000            %l2     set
[else]
   RAMbase		%l3	set
   RAMsize-start	%l2	set
[then]

   \  %l3 = base VA   %l2 = size
   begin
      %l2  /n		%l2	subcc
   0= until
      %g0  %l3		%l2	stx		\ Delay slot

   \ Copy the PROM copy of the data segment into RAM,
   \ Including the user area

   base  h# 18		%l3	ldx	\ get the dictionary length
   base  %l3		%l3	add	\ compute the VA
   base  h# 10		%l2	ldx	\ sizeof user segment
   begin
      %l2  /n		%l2	subcc
      %l3  %l2		%l5	ldx
   0= until
      %l5   up		%l2	stx		\ (Delay)

\itc  up  %g0			iflush	\ For t16 this is required.

   \ The User Area is now initialized

   %i0  pageshift	%i0	srlx	\ convert to page#
   'user# hi-memory-base scr	set
   %i0  up		scr	nput	\ Set the memory configuration variable

   %i1  pageshift	%i1	srlx	\ convert to #pages
   'user# hi-memory-size scr	set
   %i1  up		scr	nput	\ Set the memory configuration variable

   up        'user up0		nput	\ Set the up0 user variable

   RAMbase rs-size +	rp	set	\ Initialize the Return Stack Pointer
   rp        'user .rp0		nput	\ Set the rp0 user variable

   rp h# 20		scr	add
   scr  ps-size		scr	add
   scr  'user .sp0		nput	\ Set the sp0 user variable
   scr  /n		sp	add	\ Account for the top of stack register

   sp   /n		scr	add
   'user# heap-base	sc1	set
   scr  up		sc1	nput

   %i7  8			return
   nop					\ (delay)
end-code


