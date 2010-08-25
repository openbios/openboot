\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: diagprint.fth
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
id: @(#)diagprint.fth 1.1 06/02/22
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex

\ %o6 = Count
\ %o3 = String address
\ %o2 = Scratch
label puts
   %o7			%o3	move	\ Return Address
   %o3 8		%o3	add	\ Addr. of the first char.
   %o3 %g0		%o6	ldub	\ Count
[ifdef] VERBOSE-RESET
   begin
      %o6  %g0		%g0	subcc
   0>  while
      %o3  1		%o3	add	\ (delay)
      %o3  %g0		%o2	ldub
      %o4		%o1	move
      %o2		%o0	move
      %g0  h# 61	%o5	add
      %g0  h# 80		always	htrapif
   repeat
      %o6  1		%o6	sub
   %o3  4		%o3	add
[else]
   %o3 %o6		%o3 	add	\ end of string
   %o3  5		%o3	add
[then]   
   %o3  3		%o3	andn
   %o3  %g0		%g0	jmpl
   nop
end-code
alias diag-puts puts

\ %o0 = number
\
\ %o4 = Return Address
\ %o6 = Shift count
\ %o3 = number
\ %o2 = Scratch
label puthex
   %o7			%o4	move	\ Return adr.
[ifdef] VERBOSE-RESET
   h# 3c		%o6	set	\ Shift count
   %o0			%o3	move	\ Number

   begin
      %o3  %o6		%o2	srlx
      %o2  h# 0f	%o2	and
      %o2  h# 0a	%g0	subcc
      %o2  ascii 0	%o0	add
      <  if annul
	 %o2  ascii a h# 0a -  %o0	add
      then
      %g0  h# 61	%o5	add
      %g0  h# 80		always	htrapif

      %o6  h# 0f  %g0  andcc
      0=  if %o6  %g0  %g0  subcc
	 0<>  if
	    ascii .	%o0	move
	    %g0  h# 61	%o5	add
	    %g0  h# 80		always	htrapif
	 then
      then
      %o6  4		%o6	subcc
   <  until
      nop
   h# 20		%o0	move
   %g0  h# 61		%o5	add
   %g0  h# 80			always	htrapif
[then]
   %o4	8		%g0	jmpl
   nop
end-code

headers
transient
also assembler definitions

: $print ( str$ -- )
   puts call nop  ", align
;

: print" ( -- ) \ string"
   puts call nop  ," align
;

: print-cr ( -- )  " "r"n" $print  ;

: print-reg ( reg -- )
   puthex call %o0 move
;

: $diag-print ( str$ -- )
   puts call nop  ", align
;

: diag-print" ( -- ) \ string"
   puts call nop  ," align
;

: diag-print-cr ( -- )  " "r"n" $diag-print  ;

: diag-print-reg ( reg -- )
   puthex call %o0 move
;

resident
previous definitions
