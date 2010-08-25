\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tlbasm.fth
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
id: @(#)tlbasm.fth 1.1 06/02/16
purpose: Implements low level tlb code for sun4v class CPUs
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


\ %o0 = VA
\ %o1 = PA
\ %o2 = Size 0 = 8K, 1 = 64K , 3 = 4M , 5 = 256M
\ %o3 = TTE Mode bits
label setup-itlb-entry
   %o1 d# 64 #pabits -  %o5  sllx
   %o5 %g0    %g0  subcc
   0<  if
   %o1  0 >tte-priv >tte-cv >tte-cp >tte-writable  %o5  or  \ P,CP,CV,W
      %o1  0 >tte-priv >tte-effect >tte-writable  %o5  or  \ P,E,W
   then
   %o5  %o3          %o1  or	\ Other bits
   %o5  %o2          %o1  or    \ Size
   %g0  1            %o2  or
   %o2  d# 63        %o2  sllx	\ V
   %o2  %o1          %o2  or	\ %o2 = TTE
   %g0               %o1  move  \ %o1 = context
   %g0  2            %o3  add   \ %o3 = ITLB
   \ %o0 = Virt
   \ %o1 = context
   \ %o2 = TTE
   \ %o3 = ITLB

   %g0 map-perm-addr-func#  %o5 add  %g0 0 always htrapif

   retl
   nop
end-code

\ %o0 = VA
\ %o1 = PA
\ %o2 = Size 0 = 8K, 1 = 64K , 3 = 4M , 5 = 256M
\ %o3 = TTE Mode bits
label setup-dtlb-entry
   %o1 d# 64 #pabits -  %o5  sllx
   %o5 %g0    %g0  subcc
   0<  if
   %o1  0 >tte-priv >tte-cv >tte-cp >tte-writable  %o5  or  \ P,CP,CV,W
      %o1  0 >tte-priv >tte-effect >tte-writable  %o5  or  \ P,E,W
   then
   %o5  %o3          %o1  or	\ Other bits
   %o5  %o2          %o1  or    \ Size
   %g0  1            %o2  or
   %o2  d# 63        %o2  sllx	\ V
   %o2  %o1          %o2  or	\ %o2 = TTE
   %g0               %o1  move  \ %o1 = context
   %g0  1            %o3  add   \ %o3 = DTLB
   \ %o0 = Virt
   \ %o1 = context
   \ %o2 = TTE
   \ %o3 = DTLB

   %g0 map-perm-addr-func#  %o5 add  %g0 0 always htrapif

   retl
   nop
end-code
