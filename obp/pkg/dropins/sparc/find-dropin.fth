\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: find-dropin.fth
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
id: @(#)find-dropin.fth 1.1 02/08/22
purpose: 
copyright: Copyright 1999-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

inline-struct? on
struct
   /l field >di-magic
   /l field >di-size
   /l field >di-sum
   /l field >di-exp  \ Reserved
d# 16 field >di-name
    0 field >di-image
constant /lvl1-hdr
inline-struct? off

[ifdef] dropin-debug?
label di-print-addr
   %l5			%o0	move
   %g0  %g0		%g0	save
   print" "r"nScan addr: "
   %i0				print-reg
   %i7  8			return
   nop
end-code

label di-print-name
   %g0  %g0		%g0	save
   ttya-pa %o2		%l7	setx

   %l7			%o1	move
   bpemit			call
   ascii [		%o0	move		\ (delay)

   %l7			%o1	move
   bpemit			call
   %i2			%o0	move		\ (delay)

   %l7			%o1	move
   bpemit			call
   ascii !		%o0	move		\ (delay)

   %l7			%o1	move
   bpemit			call
   %i3			%o0	move		\ (delay)

   %l7			%o1	move
   bpemit			call
   ascii ]		%o0	move		\ (delay)

   %i7  8			return
   nop
end-code
[then]

\ In
\   %o0 = di-name
\   %o1 = start-addr
\ Out
\   %o0 = addr of dropin-header or 0 if not found.
label find-drop-in
   %g0  %g0		%g0	save

   %i1			%l5	move		\ start address
   h# 4f424d44		%l6	set		\ dropin magic
   %g0  %g0		%l7	add		\ found address
   begin
      \ Skip trailing 01 bytes.
      begin
         %l5  0 	%o0	ldub
         %o0  h# 01	%g0	subcc
      0<> until
         %l5  1		%l5	add
      %l5  3		%l5	andn		\ Force alignment
[ifdef] dropin-debug?
      di-print-addr		call	nop
[then]
      %l5  0 >di-magic	%l4	ld		\ get magic
      %l5  0 >di-size	%l1	ld		\ get size
      %l4  %l6		%g0	subcc
      0= if
         %g0  %g0	%g0	subcc		\ (delay) mark exit

         \ Check the name
         %l5  0 >di-name %o0	add		\ Dropin name
         %i0  %g0	%o1	add		\ SRC name
         %g0  d# 16	%o4	add		\ max len.
         begin
            %o0  0	%o2	ldub
            %o1  0	%o3	ldub
[ifdef] dropin-debug?
            di-print-name	call	nop
[then]
            %o2  %o3	%g0	subcc
            0= if
               %g0  %g0  %g0	subcc		\ (delay) no match exit
               %o2  %g0  %g0	subcc
               0= if
                  %o4 1	%o4	subcc		\ decr and continue (delay)
                  %l5	%l7	move		\ name matched.
                  %g0  %g0  %g0	subcc		\ force exit.
               then
            then
            %o0  1	%o0	add
         0= until
	    %o1  1	%o1	add

         %l7  %g0	%g0	subcc		\ name matched?
         0<> if
            %g0  1	%g0	subcc		\ continue
            %g0  %g0	%g0	subcc		\ End
         then
      then
      %l5  /lvl1-hdr	%l5	add		\ Skip the header.
   0= until
      %l5  %l1		%l5	add		\ Skip the data to next dropin.

   %l7	%g0		%i0	add
   %i7  8			return
   nop      
end-code
