\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: error-reset.fth
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
id: @(#)error-reset.fth 1.1 06/02/16
purpose: Recover from error resets 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

label error-reset-recovery

   %o7			%g3	move		\ Save return address in %g3

   %g0  h# f                    wrpil
   %g0  4                       wrpstate

   trap-table      %o1        	set
   %o1             0          	wrtba     	\ Take over the tba

   h# ffff		%o1	set
 
   %g0  1 		%o0  	add
   %g0 mmu-on-off-func# %o5  add
   %g4                          rdpc
   %g4	%o1		%g4	and
   h# f000.0000         %o1   	set
   %o1	%g4		%o1	add
   %o1	h# 20		%o1	add 
   %g0 fast-trap#    always  htrapif
   nop			
   nop nop nop nop				\ return to here but
						\ in virtual space
   %g0 0 wrtl

   h# ffff		%o1	set		\ return address 
   %g3	%o1		%g3	and   		\ need to be f000.xxxx
   h# f000.0000         %o1   	set
   %o1	%g3		%g3	add
   %g3  8		%g0	jmpl
				nop		\ (delay)
end-code
