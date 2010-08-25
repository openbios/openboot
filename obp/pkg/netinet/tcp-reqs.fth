\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-reqs.fth
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
id: @(#)tcp-reqs.fth 1.1 04/09/07
purpose: TCP socket interface
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0  value  tcp-last-port#	\ Last TCP port number assigned

: tcp-next-port ( -- port# )
   tcp-last-port# 1+  dup d# 32768 d# 65535 between  0= if
      drop d# 32768
   then  dup to tcp-last-port#
;

\ Allocate/initialize protocol control blocks and link structures together. 
: tcp-soattach ( sockaddr -- )
   tcp-inpcb-list inpcb-alloc			( sockaddr inpcb )
   tcb-alloc					( sockaddr inpcb tcb )
   2dup >tcb-inpcb !  over >in-ppcb !		( sockaddr inpcb )
   2dup >in-socket !  swap >so-inpcb !		( )
;

\ Close connection and deallocate Internet PCB and TCP control blocks. 
: tcp-sodetach ( sockaddr -- )
   dup so>tcb 0 TR_SOCKET PRREQ_DETACH tcp-trace	( sockaddr )
   dup so>tcb dup tcp-close-connection			( sockaddr tcb )
   dup tcb>inpcb  swap tcb-free  inpcb-free		( sockaddr )
   0 swap >so-inpcb !					( )
;

\ Bind local address and port number to socket.
: tcp-sobind ( sockaddr addr addrlen -- )
   drop  insock>addr,port  dup 0=  if		( sockaddr addr port )
      drop tcp-next-port			( sockaddr addr lport )
   then						( sockaddr addr lport )
   rot  so>inpcb  -rot  inpcb-bind  		( )
;

\ Prepare to accept incoming connections. Only one pending connection 
\ is supported.
: tcp-solisten ( sockaddr backlog -- 0 )
   drop  dup so>inpcb  dup in-lport@ 0=  if	( sockaddr inpcb )
      my-ip-addr tcp-next-port inpcb-bind	( sockaddr )
   else						( sockaddr inpcb )
      drop					( sockaddr )
   then						( sockaddr )
   TCPS_LISTEN swap so>tcb tcb-state!		( )
   0						( result )
;

\ Accept a connection and return peer's IP address and port number to 
\ caller. A new socket is not created (i.e, the listening socket is
\ the connected socket).
: tcp-soaccept ( sockaddr addr addrlen -- 0 | error# )
   2 pick so>tcb				( sockaddr addr addrlen tcb )
   tcp-accept-connection ?dup if		( sockaddr addr addrlen error#)
      >r  3drop r>				( error# )
   else						( sockaddr addr addrlen )
      /insock swap l!				( sockaddr addr )
      >r so>inpcb r> in-getpeeraddr  0		( 0 )
   then						( 0 | error# )
;

\ Initiate connection to peer.
: tcp-soconnect ( sockaddr srvaddr addrlen -- 0 | error# )
   drop  over so>inpcb swap			( sockaddr inpcb addr )
   over in-lport@ 0=  if			( sockaddr inpcb addr )
      over my-ip-addr tcp-next-port inpcb-bind	( sockaddr inpcb addr )
   then						( sockaddr inpcb addr )
   insock>addr,port inpcb-connect		( sockaddr )
   so>tcb tcp-open-connection			( result )
;

\ Queue data in send buffer and send all the data we can.
: tcp-sosend ( sockaddr buf nbytes flags -- #sent | error# )
   drop  rot  so>tcb  -rot			( tcb buf nbytes )
   2 pick 0 TR_SOCKET PRREQ_SEND tcp-trace	( tcb buf nbytes )
   begin					( tcb buf nbytes )
      2 pick over tcp-canputdata?		( tcb buf nbytes flag )
   0=  while					( tcb buf nbytes )
      2 pick tcb-error@  ?dup  if		( tcb buf nbytes error# )
         >r 3drop r> exit			( error# )
      then					( tcb buf nbytes )
      tcp-poll					( tcb buf nbytes )
   repeat					( tcb buf nbytes )
   2 pick >r  tcp-putdata  r> tcp-output        ( #sent )
;

\ Read data from the receive buffer. Data in the receive buffer can be 
\ read if we have enough data, or we are not expecting any more data, 
\ or if data is being pushed. 
: tcp-soreceive ( sockaddr buf nbytes flags -- #rcvd | error# )
   drop  rot  so>tcb  -rot			( tcb buf nbytes )
   begin					( tcb buf nbytes )
      2 pick over tcp-cangetdata?		( tcb buf nbytes flag )
   0= while					( tcb buf nbytes )
      2 pick tcb-error@  ?dup if		( tcb buf nbytes error# )
         >r 3drop r> exit			( error# )
      then					( tcb buf nbytes )
      tcp-poll					( tcb buf nbytes )
   repeat					( tcb buf nbytes )
   2 pick 0 TR_SOCKET PRREQ_RECV tcp-trace	( tcb buf nbytes )
   tcp-getdata					( #rcvd )
;

\ Process a TCP user request.
: tcp-prreq-execute ( ?? req# -- ?? )
   case
      PRREQ_RECV     of  tcp-soreceive           endof
      PRREQ_SEND     of  tcp-sosend              endof
      PRREQ_ATTACH   of  tcp-soattach            endof
      PRREQ_DETACH   of  tcp-sodetach            endof
      PRREQ_BIND     of  tcp-sobind              endof
      PRREQ_CONNECT  of  tcp-soconnect           endof
      PRREQ_LISTEN   of  tcp-solisten            endof
      PRREQ_ACCEPT   of  tcp-soaccept            endof
      PRREQ_RECVFROM of  3drop 3drop EOPNOTSUPP  endof	\ Not supported
      PRREQ_SENDTO   of  3drop 3drop EOPNOTSUPP  endof	\ Not supported
      ( default ) ." Unknown TCP socket operation"  -1 throw
   endcase
;

headers
