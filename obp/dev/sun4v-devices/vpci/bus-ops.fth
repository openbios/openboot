\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: bus-ops.fth
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
id: @(#)bus-ops.fth 1.2 06/05/10
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc  All Rights Reserved

copyright: Use is subject to license terms.

headerless

\ Decode just the 2 "ss" bits which denotes the address space 
: cfg>sstype ( phys.hi -- sstype )  d# 24 rshift  3 and ;

\ Convert phys.hi into actual offset within configuration space
\ For ss=0 encoding,
\	phys.hi encoding:		RRRR0000.bbbbbbbb.dddddfff.rrrrrrrr
\	PCI config space offset:	0000.bbbb.bbbb.dddd.dfff.rrrr.rrrr
\	PCIE config space offset:	bbbb.bbbb.dddd.dfff.RRRR.rrrr.rrrr
\ For other ss types,
\	phys.hi encoding:		nptx00ss.bbbbbbbb.dddddfff.rrrrrrrr
\	PCI config space offset:	bbbb.bbbb.dddd.dfff.0000.rrrr.rrrr

: phys.hi>cfg-offset ( phys.hi -- pci-cfg-offset )
   dup cfg>sstype 0=  if			( phys.hi )
      dup d# 28 >> d# 8 <<                      \ Position RRRR bits
   else
      0
   then
   over h# ff and +				( phys.hi reg# )
   swap h# 00ff.ff00 and 4 << +			( offset )
;

: (map-in) ( pa len -- va ) >r xlsplit r> " map-in" $call-parent  ;

: bus-map-io ( phys.lo phys.mid phys.hi len -- va )
   >r 2drop					( phys.lo ) ( r: len )
   pci-iosize 1- and  pci-iobase +		( pa )
   r> (map-in)					( va ) ( r: )
;

: bus-map-mem  ( phys.lo phys.mid phys.hi len -- va )
   >r 2drop					( phys.lo ) ( r: len )
   -1 and32 pci-mem32base +			( pa )
   r> (map-in)					( va ) ( r: )
;

headers
