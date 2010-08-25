\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fb8-ops.fth
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
id: @(#)fb8-ops.fth 2.8 95/04/19
purpose: Optimized fb8 package support routines
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

headerless
decimal

\ Fast 8-bit cursor toggle
\ Now tests for 32-bit alignment, uses 32-bit ops if possible
code cfb8-invert  ( adr width height bytes/line fg-color bg-color -- )
                             \ bg-color in tos
   sp    0 /n*  sc5  nget    \ fg-color in sc5
   sp    1 /n*  scr  nget    \ bytes/lines in scr
   sp    2 /n*  sc2  nget    \ height in sc2 (outer loop index, >0)
   sp    3 /n*  sc1  nget    \ width in sc1 (inner loop index, >0)
   sp    4 /n*  sc3  nget    \ adr in sc3 (starting address)

   ahead	\ Branch to the loop test at "but then"
   nop
   begin	\ Outer loop

      ahead	\ Branch to the loop test at "but then"
      nop
      begin	\ Inner loop

	 \ The following code is a tribute to delayed branching, a bad
	 \ idea whose time has come and gone
         sc4 tos       cmp
         =  if
         sc4 sc5       cmp	  \ Delay slot, setup for possible next "if"
         else
            sc5   sc3 sc1  stb    \ Delay slot, executed if sc4=tos

            =  if  annul	  \ Executed if sc4<>tos
               sc4  sc3 sc1  stb  \ Delay slot, executed if tos<>sc4<>sc5

               tos  sc3 sc1  stb  \ store byte, executed if sc4=sc5
            then
         then

      but then
         sc1 1    sc1  subcc  \ decrement width until =0
      < until  annul		\ End inner loop when width=0
         sc3 sc1  sc4  ldub

      sc3 scr  sc3  add    \ increment adr to next line

   but then
      sc2 1    sc2  subcc  \ decrement height until =0
   < until   \ End outer loop when height=0
      sp  3 /n*    sc1  nget     \ (delay) restore starting width value

   sp 5 /n*  tos  nget     \ Pop 6 stack items
   sp 6 /n*  sp   add
c;
here lastacf -  constant /cfb8-invert
defer fb8-invert  ' cfb8-invert is fb8-invert

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Assumptions: 	Fontbytes is 2; 0 < width <= 16
\		Fontadr is divisible by 2
\		XXX - Fontbytes is 1 for touche.obf, others?
code cfb8-paint
( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
			\ bg-color in tos
   sp  0 /n*  %o5  nget     \ fg-color in %o5
   sp  1 /n*  sc2  nget     \ Bytes/line - bytes per scan line
   sp  2 /n*  sc3  nget     \ Screenadr - start address in frame buffer
   sp  3 /n*  sc4  nget     \ Height - character height in pixels
   sp  4 /n*  sc5  nget     \ Width - character width in pixels (bytes)
   sp  5 /n*  sc6  nget     \ Fontbytes - bytes per font line
   sp  6 /n*  sc7  nget     \ Fontadr - start address (of this char) in font table

   sc2 sc5  sc2  sub	\ Account for incrementing of address within inner

   sc5 7    %o0  add
   %o0 3    %o0  srl	\ Number of bytes actually used for each font scan line
   sc6 %o0  sc6  sub	\ Amount to add to font byte counter at end of loop

   ahead
   nop
   begin                \ Outer loop - for all scan lines in char

      ahead
      nop
      begin		\ Middle loop - pixels on a scan line
	 > if
	    %o2  %o3  move	  \ (delay) - assume %o2 bits per chunk
	    8    %o3  move	  \ If %o3 > 8, do just 8 at a time
	 then

	 %o2 %o3   %o2  sub   \ Reduce pixel/scan-line count

	 sc7 0     scr  ldub  \ Load one byte of font
	 sc7 1     sc7  add   \ Advance to next byte
	 scr bits/cell 9 - scr  slln   \ Align 1 shift position below sign bit of scr

	 %g0 %o3   %o0  sub   \ Count from (-)width up to 0

	 sc3 %o3   %o1  add   \ Working frame addr is frame+width

	 scr scr   scr  addcc	\ Test high bit
	 begin                	\ Inner loop - bits within one font byte
	    0<  if  annul
	       tos  %o0 %o1   stb	\ Write bg-color to (frame+width + (-)count)

	       %o5  %o0 %o1   stb	\ Write fg-color to (frame+width + (-)count)
	    then

	    %o0     1 %o0  addcc	\ Increment width pixel count
	 = until                 	\ Repeat until width count = 0
	 scr scr   scr  addcc		\ Test high bit

	 sc3   %o3 sc3  add   \ Increment frame buffer addr to next chunk

	 but  then
	 %o2  %g0  cmp
      = until
      %o2    8  cmp

      sc3   sc2 sc3  add   \ Increment frame buffer addr to next line

      sc7   sc6 sc7  add   \ Next scan line in font table
      but then
      sc4     1 sc4  subcc \ Decrement height counter
   < until                 \ Repeat until height count = 0
   sc5     %o2    move     \ Reset pixels/scan-line counter

   sp 7 /n*  tos  nget     \ Pop 8 stack items
   sp 8 /n*  sp   add

c;
here lastacf -  constant /cfb8-paint
defer fb8-paint   ' cfb8-paint  is fb8-paint

\ Very fast window move, for scrolling
\ Similar to 'move', but only moves #move/line out of every 'bytes/line' bytes
\ Assumes bytes/line is divisible by 8 (for double-long load/stores)
\ Assumes src and dst separated by n*bytes/line
\ Called with:
\ src-start dst-start      size      bytes/line #move/line      fb8-move
\ (break-lo)(cursor-y) (winbot-breaklo)  (")  (emu-bytes/line)
\ src > dst, so move from start towards end

32\ [ifdef] ldd-is-broken
32\    4 constant fbalign
32\ [else]
32\    8 constant fbalign
32\ [then]
64\ 8 constant fbalign

code cfb8-window-move  ( src-start dst-start size bytes/line #move/line -- )
                      \ tos=#move/line
   sp 0 /n*  scr  nget       \ scr=bytes/line
   sp 1 /n*  sc1  nget       \ sc1=size
   sp 2 /n*  sc2  nget       \ sc2=dst-start
   sp 3 /n*  sc3  nget       \ sc3=src-start

\ First, force src and dst to alignment boundary, adjust #move/line
   sc3 fbalign 1-  sc4  and    \ Any extra bytes at start?
   tos sc4         tos  add    \ Adjust #move/line by that amount
   sc3 fbalign 1-  sc3  andn   \ Lock src to alignment boundary
   sc2 fbalign 1-  sc2  andn   \ Lock dst to alignment boundary
   tos fbalign 1-  tos  add    \ Round #move/line up to next unit
   tos fbalign 1-  tos  andn

   begin   \ Outer loop
      tos 0    sc4  add  \ Setup inner loop index
      begin  \ Inner loop
         sc4 fbalign    sc4  subcc  \ Decrement index until =0
32\ [ifdef] ldd-is-broken
32\          sc3 sc4        sc6  ld
32\       <= until   \ End inner loop when index=0
32\          sc6  sc2 sc4   st    \ (delay)
32\ [else]
32\          sc3 sc4        sc6  ldd
32\       <= until   \ End inner loop when index=0
32\          sc6  sc2 sc4  std    \ (delay)
32\ [then]
64\          sc3 sc4        sc6  ldx
64\       <= until   \ End inner loop when index=0
64\          sc6  sc2 sc4  stx    \ (delay)

      sc1 scr  sc1  subcc \ Decrement size until =0
      sc2 scr  sc2  add   \ Increment src
   <= until   \ End outer loop when size=0
      sc3 scr  sc3  add   \ (delay) Increment dst

   sp 4 /n*  tos  nget    \ Pop 5 stack items
   sp 5 /n*  sp   add
c;
here lastacf -  constant /cfb8-window-move
defer fb8-window-move  ' cfb8-window-move  is fb8-window-move

[ifdef] copy-to-ram
: stand-init  ( -- )
   stand-init
   ['] cfb8-paint  /cfb8-paint   copy-to-ram  is fb8-paint
   ['] cfb8-invert /cfb8-invert  copy-to-ram  is fb8-invert
   ['] cfb8-window-move  /cfb8-window-move copy-to-ram  is fb8-window-move
;
[then] \ copy-to-ram
headers
