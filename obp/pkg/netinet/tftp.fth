\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tftp.fth
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
id: @(#)tftp.fth 1.2 05/03/25
purpose: TFTP support
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC  906: Bootstrap loading using TFTP
\ RFC 1350: The TFTP Protocol

fload ${BP}/pkg/netinet/tftp-h.fth

headerless

0        instance value     tftp-sockid
/timer   instance buffer:   tftp-timer
/insock  instance buffer:   tftp-cli-addr
/insock  instance buffer:   tftp-srv-addr
/insock  instance buffer:   tftp-from-addr
         instance variable  tftp-from-len
0        instance value     tftp-sndbuf
         instance variable  tftp-sndbuflen
0        instance value     tftp-rcvbuf
         instance variable  tftp-nextblk#
0        instance value     tftp-retries

: tftp-init ( siaddr -- )
   tftp-cli-addr my-ip-addr 0            insock-init		( ipaddr )
   tftp-srv-addr swap       IPPORT_TFTP  insock-init		( )

   /tftp-packet alloc-mem  to tftp-sndbuf			( )
   /tftp-packet alloc-mem  to tftp-rcvbuf			( )

   AF_INET SOCK_DGRAM IPPROTO_UDP socreate to tftp-sockid	( )
   tftp-sockid tftp-cli-addr /insock  sobind 			( )
;

: tftp-close ( -- )
   tftp-sndbuf /tftp-packet free-mem
   tftp-rcvbuf /tftp-packet free-mem
   tftp-sockid soclose
;

\ Send a packet to the TFTP server
: tftp-send-packet ( -- )
   tftp-sockid tftp-sndbuf tftp-sndbuflen @ 0 tftp-srv-addr /insock
   sosendto 0<  if
      ." TFTP: Could not send to "
      tftp-srv-addr .insock  tftp-sockid .soerror  -1 throw
   then
;

\ Send a TFTP read request 
: tftp-send-rrq ( mode$ file$ -- )
   tftp-sndbuf >r				( mode$ file$ ) ( r: pkt )
   TFTP_RRQ  r@ >tftp-opcode  htonw!		( mode$ file$ )
             r@ >tftp-file    $cstrput		( mode$ adr )
                              $cstrput		( adr' )
   r> - tftp-sndbuflen !			( ) ( r: )
   1 tftp-nextblk# !				( )
   tftp-send-packet				( )
;

\ Format and send a TFTP ack packet. 
: tftp-send-ack ( block# -- )
   tftp-sndbuf					( block# pkt )
   TFTP_ACK over >tftp-opcode    htonw!		( block# pkt )
                 >tftp-block#    htonw!		( )
   /tftp-header  tftp-sndbuflen  !		( )
   tftp-send-packet				( )
;

\ Format a TFTP ERROR packet and send it to the specified endpoint. Used
\ to reject connections once a connection to a TFTP server has been
\ established.

: tftp-send-error ( insock -- )
   /tftp-packet alloc-mem  swap >r			( pkt ) ( r: insock )
   TFTP_ERROR  over >tftp-opcode   htonw!		( pkt )
   5           over >tftp-errcode  htonw!		( pkt )
   " Unknown transfer ID"				( pkt $ )
               2 pick >tftp-data   $cstrput		( pkt pktend )
   over tuck -						( pkt pkt len )
   tftp-sockid -rot 0 r> /insock sosendto drop		( pkt ) ( r: )
   /tftp-packet free-mem				( )
;

\ Managing timeouts and retransmissions. Use a simple exponential backoff 
\ strategy (with a maximum timeout of 32 seconds) between retries. Abort 
\ the file transfer if the maximum number of retries has been exceeded.

: tftp-retransmit-packet ( -- )
   tftp-retries tftp-max-retries u> if			( )
      ." TFTP: Transfer timed out"  -1 throw
   then							( )
   tftp-retries 1+  dup to tftp-retries			( n )
   d# 10 mod 0=  if					( )
      ." Timed out waiting for TFTP reply" cr		( )
   then							( )
   tftp-send-packet					( )
;

: tftp-backoff ( -- )
   tftp-timer  dup clear-timer 2* d# 32000 min  set-timer
;

\ Process incoming TFTP packets addressed to our port. If this is an
\ ERROR packet, we accept the error only if the we know the TFTP
\ server's address and the error is on this connection.

: (tftp-receive-packet) ( -- pkt len )
   tftp-sockid tftp-rcvbuf tuck /tftp-packet 0 tftp-from-addr tftp-from-len
   sorecvfrom
;

: tftp-receive-packet ( -- pkt len true | false )
   (tftp-receive-packet) dup 0= if 2drop false exit then
   over >tftp-opcode ntohw@  TFTP_ERROR =  if		( pkt len )
      tftp-srv-addr >sin-addr dup ip=broadcast? if	( pkt len ipaddr )
         3drop false exit				( false )
      then						( pkt len ipaddr )
      tftp-from-addr >sin-addr ip<>  if			( pkt len )
         2drop false exit				( false )
      then						( pkt len )
      drop >tftp-errmsg cscount				( error$ )
      ." TFTP Error: " type cr  -1 throw		( )
   then							( pkt len )
   true							( pkt len true )
;

\ Processing TFTP DATA packets. If this is the first response, register
\ the server's IP address and port number (TID). Once a connection has
\ been established, other connections are rejected by returning an 
\ ERROR packet.
 
: (tftp-receive-data) ( -- pkt len true | false )
   tftp-receive-packet 0=  if  false exit  then		( pkt len )
   over >tftp-opcode ntohw@  TFTP_DATA <>  if		( pkt len )
      2drop false exit					( false )
   then							( pkt len )
   tftp-srv-addr dup >sin-port ntohw@ IPPORT_TFTP = if	( pkt len srvaddr )
      tftp-from-addr insock>addr,port insock-init true	( pkt len true )
   else							( pkt len srvaddr )
      tftp-from-addr insock=  if			( pkt len )
         true						( pkt len true )
      else						( pkt len )
         tftp-from-addr tftp-send-error  2drop false	( false )
      then						( pkt len true | false )
   then							( pkt len true | false )
;

: tftp-receive-data ( -- pkt len true | false )
   (tftp-receive-data)  if			( pkt len )
      over >tftp-block# ntohw@  dup >r		( pkt len blk ) ( r: blk )
      tftp-nextblk# @ =  if			( pkt len )
         1 tftp-nextblk# +!  true		( pkt len true )
      else					( pkt len )
         2drop false				( false )
      then					( pkt len true | false )
      r> tftp-send-ack				( pkt len true | false ) ( r: )
   else						( )
      false					( false )
   then						( pkt len true | false )
;

\ Wait for a DATA packet to arrive.
: (tftp-read-data) ( -- data datalen true | false )
   begin  tftp-timer timer-expired? 0=  while		( )
      tftp-receive-data if				( pkt len )
         /tftp-header encapsulated-data true exit	( data datalen true )
      then						( )
   repeat  false					( false )
;

\ Copy TFTP segment data to memory and check if there's more data to come.
: tftp-read-data ( adr -- adr' more? )
   tftp-timer d# 4000 set-timer				( adr )
   begin  (tftp-read-data) 0=  while			( adr )
      tftp-retransmit-packet  tftp-backoff		( adr )
   repeat						( adr data datalen )
   >r  over r@ move  r@ ca+  r> TFTP_SEGSIZE =		( adr' more? )
;

: tftp-read ( adr filename$ -- size )
   " octet" 2swap tftp-send-rrq				( adr )
   dup  begin  tftp-read-data  while			( adr adr' )
      show-progress					( adr adr' )
   repeat  swap -					( size )
;

: tftp-load ( adr filename$ siaddr -- size )
   tftp-init						( adr filename$ )
   ['] tftp-read catch  if				( adr filename$ )
      tftp-close  -1 throw
   then							( size )
   tftp-close						( size )
;

headers
