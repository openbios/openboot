\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: reset-dropin.fth
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
id: @(#)reset-dropin.fth 1.2 03/08/20
purpose: 
copyright: Copyright 2001-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

[ifnexist] trace-me
alias trace-me drop
[then]

\ In
\   %o0 = ptr to name
\   %o1 = base-addr to start search
\   %o2 = destination
\   %o3 = 0 = dont copy before decompress, else copy data here first
\   %o4 != 0 verify dropin checksum
\ Out:
\   %o0 = 0 for not found, otherwise it is the #bytes copied (rounded to 8 byte
\         alignment.
\

label find&copy-dropin
   %g0  %g0		%g0	save

   %i0			%o0	move
   find-drop-in			call
   %i1			%o1	move
   %o0  %g0		%g0	subcc
   0=  if
      %o0  %g0		%l7	add		\ (delay)
      print" Can't start: No image found"
      %g0  %g0		%i0	add		\ failed.
      %i7  8			return
				nop
   then

[ifdef] dropin-checksum?
   %i4  %g0		%g0	subcc		\ Checksum?
   0<> if
      %l7  0		%l0	add		\ data
      diag-print" "r"nDropin checksum: "
      %l7  0 >di-sum	%l1	ld		\ SUM
      %l7  0 >di-size	%l2	ld		\ size
      %l2  /lvl1-hdr	%l2	add		\ include the header
      %g0  %l1		%l3	sub		\ check
      begin
         %l2  2		%l2	subcc
         %l0  %l2	%l4	lduh
      0= until
         %l4  %l3	%l3	add

      h# ffff		%l4	set
      begin
         %l3  %l4	%l5	and		\ low bits
         %l3  d# 16	%l6	srl
         %l6  %g0	%g0	subcc
      0= until
         %l6  %l5	%l3	add		\ (delay) fold sum

      %l3  %l4		%g0	subcc		\ sum = 0xffff?
      0= if
         %l3  %l4	%l3	xor		\ (delay) invert
         %l4  %g0	%l3	add		\ sum = 0xffff
      then
      %l3  %l1		%g0	subcc
      0<> if
         nop
         diag-print" failed"
         print" "r"nCan't start: image is corrupted"r"n"
         %g0  %g0	%g0	add
         %i7  8			return
				nop
      then
      diag-print" OK"
   then
[then]

[ifdef] dropin-debug?
   print" "r"nFind dropin: "
			%i0	print-reg
			%i1	print-reg
			%i2	print-reg
			%i3	print-reg
			%i4	print-reg
			%l7	print-reg
		
[then]
   
   diag-print" "r"nFind dropin"

   %l7  0 >di-image	%l0	add		\ addr of first data word
   %l0  0		%o0	ld		\ get magic
   h# 434f4d50		%o1	set		\ COMP magic
   %o0  %o1		%g0	subcc
   0= if
      %i3  %g0		%g0	subcc		\ (delay) relocate?
      0<> if
         %l0  4		%l1	ld		\ (delay) get comp size
         %l1  h# 10	%l2	add		\ copy size
         %l2  3		%l2	add
         %l2  3		%l2	andn		\ round-up
         begin
            %l2  4	%l2	subcc
            %l0  %l2	%l3	ld
         0= until
            %l3  %i3	%l2	st
         %i3  %g0	%l0	add		\ Use copy as SRC
         diag-print" , (copied)"
      then
      diag-print" , Decompressing "
      %l0  h# 10	%o0	add		\ Skip to Data
      %l1  0		%o1	add		\ get size
      " decompress"		$acall
      %i2 0		%o2	add		\ (delay)

      " output"		%o0	$set-external
      %o0  %g0		%l0	lduw
      %l0  %i2		%i0	sub
   else
      nop
      diag-print" , Copying "
      %l0  0		%o0	add		\ Skip to Data
      %l7  0 >di-size	%l5	ld		\ get size
      %l5  d# 15	%l3	add		\ Size
      %l3  d# 15	%l3	andn		\ Size rounded Up.
      %l3  /lvl1-hdr	%o2	add		\ Add header size.
      %i2  %g0		%o1	add		\ dest
      begin
         %o2  /l	%o2	subcc
         %o0  %o2	%o3	ld
      0= until
         %o3	   %o1	%o2	st
      %l3  0		%i0	add		\ data size for printing

[ifdef] verify-dropin-copy?
      diag-print" (verify) "
      %l7  /lvl1-hdr	%l0	add		\ src data
      %i2  /lvl1-hdr	%l1	add
      %l7  0 >di-size	%l5	ld		\ size
      %g0  1		%l6	add
      %l5  4		%l5	sub
      begin
         %l0  %l5	%l3	ld
         %l1  %l5	%l4	ld
         %l3  %l4	%g0	subcc
         0<> if
            %l5  %g0	%g0	subcc
            %l6  1	%g0	subcc		\ exit
         then
      0= until
         %l5  4		%l5	sub
      %l6  %g0		%g0	subcc
      0= if
         nop
         print" failed: @ "
         %l5  print-reg
         %l3  print-reg
         %l4  print-reg
      then
[then]

   then
   diag-print" Done, Size "
   %i0				diag-print-reg

   %i7  8			return
   nop
end-code
