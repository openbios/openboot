\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: support.fth
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
id: @(#)support.fth 1.8 04/04/21
purpose: 
copyright: Copyright 1997-2000,2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ An ATA packet looks like:
\	byte		Meaning
\	0		cmd
\	1		<PAD>
\	2		error
\	3		#blocks
\	4,5,6,7		block#
\	8,9,a,b		<PAD>
\
\
struct
  1	field >cmd-byte
  1	field >error
  1	field .pad1
  1	field >#blocks
  4	field >block#
  4	field .pad2
constant /ata-pkt

: count!  ( data -- ) 2 ata! ;
: sec!    ( data -- ) 3 ata! ;
: cyl-lo! ( data -- ) 4 ata! ;
: cyl-hi! ( data -- ) 5 ata! ;
: cyl!    ( cyl -- ) wbsplit cyl-hi! cyl-lo! ;
: head!   ( data -- ) 6 ata! ;

: >disk ( id -- ) 1 and 4 << ;

: select-drive  ( id -- ) >disk cmd-reg-bits or head! ;

\
\ This routine fills the registers with meaningfull data
\ 
: lba! ( block -- )
  lbsplit			( sect cyl-lo cyl-hi xtra )
  h# f and			( sect cyl-lo cyl-hi hds )
  disk-id >disk or		( sect cyl-lo cyl-hi hds' )
  cmd-reg-bits or		( sect cyl-lo cyl-hi hds' )
  head!				( sect cyl-lo cyl-hi )
  cyl-hi! cyl-lo! sec!		( -- )
;

: drive+cmd! ( cdb -- )
  disk-id >disk cmd-reg-bits or head!
  c@ cmd! 1 ms
;

: dataless-xfer ( pkt -- fail? )
  >cdb-ptr l@				( cdb )
  d# 2000 wait-!busy? if
    drive+cmd!				( -- )
    timeout wait-!busy? drop		( -- )
    false				( false )
  else					( cdb )
    drop true				( true )
  then					( fail? )
;

: addressless-xfer ( pkt -- fail? )
   get-pkt-data >r			( buffer cdb )
   d# 2000 wait-!busy? if		( buffer cdb )
      drive+cmd!			( buffer )
      timeout wait-data&!busy? if	( buffer )
         cmd-regs swap h# 200		( cmd-regs buffer len )
         dup r> >transfer-bytes l!	( cmd-regs buffer len )
         xfer-fn false exit		( false )
      then 0				( buffer 0 )
   then					( buffer cdb )
   r> 3drop true			( true )
;

: data-xfer ( pkt -- fail? )
  get-pkt-data >r			( buffer cdb )
  dup >block# l@ lba!			( buffer cdb )
  dup >#blocks c@ count!		( buffer cdb )
  tuck					( cdb buffer cdb )
  d# 2000 wait-!busy? if		( cdb buffer cdb )
    >cmd-byte c@ cmd! 1 ms		( cdb buffer )
    dup >r				( cdb buffer )
    over >#blocks c@			( cdb buffer #blocks )
    ?dup 0= if d# 256 then		( cdb buffer #blocks )
    0 do				( cdb buffer )
      timeout wait-data? 0= ?leave	( cdb buffer )
      cmd-regs over h# 200		( cdb buffer cmd-regs buffer len )
      xfer-fn				( cdb buffer )
      h# 200 +				( cdb buffer' )
      \ Wait up to 2 seconds for non busy status 
      d# 200.000 xfer-wait-!busy? 0=	( cdb buffer )
      ?leave				( cdb buffer )
    loop				( cdb buffer )
    nip r> -				( #bytes )
    r> >transfer-bytes l!		( -- )
    false				( false )
  else					( cdb buffer cdb )
    r> 2drop 2drop true			( true )
  then					( flag )
;

: .identify ( pkt -- fail? )
  dup >r (read)				( pkt )
  addressless-xfer ?dup if		( -- )
    r> drop				( true )
  else					( -- )
    r> >data-ptr l@			( buffer )
    h# 200 bounds do i w@ flip i w! 2 +loop
    false				( false )
  then					( flag )
;

\ This is how I check if a disc is present,
\ If the recalibrate doesn't have device ready set within 100ms of the
\ command being issued I assume the device is missing.
\
: .recalibrate ( pkt -- fail? )
  get-pkt-data drop			( buffer cdb )
  nip d# 2000 wait-!busy? if		( cdb )
    drive+cmd!				( -- )
    d# 100 wait-ready? if		( -- )
      true				( true )
    else				( -- )
      timeout wait-!busy? drop		( -- )
      false				( false )
    then				( flag? )
  else					( cdb )
    drop true				( true )
  then					( fail? )
;

: run-ata ( pkt -- error? )
   dup >r
   r@ >timeout l@ is timeout		( pkt )
   r@ >cdb-ptr l@ >cmd-byte c@		( pkt cmd )
   h# fe and case			( pkt )
     h# E0 of  dataless-xfer		endof	\ SPIN UP/DOWN
     h# EC of  .identify		endof	\ IDENTIFY
     h# A0 of  .identify		endof	\ IDENTIFY
     h# 10 of  .recalibrate		endof	\ RECALIBRATE
     h# 20 of  (read) data-xfer		endof	\ READ SECTORS
     h# 30 of  (write) data-xfer	endof	\ WRITE SECTORS
     >r true r>
   endcase				( fail? )
   r> swap if				( pkt )
      stat@ over >status l!		( pkt )
      err@  over >cdb-ptr l@		( pkt err cdb )
      >error c!				( pkt )
      true				( pkt true )
   else					( pkt )
      false				( pkt false )
   then nip				( flag )
;
