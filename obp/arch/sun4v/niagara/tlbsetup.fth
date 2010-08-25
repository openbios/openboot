\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tlbsetup.fth
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
id: @(#)tlbsetup.fth 1.1 06/02/16
purpose: Implements low level tlb code for sun4v class CPUs
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
\ %o0 = Memory base addr
\ %o1 = Memory size
label  setup-i/d-tlbs

   %g0 0        %g0   save

   %i0			%o0	move	\ %o0: VA = membase
   %i0			%o1	move	\ %o1: PA = membase
   %g0  3		%o2	add	\ %o2: size = 4M
   setup-itlb-entry		call
   %g0  0		%o3	add	\ %o3: Mode = none

   %i0			%o0	move	\ %o0: VA = membase
   %i0			%o1	move	\ %o1: PA = membase
   %g0  3		%o2	add	\ %o2: size = 4M
   setup-dtlb-entry		call
   %g0  0		%o3	add	\ %o3: Mode = none

   monvirtbase		%o0	set	\ %o0: VA = f000.0000
   %i0			%o1	move	\ %o1: PA = membase
   %g0  3		%o2	add	\ %o2: size = 4M
   setup-itlb-entry             call
   %g0  0		%o3	add	\ %o3: Mode = none

   RAMbase		%o0	set	\ %o0: VA = RAMbase
   2meg RAMsize-start - %o1	set
   %i0  %o1		%o1	add	\ %o1: PA = membase + 2M - 64K
   %g0  1		%o2	add	\ %o2: Size = 64K
   setup-dtlb-entry             call
   %g0  0		%o3	add	\ %o3: Mode = none

   monvirtbase		%o0	set	\ %o0: VA = f000.0000
   %i0			%o1	move	\ %o1: PA = membase
   %g0  3		%o2	add	\ %o2: size = 4M
   setup-dtlb-entry             call
   %g0  0		%o3	add	\ %o3: Mode = none

   ret
   %g0 %g0 %g0 restore

end-code
