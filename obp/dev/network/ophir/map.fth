\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: map.fth
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
id: @(#)map.fth 1.1 06/02/16
purpose: Intel Ophir/82571 map routines
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Instance values
0 instance value reg-base
0 instance value cpu-dma-base	\ cpu mapped dma base
0 instance value io-dma-base	\ device mapped dma base
0 instance value /dma-blk	\ Total amount to map.

\ Constants
h# 20.000	constant map-size	\ Amount to map for registers.

: map-in	( phys.lo .. phys.hi size -- vaddr ) " map-in" $call-parent ;
: map-out	( vaddr size -- ) " map-out" $call-parent ;

: dma-alloc	( size -- vaddr ) " dma-alloc" $call-parent ;
: dma-free	( vaddr size -- ) " dma-free" $call-parent ;

: dma-map-in	( vaddr n cache? -- devaddr ) " dma-map-in" $call-parent ;
: dma-map-out	( vaddr devaddr n -- ) " dma-map-out" $call-parent ;

: dma-sync	( virt-adr dev-adr size -- )
   " dma-sync" ['] $call-parent catch if
      3drop 2drop
   then
;

: enable-mem-space ( -- )  
   \ PCI Command Register Settings
   \ h# 100  = SERR# Enable
   \ h#  40  = Parity Error Enable
   \ h#   4  = Mastering Enable
   \ h#   2  = Memory Access Enable
   4  my-w@ h# 146 or 4 my-w!
; 

: disable-mem-space ( -- )  
   4 my-w@ h# 2 invert and 4 my-w!
;

\
\ "Local" access to hardware data structures held in
\ local memory.
\ These are functionally equivalent to "rw@" etc except
\ they access local memory.  Since the chip is little-endian
\ we have to do the flip explicitly ("rw@" etc fcodes
\ are set up to do it for us, but not "w@" etc).
\

: local-c@	( offset -- data ) c@ ;
: local-c!	( data offset -- ) c! ;
: local-w!	( data offset -- ) swap wbflip swap w! ;
: local-w@	( offset -- data ) w@ wbflip ;
: local!	( data offset -- ) swap lbflip swap l! ;
: local@	( offset -- data ) l@ lbflip ;
: local-x!	( data offset -- ) swap xbflip swap x! ;
: local-x@	( offset -- data ) x@ xbflip ;

: reg@		( offset -- data ) reg-base + rl@ ;
: reg!		( data offset -- ) reg-base + rl! ;
: regx@		( offset -- data ) reg-base + rx@ ;
: regx!		( data offset -- ) reg-base + rx! ;

: reg-bset	( data offset -- ) dup reg@ rot or swap reg! ;
: reg-bclear	( data offset -- ) dup reg@ rot invert and swap reg! ;

\ Conversion between cpu dma address and io dma address.
: cpu>io-adr	( cpu-adr -- io-adr ) cpu-dma-base - io-dma-base + ;
: io>cpu-adr	( io-adr -- cpu-adr ) io-dma-base - cpu-dma-base + ;

: map-buffers	( -- )
   /dma-blk dma-alloc to cpu-dma-base
   cpu-dma-base /dma-blk false dma-map-in to io-dma-base
;

: unmap-buffers	( -- )
   cpu-dma-base io-dma-base /dma-blk dma-map-out
   cpu-dma-base /dma-blk dma-free
   0 to cpu-dma-base 0 to io-dma-base
;

: map-regs	( -- )
   my-address my-space h# 300.0010 or map-size map-in
   to reg-base
   enable-mem-space
;

: unmap-regs	( -- )
   reg-base map-size map-out
   0 to reg-base
   disable-mem-space
;

headers

: map-resources	( -- )
   reg-base 0= if map-regs map-buffers then
;

: unmap-resources	( -- )
   reg-base if unmap-buffers unmap-regs then
;

headerless
