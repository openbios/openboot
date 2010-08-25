\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: core.fth
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
id: @(#)core.fth 1.2 06/05/11
purpose: Intel Ophir/82571 Core routines
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 instance value restart?
defer restart-net ['] true to restart-net
\ ============================================================================
\ Data structures
\ ----------------------------------------------------------------------------

\ RX descriptor
struct
   /x field >rx-buf			\ Pointer to data buffer
   /w field >rx-length			\ Length of data buffer
   /w field >rx-csum			\ Checksum
   /c field >rx-status
   /c field >rx-error
   /w field >rx-special			\ Special - unused (needed for VLAN)
constant /rxd

\ RX Status bits
h# 01 constant rxstat.dd		\ Descriptor done
h# 02 constant rxstat.eop		\ End of packet
h# 04 constant rxstat.ixsm		\ Ignore checksum indication
					\ Ignore bits 3-7.
\ RX Error bits
h# 01 constant rxerr.ce			\ CRC or alignment error
h# 02 constant rxerr.se			\ Symbol error (TBI)
h# 04 constant rxerr.seq		\ Sequence error (TBI)
\ Ignore other errors - applicable to
\ offload features.

\ Miscellaneous rx constants and pointers
h# 40 constant #rxds			\ Number of rx descriptors
#rxds /rxd * constant /rxd-ring		\ Size of rx descriptor table
0 value rxd-base			\ Base of descriptor table
0 value rxd-end				\ End of descriptor table in bytes.
0 value rxd-tail			\ Shadow of hardware tail pointer.
0 value rxd-dma-base			\ Hardware address of descriptor array.
d# 2048 constant /rx-buf		\ Size of one rx buffer
/rx-buf #rxds *
constant /rx-buf-array			\ Total amount of memory allocated for
					\ rx buffers.
0 value rx-buf-base			\ Base of rx buffer array

\ TX descriptor
struct
   /x field >tx-buf			\ Pointer to data buffer
   /w field >tx-length			\ Length of data buffer
   /c field >tx-cso			\ Checksum offset (optional)
   /c field >tx-cmd			\ Command
   /c field >tx-status
   /c field >tx-css			\ Checksum Start field (optional)
   /w field >tx-special			\ Special - unused (needed for VLAN)
constant /txd

\ TX command bits
h# 01 constant txcmd.eop		\ End of packet
h# 02 constant txcmd.ifcs		\ Insert Frame checksum
h# 08 constant txcmd.rs			\ Report status
					\ All other bits ignored

\ TX status bits
h# 01 constant txstat.dd		\ Descriptor done.
h# 02 constant txstat.ec		\ Excess collisions
h# 04 constant txstat.lc		\ Late collision

\ TX constants and pointers
h# 8 constant #txds			\ Number of tx descriptors
					\  (8 is the smallest possible)
#txds /txd * constant /tx-ring		\ Size of tx descriptor table
0 value txd-base			\ Base of descriptor table
0 value txd-end				\ End of descriptor table in bytes
0 value txd-current			\ Currently being transmitted buffer
0 value txd-tail			\ Shadow of hardware tail pointer
0 value txd-dma-base			\ Hardware address of descriptor array

d# 2048 constant /tx-buf		\ Size of one tx buffer
/tx-buf #txds *
   constant /tx-buf-array		\ Total amount of memory
   					\  allocated for tx buffers.
0 value tx-buf-base			\ Base of tx buffer array

\
\ Memory layout: starting from cpu-dma-blk (which is therefore the same
\ as rxd-base)
\	Base			Size			Comments
\	========== 		=====			========
\	rxd-base		/rxd-ring		rx descriptors
\	rx-buf-base		/rx-buf-array		rx data buffers
\	txd-base		/tx-ring		tx descriptors
\ 	tx-buf-base		/tx-buf-array		tx buffers
\
\ Set value  of /dma-blk for "map-buffers"
\
/rxd-ring /rx-buf-array +		( /rx-data )
/tx-ring /tx-buf-array +		( /rx-data /tx-data )
+ /rxd + is /dma-blk		\ Add /rxd to allow for alignment rounding.

: rxd>d#	( desc -- index )
   rxd-base - /rxd /
;
   
\ Write a value to the rx tail register
: rx-tail! ( desc -- )
   rxd>d# h# 2818 reg!
;

: txd>d#	( desc -- index )
   txd-base - /txd /
;

\ Write a value to the tx tail register
: tx-tail! ( desc -- )
   txd-base - /txd /  h# 3818 reg!
;
   
\
\ Initialize the rx and tx descriptor rings and buffers.
\ We aren't telling the hardware about these yet.
\
: .rx-ring ( -- )
   ." Head: " h# 2810 reg@ .x
   ." Tail: " h# 2818 reg@ .x cr
   rxd-base #rxds 0 do
      dup i /rxd * + 			( adr desc )
      dup local-x@ .x /x + local-x@ .x cr
      loop
   drop
;

: .tx-ring ( -- )
   ." Head: " h# 3810 reg@ .x
   ." Tail: " h# 3818 reg@ .x cr
   txd-base #txds 0 do 
      dup i /txd * + 
      dup local-x@ .x /x + local-x@ .x cr
      loop
   drop
;
   
: init-rings	( base -- )
   dup >r				( base ) ( r: base )
   /rxd round-up			( desc-base )	\ Align descriptor base
   dup is rxd-base
   \ Tail starts off as first descriptor (head will be second)
   \ That is, all buffers start off belonging to the chip,
   \ except the tail itself.
   dup is rxd-tail			( desc )
   cpu>io-adr is rxd-dma-base		( )

   rxd-base /rxd-ring + dup is rx-buf-base is rxd-end
   #rxds 0 do
      i /rx-buf * rx-buf-base + cpu>io-adr	( dma-adr )
      i /rxd * rxd-base + tuck		( desc-adr dma-adr desc-adr )
      \ Write the buffer address to the descriptor
      >rx-buf local-x!			( desc-adr )
      \ Clear the flags (buffer belongs to hw)
      0 swap >rx-length local-x!	( )
   loop

   rx-buf-base /rx-buf-array + is txd-base
   txd-base is txd-tail
   txd-base /tx-ring + dup is tx-buf-base is txd-end
   txd-base cpu>io-adr is txd-dma-base
   #txds 0 do
      i /tx-buf * tx-buf-base + cpu>io-adr	( dma-adr )
      i /txd * txd-base + tuck	( desc dma-adr desc )
      \ Write the buffer address to the descriptor
      >tx-buf local-x!			( desc )
      \ Clear the rest of the descriptor
      0 over >tx-length local-x!	( desc )
      \ Initialize command register.
      txcmd.rs txcmd.eop or txcmd.ifcs or swap >tx-cmd local-c!
   loop
   \ Sync it all back to mem.
   r> dup cpu>io-adr /dma-blk dma-sync	( ) ( r: )
;

\ ============================================================================
\ Receive routines.
\ ----------------------------------------------------------------------------

\ Move to the next rx descriptor in the ring (ie
\ wrap if needed).
: next-rxd	( desc -- next-desc )
   /rxd +
   dup rxd-end >= if
      drop rxd-base
   then
;

: sync-rxd	( desc -- ) dup cpu>io-adr /rxd dma-sync ;
: sync-rx-buf ( desc -- ) >rx-buf local@ dup io>cpu-adr swap /rx-buf dma-sync ;

: return-buffer	( handle -- )
   \ Clear status
   0 over >rx-status local-c!		( desc )
   0 over >rx-length local-w!
   dup sync-rx-buf
   dup rx-tail!				( desc )
   is rxd-tail				( )
;

: receive-ready?	( -- pkt-waiting? )
   rxd-tail next-rxd
   dup sync-rxd				( desc )
   >rx-status local-c@			( status )
   rxstat.dd and 0<>			( pkt-waiting? )
;

: receive	( -- pkt-handle pkt pktlen )
   rxd-tail next-rxd			( desc )
   dup >rx-buf local-x@ io>cpu-adr	( desc pkt )
   over >rx-length local-w@   		( desc pkt len desc )
;

\ ============================================================================
\ Main transmit routines
\ ----------------------------------------------------------------------------

\ Move to the next tx descriptor in the ring (ie
\ wrap if needed).
: next-txd ( desc -- next-desc )
   /txd +
   dup txd-end >= if
      drop txd-base
   then
;

: sync-tx-buf	( desc -- )
   \ Might as well sync the descriptor here also.
   dup dup cpu>io-adr /txd dma-sync
   >tx-buf local-x@ dup io>cpu-adr swap /tx-buf dma-sync
;

: transmit-complete?	( desc -- complete? )
   >tx-status local-c@  txstat.dd and 0<>
;

\ Wait for up to 4 seconds for the transmit to complete.
: send-wait	( desc -- ok? )
   d# 4000 get-msecs +			( desc tout )
   begin
      dup get-msecs >=	while		( desc tout )
      over transmit-complete? if
	 2drop true exit
      then
   repeat				( desc tout )
   2drop
   " Timeout waiting for transmit completion" diag-type-cr
   true to restart?
   false
;

: transmit	( buf len -- ok? )
   txd-tail >r				( buf len ) ( r: desc )
   dup r@ >tx-length local-w!		\ Set length
   r@ >tx-buf local-x@ io>cpu-adr swap cmove	( ) \ Copy data
   0 r@ >tx-status local-c!
   r@ sync-tx-buf

   \ Increment shadow tail pointer.
   r> dup next-txd dup to txd-tail	( desc desc'  ) ( r: )
   \ Write updated tail pointer to hardware (starts transmit)
   tx-tail!				( desc )
   \ Wait for the transmit to complete.
   send-wait				( ok? )
   \ At this point, errors we can see are:
   \ 	Timeout waiting for send to complete - maybe need to restart net
   \	Excess collisions.
   \ 	Late collision.
;

: get-tx-buffer ( -- adr )
   txd-tail >tx-buf local@ io>cpu-adr
;

\ ============================================================================
\ Initialization routines
\ ----------------------------------------------------------------------------

\ Control register: address 0x0000
: ctrl@ ( -- value ) 0 reg@ ;
: ctrl! ( value -- ) 0 reg! ;
1 d# 26 << constant ctrl.rst
1 d# 05 << constant ctrl.asde
1 d# 06 << constant ctrl.slu

\ Receive address registers:
\	Low: 5400 + 8*i
\	Hi:  5404 + 8*i

\ Set receive address low register[i]
: ral!	( val i -- )
   8 * h# 5400 + reg!
;
\ Set the i'th receive address hi register[i]
: rah! ( val i -- )
   8 * h# 5404 + reg!
;
: ra! ( val i -- )
   8 * h# 5400 + regx!
;

   
: reset-chip ( -- )
   ctrl.rst ctrl!
   10 ms
   \ Assume reset has completed.
;   

: clear-multicast-table ( -- )
   h# 5400 h# 5200 do
      0 i reg!
      /l +loop
;


\ Set the mac address in the receive address 0 registers.
\ Clear the remaining registers and the multicast table array.

: set-mac-address	( -- )
   clear-multicast-table
   mac-address drop	( mac-adr-ptr )
   dup w@ wbflip
   over 2 + w@ wbflip wljoin 0 ral! ( mac-adr-ptr )
   4 + w@ wbflip  h# 8000.0000 or 0 rah! 
   \ Clear remaining receive address registers.
   d# 16 1 do
      0 i ral!
      0 i rah!
   loop
;

: set-promis-mode ( -- )
   h# 18	h# 0100 reg-bset		\ Set upe and mpe
;

: init-mac-mode  ( -- )
   mac-mode  case
      promiscuous   of  set-promis-mode  endof
   endcase
;

: init-receive ( -- )
   set-mac-address
   0 h# 2820 reg!		\ Clear receive delay timer
   0 h# 282c reg! 		\ Clear receive absolute timer reg
   /rxd-ring h# 2808 reg!	\ Set receive descriptor length reg
   \ Set the rx descriptor base address
   rxd-base cpu>io-adr xlsplit h# 2804 reg!	 ( base.lo )  \ hi
   h# 2800 reg!			\ lo
   rxd-tail rx-tail!	\ Set tail (precalculated in init-rings)
   \ Give all the buffers to the chip: the tail pointer has already
   \ been initialized by init-rings - set the head to be the next descriptor.
   rxd-tail next-rxd
   rxd>d# h# 2810 reg!
   h# 0001.0101 h# 2828 reg!	\ rx descriptor control
   \ Receive control:
   \ 	Enable:			0000.0002	On.
   \	Store bad packets:	0000.0004	Off.
   \ 	Promiscuous bits:	0000.0018	Off.
   \	Long packet enable:	0000.0020	Off.
   \	Loopback mode:		0000.00c0	No loopback
   \ 	RDMTS			0000.0300	Don't care. 0 is ok.
   \	Multicast offset:	0000.3000	Don't care. 0 is ok.
   \ 	Accept broadcast:	0000.8000	On.
   \ 	Receive buf size:	0003.0000	0 == 2048 byte buffers.
   \	Vlan Filter:		0004.0000	Off
   \ 	CFI bits:		0018.0000	Off.
   \    Discard pause frames:	0040.0000	On. 
   \  	Pass mac control:	0080.0000	Off.
   \	BSEX:			0200.0000	Off. None of that thank you!
   \ 	Strip crc:		0400.0000	Off.
   \ 
   h# 0040.8002 h# 0100 reg-bset	\ Now receiving!
   init-mac-mode
;

: init-transmit ( -- )
   \ Set transmit descriptor base address
   txd-base cpu>io-adr xlsplit h# 3804 reg! ( base.lo ) \ hi
   h# 3800 reg!		( ) 		\ lo
   /tx-ring h# 3808 reg!		\ Transmit descriptor ring length
   \ Start the head and tail pointers pointing to the same value
   \ (doesn't matter which it is).
   txd-tail tx-tail!			\ Transmit descriptor tail
   txd-tail txd>d# h# 3810 reg!		\ Transmit descriptor head
   h# 60200a h# 0410 reg!		\ Inter-packet gap register.
   \ Transmit control:
   \ 	Enable:			0000.0002	On
   \	Pad short packets:	0000.0004	On (per manual)
   \	Collision threshold:	0000.00f0	Value = 0xf (recommended)
   \	Collision distance:	0020.0000	0x40 bytes (half-duplex)
   \	Software xoff		0040.0000	Off
   \	Retransmit on late col: 0100.0000	Off
   h# 0004.00fe h# 400 reg!
;

: init-chip ( -- )
   ctrl.slu ctrl.asde or ctrl!	\ Set control register - enable PHY
   0 		h# 00c8 reg!	\ Clear all interrupt cause set bits
   h# ffff.ffff h# 00d8 reg!	\ Mask all interrupts.
   0		h# 0178 reg!	\ Clear txcw
   cpu-dma-base init-rings	\ Initialize the memory structures
   init-receive
   init-transmit
;

: net-on	( -- ok? )
   reset-chip
   init-chip
   true
;

: net-off	( -- )
   2 h# 100 reg-bclear		\ Disable rx
   2 h# 400 reg-bclear		\ Disable tx
   reset-chip
;
