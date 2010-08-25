\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: divrem.fth
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
id: @(#)divrem.fth 1.5 96/03/01
purpose: 
copyright: Copyright 1992 Sun Microsystems, Inc.  All Rights Reserved

\ Translated directly from forthlang/kernel/sparc/divrem.s
\ It generates exactly the same code as divrem.s
code u/mod  (s u.dividend u.divisor -- u.remainder u.quotient )
   sp   0 /n* sc6  nget     \ dividend in  %l6
   %g0  tos  sc1  add    \ divisor in   %l1
   %l1  %g0  %l1  orcc
   %g0 h# 3e  =   trapif
   sc6  sc1  %g0 subcc
   u>=  if
      %g0 %g0     %l5  or
      h# 800.0000 %l3  sethi
64\   %l3  d# 32 %l3   slln
      %l6  %l3    %g0  subcc
      u>=  if  %g0 %g0  %l0  or  ( Delay slot )
	 begin
	    %l1  %l3  %g0  subcc
	    0 F: u>=  brif   %g0  1  %l4  or  ( Delay slot )
	    %l1  4  %l1  sll
	 again   %l0  1  %l0  add
	 begin
	    %l1 %l1  %l1  addcc
	    u<  if   %l4 1  %l4  add  ( Delay slot )
	       %l3  4    %l3  slln
	       %l1  1    %l1  srln
	       %l1  %l3  %l1  add
	       1 F: bra   %l4  1   %l4  sub  ( Delay slot )
	    then
0 L:
            %l1  %l6  %g0  subcc
         u>=  until  nop  ( Delay slot )

	 <>  if  nop  then  \ XXXX Don't really need this !!!
1 L:

         %l4  1   %l4  subcc
	 3  F: <  brif  nop  ( Delay slot )

	 %l6  %l1   %l6  sub
	 %g0  1     %l5  or
	 2 F:  bra  annul

	 begin
	    %l5  1  %l5  slln
	    >=  if   %l1  1  %l1  srln  ( Delay slot )
	       %l6  %l1  %l6  sub
	       2 F:  bra   %l5 1  %l5  add  ( Delay slot )
	    then

	    %l6  %l1   %l6  add
	    %l5  1     %l5  sub
2 L:
	    %l4  1   %l4  subcc
	 <  until  %g0  %l6   %g0  orcc  ( Delay slot )

	 3  F:  bra  annul
      then

      begin
	 %l1  4  %l1  slln
	 %l1  %l6  %g0  subcc
      u>  until   %l0  1  %l0 addcc  ( Delay slot )

      <>  if    %l0  1   %l0  sub  ( Delay slot )
	 %g0  %l6   %g0  orcc

	 begin
	    %l5  4  %l5  slln
	    >=  if  %l1  1   %l1  srln  ( Delay slot )
	       %l6  %l1  %l6  subcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6  subcc
		  >=  if  %l1  1   %l1  srln  ( Delay slot )
		     %l6  %l1  %l6  subcc
		     >=  if  %l1  1   %l1  srln  ( Delay slot )
			%l6  %l1  %l6  subcc
			3  F:  bra   %l5  h# 0f  %l5 add  ( Delay slot )
		     then
		     %l6  %l1  %l6  addcc
		     3  F:  bra   %l5  h# 0d  %l5 add  ( Delay slot )
		  then
		  %l6  %l1   %l6  addcc
		  >=  if  %l1  1   %l1  srln  ( Delay slot )
		     %l6  %l1  %l6 subcc
		     3  F:  bra   %l5  h# 0b  %l5 add  ( Delay slot )
		  then
		  %l6  %l1  %l6  addcc
		  3  F:  bra   %l5  h# 09  %l5 add  ( Delay slot )
	       then

	       %l6  %l1   %l6  addcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6 subcc
		  >=  if  %l1  1   %l1  srln  ( Delay slot )
		     %l6  %l1  %l6 subcc
		     3  F:  bra   %l5  h# 07  %l5 add  ( Delay slot )
		  then
		  %l6  %l1   %l6  addcc
		  3  F:  bra   %l5  h# 05  %l5 add  ( Delay slot )
	       then
	       %l6  %l1   %l6  addcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6 subcc
		  3  F:  bra   %l5  h# 03  %l5 add  ( Delay slot )
	       then
	       %l6  %l1   %l6  addcc
	       3  F:  bra   %l5  h# 01  %l5 add  ( Delay slot )
	    then
	    %l6  %l1   %l6  addcc
	    >=  if  %l1  1   %l1  srln  ( Delay slot )
	       %l6  %l1  %l6 subcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6 subcc
		  >=  if  %l1  1   %l1  srln  ( Delay slot )
		     %l6  %l1  %l6 subcc
		     3  F:  bra   %l5  h# -1  %l5 add  ( Delay slot )
		  then
		  %l6  %l1   %l6  addcc
		  3  F:  bra   %l5  h# -3  %l5 add  ( Delay slot )
	       then
	       %l6  %l1   %l6  addcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6 subcc
		  3  F:  bra   %l5  h# -5  %l5 add  ( Delay slot )
	       then
	       %l6  %l1   %l6  addcc
	       3  F:  bra   %l5  h# -7  %l5 add  ( Delay slot )
	    then
	    %l6  %l1   %l6  addcc
	    >=  if  %l1  1   %l1  srln  ( Delay slot )
	       %l6  %l1   %l6  subcc
	       >=  if  %l1  1   %l1  srln  ( Delay slot )
		  %l6  %l1  %l6 subcc
		  3  F:  bra   %l5  h# -9  %l5 add  ( Delay slot )
	       then
	       %l6  %l1   %l6  addcc
	       3  F:  bra   %l5  h# -0b  %l5 add  ( Delay slot )
	    then
	    %l6  %l1   %l6  addcc
	    >=  if  %l1  1   %l1  srln  ( Delay slot )
	       %l6  %l1  %l6 subcc
	       3  F:  bra   %l5  h# -0d  %l5 add  ( Delay slot )
	    then
	    %l6  %l1   %l6  addcc

	    \ XXXX Don't really need the following 3 F:  bra !!!
	    3  F:  bra   %l5  h# -0f  %l5 add  ( Delay slot )

3 L:
	    %l0  1  %l0  subcc
	    < until  %g0 %l6  %g0  orcc  ( Delay slot )
	 <  if  nop  ( Delay slot )
	    %l5  1    %l5  sub
	    %l6  tos  %l6  add
	 then
      then
   then
   nop	\ XXXX Don't really need this !!!

   sc6  sp 0 /n*  nput    \ remainder
   %g0 sc5  tos  add      \ quotient

c;
