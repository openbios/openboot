\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: contigph.fth
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
id: @(#)contigph.fth 1.7 95/08/17
purpose: 
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ contiguous-range scans the given address range to ensure that the
\ mappings contained within that range are physically contiguous.
\ If not, the length is reduced so that the mappings within the reduced
\ range are physically contiguous.  This is an error check, because there
\ is at least one known FCode driver (old ECL frame buffer driver) which
\ attempts to free a larger range than it allocated.

: contiguous-range  ( adr len -- adr len' )
   over >physical  2over bounds  ?do            ( adr len padr space )
      2dup i >physical  d=  0=  if              ( adr len padr space )
         2swap                                  ( padr space adr len )
         diagnostic-mode?  if
	    ." Warning: freeing a range of virtual memory that is not " cr
	    ." mapped to physically-contiguous pages." cr
	    ." Start address " over .h  ." Length " dup .h
	    ." Error address " i .h cr
         then
	 drop                                   ( padr space adr )
         i mmu-pagesize round-down over -       ( padr space adr len' )
         2swap  leave                           ( adr len' padr space )
      then                                      ( adr len padr space )
      swap mmu-pagesize + swap                  ( adr len padr' space )
   mmu-pagesize  +loop                          ( adr len padr space )
   2drop                                        ( adr len )
;
' contiguous-range is check-range
