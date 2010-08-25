\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: io.fth
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
id: @(#)io.fth 1.11 05/02/02
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
d# 90   constant ubufsize
ubufsize buffer: ubuf
0 	value  getptr
0 	value  putptr
0 	value  endptr

h# 10 constant msr-cts

variable ttylock

: initubuf  ( -- )
   ubuf  is  getptr
   ubuf  is  putptr
   ubuf ubufsize + is endptr
;

\ put key into uart buffer, ignoring overun
: bput	( key -- )	\ put key into buffer
   putptr endptr >= if  ubuf is putptr  then
   putptr c! putptr 1+ is putptr
;

\ clear the uart buffer for put task
: bputclr  ( -- )  getptr is putptr  ;


\ Fetch a key from buffer
: bget	( -- key )
   getptr endptr >= if  ubuf is getptr  then
   getptr c@ getptr 1+ is getptr
;

\ return TRUE if uart buffer is empty.
: ubuf-empty? 	( -- flag )  getptr putptr =  ;

headerless
: usea  ( -- )  uartbase to uart  ;
: useb  ( -- )  uartbase to uart  ;

create init-table
  h# 00 c, h# 01 c,	\ Interrupt Enable Register = disable all interrupts
  h# 00 c, h# 04 c,	\ Modem Control Register = disable all Modem fcns
  h# 00 c, h# 02 c,	\ FIFO Control Register = 0
  h# 01 c, h# 02 c,	\ FIFO Control Register = 1
  h# 83 c, h# 03 c,	\ Line Control Register = 83
  h# 60 c, h# 00 c,	\ Divisor Latch Register LSB
  h# 00 c, h# 01 c,	\ Divisor Latch Register MSB
  h# 03 c, h# 03 c,	\ Line Control Register = 03
\  h# 00 c, h# 04 c,	\ Modem Control Register unchanged
\  h# 10 c, h# 04 c,	\ Modem Control Register = enable Loopback Mode
  h# 08 c, h# 04 c,	\ Modem Control Register = IRQ enable
here init-table - constant #table-size

: uart!  ( c offset -- )  uart + c!  ;
: uart@  ( offset -- c )  uart + c@  ;

\ read SIO modem status register
: msr@  ( -- byte )  h# 06 uart@  ;

\ bsc is ready if CTS is asserted
: hw-bsc-ready?  ( -- ready? )  msr@ msr-cts and  ;

defer bsc-ready?  ( -- ready? )		\ depends on flow control
' true is bsc-ready?			\ default is no flow control

\ Receive Buffer Register RO
: rbr@  ( -- c )  0 uart@  ;

\ Transmit Holding Register WO
: thr!  ( c -- )  0 uart!  ;

0 value IER-reg		\ IER contents at entry

\ Interrupt Enable Register
: ier!  ( c -- )  1 uart!  ;
: ier@  ( -- c )  1 uart@  ;

: disable_tx_int  ( -- )
   ier@ dup to IER-reg  h# fd and ier!
;

: restore_tx_int  ( -- )
   IER-reg ier!
;

variable LSR-reg	\ LSR shadow

\ Line Status Register RO
: lsr@  ( -- c )  5 uart@ dup  LSR-reg c@ or LSR-reg c!  ;

: inituart  ( -- )
   initubuf
   \ One time init stuff goes here.
   init-table #table-size bounds  ?do
      i c@ i 1+ c@ uart!
   2 +loop
;

\ Test for "break" character received.
: ubreak?  ( -- flag )  lsr@ drop LSR-reg c@ h# 10 and  ;

: uemit?  ( -- flag )
   bsc-ready? if
      lsr@ h# 20 and
   else
      1 ms
      0
   then
;

: uemit  ( char -- )  begin  uemit?  until  thr!  ;

: (ukey?)  ( -- flag )  lsr@ h# 01 and  ;
: (ukey)   ( -- key )   begin  (ukey?)  until  rbr@  ;

\ Wait for characters to finish transmitting
: uwait  ( -- )  begin  lsr@ h# 40 and  until  ;

\ This is called from Solaris under certain circumstances
\ such as early boot and panics.
\ In order to prevent MP systems registering spurious interrupts on
\ the CPU(s) not in OBP, or to prevent corruption of console I/O by
\ OBP and the console driver writing at the same time at the start of
\ panic handling, disable the THRE (tx) interrupt during the write.
\ Restore the state of the interrupt before waiting for the last
\ character to finish transmitting, this will ensure that Solaris
\ will see a tx interrupt in the case that it is waiting for one ie
\ OBP was called with data in the FIFO.
: uwrite  ( adr len -- #written )
   ttylock on
   disable_tx_int
   tuck  bounds  ?do	( len )
      i c@  uemit	( len )
   loop			( len )
   restore_tx_int	( len )
   uwait		( len )
   ttylock off		( len )
;

: uread  ( -- )
   ttylock on
   begin  (ukey?)  while  (ukey) bput  repeat
   ttylock off
;

: ukey?  ( -- flag )  uread  ubuf-empty? 0=  ;

: ukey   ( -- char )  begin  ukey?  until  bget  ;

: clear-break  ( -- )
   ukey? drop bputclr
   0 LSR-reg c!
;

headerless
d# 24.000.000	constant xtal-clk
d# 13 d# 16 *	constant chip-div

: fifo!  ( data -- )  h# 02 uart!  ;
: lcr!   ( data -- )  h# 03 uart!  ;
: mcr!   ( data -- )  h# 8 or  h# 04 uart!  ;
: mcr@   ( -- data )  h# 04 uart@  ;

struct
  1 field LCR-reg	\ Line Control
  1 field MCR-reg	\ Modem Control
drop
variable shadow-regs

\ Set the s/w version of the Line Control Register
: set-bits  ( data addr -- )  tuck  c@ or  swap c!  ;
: set-lcr  ( data -- )  shadow-regs LCR-reg set-bits  ;
: set-mcr  ( data -- )  shadow-regs MCR-reg set-bits  ;

: hold-uart  ( -- )
  h# 00 fifo!	\ Disable and clear FIFOs
;

: release-uart  ( -- )
  5 uart@ drop          \ clear error bits in LSR
  shadow-regs			( addr )
  dup LCR-reg c@ lcr!	\ Write LCR (and select bank 0)
  MCR-reg c@ mcr!	\ write MCR reg
  h# 01 fifo!		\ FIFOs enabled
  1 ms                  \ Allow device to stabilize.
;			\ This delay is necessary to prevent
			\ garbage characters from being sent out on
			\ the first transmit resulting in a framing
			\ error. For some reason this device needs
			\ a moment to stabilize.

: set-baud  ( baud -- )
  chip-div *		( baud' )
  xtal-clk d# 8 <<	( baud' clk' )
  swap / d# 8 >>	( divisor )
  wbsplit		( lo hi )
  h# 83 lcr!            ( lo hi )       \ select Bank 1
  h# 01 uart!		( lo )		\ Write Hi Div
  h# 00 uart!		( -- )		\ Write Lo Div
  h# 03 lcr!            ( -- )          \ select Bank 0
;

: set-dtr-rts  ( on? -- )
   mcr@ swap
   if  3 or
   else  3 invert and
   then
   set-mcr
;

: set-databits  ( #bits -- )
  case
    5 of  h# 00  endof		\ 5 bits data
    6 of  h# 01  endof		\ 6 bits data
    7 of  h# 02  endof		\ 7 bits data
    8 of  h# 03  endof		\ 8 bits data
  endcase			( data )
  shadow-regs LCR-reg c!	( -- )
;

: set-parity  ( parity -- )
  case
    p.mark  of  h# 28  endof	\ mark
    p.even  of  h# 18  endof	\ even
    p.odd   of  h# 08  endof	\ odd
    p.none  of  h#  0  endof	\ none
    p.space of  h# 38  endof	\ space
  endcase			( data )
  set-lcr			(  )
;

: set-stopbits  ( #stp -- )
  1- if  h# 04 set-lcr  then
;

: no-flow-ctrl  ( -- )
   ['] true is bsc-ready?
;

: hard-flow-ctrl  ( -- )
   ['] hw-bsc-ready? is bsc-ready?
;

\ XXX needs work looking at the input chars as they arrive:
: soft-flow-ctrl  ( -- )
   ." XXXX unimp: su16550 handshake" cr
   ['] true is bsc-ready?
;

: set-handshake  ( hs -- )
   case
      hs.none of  no-flow-ctrl    endof
      hs.hw   of  hard-flow-ctrl  endof
      hs.sw   of  soft-flow-ctrl  endof
   endcase
;

headers

\ mode parameter is switching between 232 and 433 (sp?)
: config-serial  ( hs stp prty dbits baud dtr-rts-on? mode -- )
   hold-uart		( hs stp prty dbits baud dtr-rts-on? mode )
   rs-mode-select	( hs stp prty dbits baud dtr-rts-on? )
   set-dtr-rts		( hs stp prty dbits baud )
   set-baud		( hs stp prty dbits )
   set-databits		( hs stp prty )
   set-parity		( hs stp )
   set-stopbits		( hs )
   set-handshake	(  )
   release-uart		(  )
;

headerless
