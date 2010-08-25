\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: ide.fth
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
id: @(#)ide.fth 1.20 04/04/21
purpose: 
copyright: Copyright 1997-2001,2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex

headerless

" ide"	name
" ide"	device-type

2 encode-int " #address-cells" property

0	instance value cmd-regs
0	instance value ctrl-regs
0	instance value interface		\ which interface
0	instance value disk-id			\ which drive
0	instance value lun
0		 value secondary?		\ secondary interface present?
0		 value reg-enable

0       	 value present
: ata! ( data reg -- ) cmd-regs + rb! ;
: ata@ ( reg -- data ) cmd-regs + rb@ ;

: ctrl! ( data -- ) ctrl-regs + rb! ;
: ctrl@ ( -- data ) ctrl-regs + rb@ ;

: data!	  ( data -- ) wbflip cmd-regs rw!  ;
: data@   ( -- data ) cmd-regs rw@ wbflip  ;
: err@    ( -- data ) h# 1 ata@ ;
: cmd!    ( data -- ) h# 7 ata! ;
: stat@   ( -- data ) h# 7 ata@ ;
: astat@  ( -- data ) h# 2 ctrl@ ;	\ Alternate status reg

: .rd-ide-block ( regs addr bytes -- ) bounds do data@ i w! 2 +loop drop ;
: .wr-ide-block ( regs addr bytes -- ) bounds do i w@ data! 2 +loop drop ;

instance defer xfer-fn
: (read)  ( -- ) ['] .rd-ide-block is xfer-fn ;
: (write) ( -- ) ['] .wr-ide-block is xfer-fn ;

\ Checking IDE interrupts is device/vendor specific..
defer ide-irq? ( -- flag? ) ' false is ide-irq?

\
\ These bits must be set for commands to work.
\
h# E0 constant cmd-reg-bits
\ h# A0 constant cmd-reg-bits

headers

d# 5000 constant reset-bsy-timeout

headerless
0 instance value blocksize

create reg-array
	0 ,
	0 ,
	0 ,
	0 ,

: .inform ( str,len -- ) type space ;
: .drive	" drive"	.inform ;
: .master	" Master"	.inform ;
: .slave	" Slave"	.inform ;
: .interface	" interface"	.inform ;
: .primary	" Primary"	.inform ;
: .secondary	" Secondary"	.inform ;
: .number	" number"	.inform ;
: .invalid-ide	" Invalid IDE"	.inform ;
: .diag-msg	." Failed Diagnostic" cr ;

0 instance value error?
0 instance value timeout?
instance defer check-bits

\ Define a simple usec counter
[ifndef] have-usec-fcode?
d# 200 value looptime

: us ( n -- ) looptime * 0 ?do loop ;

: calibrate-us ( -- )
   d# 3.000.000 dup is looptime                         ( n )
   get-msecs looptime 0 ?do loop get-msecs swap -       ( n ms )
   d# 1000 * / 1 max is looptime
;

calibrate-us
[then]

: xfer-wait-status ( timeout check-acf -- ok? )
   false is timeout?            ( timeout check-acf )
   is check-bits  0  ?do        ( )
      stat@ check-bits  if  unloop true exit  then
      d# 10 us                      ( )
   loop  false                  ( failed )
   true is timeout?             ( failed )
;

: wait-status ( timeout check-acf -- ok? )
   false is timeout?		( timeout check-acf )
   is check-bits  0  ?do	( )
      stat@ check-bits  if  unloop true exit  then
      1 ms			( )
   loop  false			( failed )
   true is timeout?		( failed )
;

: alt-wait-status ( timeout check-acf -- ok? )
   false is timeout?		( timeout check-acf )
   is check-bits  0  ?do	(  )
      astat@ check-bits  if  unloop true exit  then
      1 ms			(  )
   loop  false			( failed )
   true is timeout?		( failed )
;


: bitset?	( data n -- set? ) tuck and = ;
: .check-busy ( status -- set? )	h# 80 bitset? ;
: .check-!busy ( status -- set? )	.check-busy 0= ;
: .check-ready ( status -- set? )	h# 40 bitset? ;
: .check-data ( status -- set? )	h#  8 bitset? ;
: .check-data&!busy ( status -- set? )	dup h#  8 bitset? swap .check-!busy and ;

: wait-!busy? ( t -- ok? )	['] .check-!busy  wait-status ;
: wait-busy? ( t -- ok? )	['] .check-busy  wait-status ;
: wait-ready? ( t -- ok? )	['] .check-ready wait-status ;
: wait-data? ( t -- ok? )	['] .check-data  wait-status ;
: wait-data&!busy? ( t -- ok? )	['] .check-data&!busy  wait-status ;
: xfer-wait-!busy? ( t -- ok? )	['] .check-!busy  xfer-wait-status ;

: alt-wait-!busy? ( t -- ok? )	['] .check-!busy  alt-wait-status ;
: alt-wait-ready? ( t -- ok? )	['] .check-ready alt-wait-status ;
: alt-wait-data? ( t -- ok? )	['] .check-data  alt-wait-status ;

: decode-unit,lun ( target lun -- m/s p/s )
  to lun				( target )
  dup 1 and				( target m/s )
  swap 1 rshift				( m/s p/s )
;

\ Our Addressing scheme works like this:
\ ide/disk@D,L
\  where D = Device 0-3, bit 1 = Interface, 0 = Device
\  and   L = Lun
\ anything else is invalid.
\
external
: set-address  ( target lun -- OK? )
  decode-unit,lun			( m/s p/s )
  dup 0 1 between			( m/s p/s valid )
  if					( m/s p/s )
    dup 0<> secondary? 0= and if	( m/s p/s )
      " No" .inform			( m/s p/s )
      .secondary .interface		( m/s p/s )
      2drop false exit			( false )
    then				( -- false )
    dup is interface			( m/s )
    if 2 else 0 then			( m/s offset )
    reg-array swap			( m/s array offset )
    2dup na+ @ is cmd-regs		( m/s array offset )
    1+   na+ @ is ctrl-regs		( m/s )
    dup 0 1 between			( m/s valid? )
    if					( m/s )
      is disk-id			( -- )
      true				( -1 )
    else				( target )
      .Invalid-IDE .drive .number	( -- )
      . cr false			( 0 )
    then				( 0 | 1 )
  else					( m/s p/s )
    .Invalid-IDE .interface .number	( m/s )
    . cr drop false			( 0 )
  then
;

headerless
\
\ For the ATA interface the data in the command block is
\ a copy of the contents of the registers and I just copy then into the
\ correct places to run the command.
\
0 instance value timeout

fload ${BP}/dev/ide/pktdata.fth
fload ${BP}/dev/ide/ata/support.fth		\ Load ATA interface
fload ${BP}/dev/ide/atapi/support.fth		\ Load ATAPI interface

headerless
: #emit ( n -- ) ascii 0 + emit ;

h# 200 buffer: id-buf
: Model-# ( -- )
  ." Model: " id-buf d# 54 + dup c@ if d# 40 type else drop ." <Unknown>" then
;

h# 12  buffer: id-pkt
h# 12  buffer: id-cmd

: .not-present ( -- false ) 4 spaces ." Not Present" false ;

: (reset) ( check? -- ok? )
   6 2 ctrl!
   1 ms
   if  1 wait-busy?  else  true  then
   2 2 ctrl!
;
