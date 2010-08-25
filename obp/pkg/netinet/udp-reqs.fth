\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: udp-reqs.fth
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
id: @(#)udp-reqs.fth 1.1 04/09/07
purpose: UDP socket interface
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0  value  udp-last-port#	\ Last UDP port number assigned

: udp-next-port ( -- port# )
   udp-last-port# 1+  dup d# 32768 d# 65535 between  0= if
      drop d# 32768
   then  dup to udp-last-port#
;

\ Allocate/initialize protocol control blocks and link structures together. 
: udp-soattach ( sockaddr -- )
   udp-inpcb-list inpcb-alloc			( sockaddr inpcb )
   ucb-alloc					( sockaddr inpcb ucb )
   2dup >ucb-inpcb !  over >in-ppcb !		( sockaddr inpcb )
   2dup >in-socket !  swap >so-inpcb !		( )
;

\ Deallocate Internet PCB and UDP control blocks.
: udp-sodetach ( sockaddr -- )
   dup so>inpcb					( sockaddr inpcb )
   dup inpcb>ucb ucb-free			( sockaddr inpcb )
   inpcb-free					( sockaddr )
   0 swap >so-inpcb !				( )
;

\ Bind local address and port number to socket.
: udp-sobind ( sockaddr addr addrlen -- )
   drop  insock>addr,port  dup 0=  if		( sockaddr addr port )
      drop udp-next-port			( sockaddr addr lport )
   then						( sockaddr addr lport )
   rot so>inpcb -rot inpcb-bind	 		( )
;

\ Send data to specified endpoint. The unconnected socket is temporarily 
\ connected to the specified destination.
: udp-sosendto ( sockaddr buf nbytes flags toaddr tolen -- #sent | error# )
   drop nip					( sockaddr buf nbytes toaddr )
   >r  rot so>inpcb  r>				( buf nbytes inpcb toaddr )
   over swap insock>addr,port inpcb-connect	( buf nbytes inpcb )
   dup 2swap udp-output				( inpcb #sent )
   swap inpcb-disconnect			( #sent )
;

\ Copy data from the datagram to the user buffer.
: udp-getdata ( pkt buf nbytes -- nread )
   rot dup ip-len@				( buf len pkt pktlen )
   /udpip-header encapsulated-data		( buf len data datalen )
   2swap rot min  dup >r  move  r>		( len' )
;

\ Get source of the message.
: udp-getpeeraddr ( pkt peeraddr addrlen -- )
   /insock swap l!					( pkt peeraddr )
   swap dup >ip-src swap >udp-sport ntohw@ insock-init	( )
;

\ Receive a message on the UDP socket. The entire message should be read
\ in one single operation.  If the message is longer than the size of
\ the buffer, excess data will be discarded. If the source of the
\ message is requested, get that information from the datagram. 

: udp-sorecvfrom ( sockaddr buf nbytes flags from fromlen -- nread )
   >r >r drop					( sockaddr buf nbytes )
   rot so>ucb					( buf nbytes ucb )	
   dup >ucb-dgramq queue-empty? if		( buf nbytes ucb )
      udp-poll					( buf nbytes ucb )
   then						( buf nbytes ucb )
   >ucb-dgramq pkt-dequeue ?dup if		( buf nbytes pkt ) 
      dup 2swap udp-getdata			( pkt nread )
      over r> r> over if			( pkt nread pkt from fromlen )
         udp-getpeeraddr			( pkt nread )
      else					( pkt nread pkt from fromlen )
         3drop					( pkt nread )
      then					( pkt nread )
      swap pkt-free				( nread )
   else						( buf nbytes )
      2drop r> r> 2drop 0			( 0 ) ( r: )
   then						( nread )
;

\ Process a UDP user request.
: udp-prreq-execute ( ?? req# -- ?? )
   case
      PRREQ_RECVFROM of  udp-sorecvfrom          endof
      PRREQ_SENDTO   of  udp-sosendto            endof
      PRREQ_ATTACH   of  udp-soattach            endof
      PRREQ_DETACH   of  udp-sodetach            endof
      PRREQ_BIND     of  udp-sobind              endof
      PRREQ_CONNECT  of  3drop EOPNOTSUPP        endof	\ Not supported
      PRREQ_SEND     of  2drop 2drop EOPNOTSUPP  endof	\ Not supported
      PRREQ_RECV     of  2drop 2drop EOPNOTSUPP  endof	\ Not supported
      PRREQ_LISTEN   of  2drop EOPNOTSUPP        endof	\ Not applicable
      PRREQ_ACCEPT   of  3drop EOPNOTSUPP        endof	\ Not applicable
   endcase
;

headers
