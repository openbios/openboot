\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sockif.fth
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
id: @(#)sockif.fth 1.1 04/09/07
purpose: Generic socket interface
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0     constant  PRREQ_ATTACH	\ New socket has been created
1     constant  PRREQ_DETACH	\ Socket is being closed
2     constant  PRREQ_BIND	\ Bind local address to socket
3     constant  PRREQ_CONNECT	\ Accept connection (SOCK_STREAM only)
d# 4  constant  PRREQ_LISTEN	\ Listen for connections (SOCK_STREAM only)
d# 5  constant  PRREQ_ACCEPT	\ Accept connection from peer
d# 6  constant  PRREQ_SEND	\ Send data on connected socket
d# 7  constant  PRREQ_SENDTO	\ Send data
d# 8  constant  PRREQ_RECV	\ Receive data from connected socket
d# 9  constant  PRREQ_RECVFROM	\ Receive data (Non-blocking)

fload ${BP}/pkg/netinet/udp-reqs.fth
fload ${BP}/pkg/netinet/tcp-reqs.fth

headerless

: soreq-execute ( ?? sockaddr req# -- ?? )
   swap  >so-type w@  case
      SOCK_STREAM  of  tcp-prreq-execute  endof
      SOCK_DGRAM   of  udp-prreq-execute  endof
      ( default ) ." Unknown socket type" -1 throw
   endcase
;

\ Create a socket.
: socreate ( family type protocol -- sockaddr )
   /socket dup alloc-mem  tuck swap erase	( family type proto sockaddr )
   tuck >so-protocol w!				( family type sockaddr )
   tuck >so-type     w!				( family sockaddr )
   tuck >so-family   w!				( sockaddr )
   dup dup PRREQ_ATTACH soreq-execute		( sockaddr )
;

\ Close a socket and terminate connection.
: soclose ( sockaddr -- )
   dup dup PRREQ_DETACH soreq-execute		( sockaddr )
   /socket free-mem				( )
;

\ Assign a local protocol address to a socket.
: sobind ( sockaddr addr addrlen -- )
   2 pick PRREQ_BIND soreq-execute
;

\ Initiate a connection on a socket.
: soconnect ( sockaddr srvaddr addrlen -- 0 | error# )
   2 pick dup >r  PRREQ_CONNECT soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Listen for connections on a socket. 
: solisten ( sockaddr backlog -- 0 | error# )
   over dup >r  PRREQ_LISTEN soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Accept a connection on a socket. This implementation does not create 
\ a new socket (i.e, the listening socket is the connected socket).
: soaccept ( sockaddr fromaddr addrlen -- 0 | error# )
   2 pick dup >r  PRREQ_ACCEPT soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Send a message from a socket. Used with connected sockets.
: sosend ( sockaddr buf nbytes flags -- #sent | error# )
   3 pick dup >r  PRREQ_SEND soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Send a message from a socket.
: sosendto ( sockaddr buf nbytes flags toaddr addrlen -- #sent | error# )
   5 pick dup >r  PRREQ_SENDTO soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Receive a message from a socket. Blocking.
: sorecv ( sockaddr buf nbytes flags -- #rcvd | error# )
   3 pick dup >r  PRREQ_RECV soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Receive a message from a socket. Non-blocking.
: sorecvfrom ( sockaddr buf nbytes flags fromaddr addrlen -- #rcvd | error# )
   5 pick dup >r  PRREQ_RECVFROM soreq-execute  dup 0<  if
      dup r@ soerror!
   then  r> drop
;

\ Decode error on connection.
: .soerror ( sockaddr -- )
   soerror@ case
      EHOSTUNREACH of  ." (Host is unreachable)"             endof
      ECONNREFUSED of  ." (Connection refused)"              endof
      ETIMEDOUT    of  ." (Connection timed out)"            endof
      ECONNRESET   of  ." (Connection reset)"                endof
      EOPNOTSUPP   of  ." (Socket operation not supported)"  endof
   endcase
;

headers
