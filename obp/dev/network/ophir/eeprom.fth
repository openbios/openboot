\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: eeprom.fth
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
id: @(#)eeprom.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ Number of bits in the EEPROM address
d# 16 constant /eepromaddr

: eec@ ( -- data ) h# 10 reg@ ;
: eer@ ( -- data ) h# 14 reg@ ;
: eec! ( data -- ) h# 10 reg! ;
: eer! ( data -- ) h# 14 reg! ;

: setbit ( bit -- ) eec@ or eec! ;
: clrbit ( bit -- ) invert eec@ and eec! ;

: set-eesk ( -- )   1 setbit ;
: set-eecs ( -- )   2 setbit ;
: set-eedi ( -- )   4 setbit ;
: clear-eesk ( -- ) 1 clrbit ;
: clear-eecs ( -- ) 2 clrbit ;
: clear-eedi ( -- ) 4 clrbit ;

: get-eedo ( -- bit ) eec@ 3 >> 1 and ;

: clock-tick ( -- ) set-eesk clear-eesk ;

: eeprom-request ( -- )
   1 6 << setbit
   begin 
      eec@ 1 7 << and 
   until
;

: eeprom-relenquish ( -- )
   1 6 << clrbit
;

: send0 ( -- ) clear-eedi clock-tick ;
: send1 ( -- ) set-eedi clock-tick ;

\ 0b00000101 = Read Status Register
: (rdsr) ( -- status )
   clear-eecs
   send0 send0 send0 send0 send0 send1 send0 send1
   0 8 0 do
      get-eedo 7 i - << or clock-tick
   loop
   set-eecs
;

: rdsr ( -- status )
   clear-eesk
   eeprom-request
   (rdsr)
   eeprom-relenquish
;

\ 0b00000110 = Write enable
: wren ( -- ) 
   clear-eecs
   send0 send0 send0 send0 send0 send1 send1 send0
   set-eecs
   clock-tick
;

\ We shouldn't need the timeout here, but we don't want to hang the system if 
\ something is wrong with the Ophir device. Ten seconds is a reasonable timeout.
d# 10000 constant write-timeout

\ This is the guts of the bit-bang interface to the Intel Ophir EEPROM. For 
\ the specifics on the protocol, see the PRM.
: (eeprom!) ( byte addr -- )
   get-msecs			( start )
   begin			( start )
      (rdsr) 1 and 0=		( start ready? )
      over get-msecs swap -	( start ready? time )
      write-timeout > or	( start done? )
   until			( start )
   get-msecs swap - write-timeout > if 
      cmn-error[ " Timeout waiting for PROM RDY signal." ]cmn-end abort
   then
   wren
   clear-eecs
   send0 send0 send0 send0 send0 send0 send1 send0
   1 /eepromaddr <<
   /eepromaddr 0 do
      1 >> 2dup and if send1 else send0 then
   loop
   2drop
   1 8 <<
   8 0 do
      1 >> 2dup and if send1 else send0 then
   loop
   2drop
   set-eecs
;

\ Request access to the EEPROM, then store a word
: eeprom-w! ( data addr -- ) 
   2* clear-eesk eeprom-request 	( data addr )
   tuck swap wbsplit			( addr addr data.lo data.hi )
   rot 1+ (eeprom!)			( addr data.lo )
   swap (eeprom!)			(  )
   eeprom-relenquish 			(  )
;

\ Read a word from the EEPROM by setting the start bit 
\ and waiting for the done bit. First make sure that the
\ device is not in use.
: eeprom-w@ ( addr -- data ) 
   eeprom-relenquish			( addr )
   2 << 1 or eer!			(  )
   begin 				(  )
      eer@ 2 and			(  )
   until 				(  )
   h# 14 reg@ d# 16 >> 			( data )
;

\ Calculate the checksum. Intel's algorithm for this is to modify 
\ checksum byte 0x40 so that the first 64 bytes add up to 0xbaba 
: checksum ( -- sum )
   0 d# 63 0 do
      i eeprom-w@ +
   loop
   h# baba swap - h# ffff and 
;

