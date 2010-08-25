\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: inpcb.fth
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
id: @(#)inpcb.fth 1.1 04/09/07
purpose: Internet protocol control block representation
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ An Internet Protocol Control Block (INPCB) is associated with each
\ socket. It holds information about local and remote endpoints for
\ this connection and pointers to the associated socket and protocol
\ specific control block structures.
\
\ TCP maintains state information for a connection in TCP Control
\ Blocks (TCBs). UDP maintains a queue of datagrams addressed to
\ the socket in UDP Control Blocks (UCBs).
\
\ All INPCBs for a particular protocol are held in doubly linked lists
\ maintained by that protocol. 

headerless

struct
   /queue-entry  field  >in-pcblist	\ Doubly linked INPCB list
   /n            field  >in-socket	\ Back pointer to socket
   /n            field  >in-ppcb	\ Pointer to per-protocol PCB 
   /ip-addr      field  >in-faddr	\ Remote IP, network byte ordered
   /w            field  >in-fport	\ Remote port, network byte ordered
   /ip-addr      field  >in-laddr	\ Local IP, network byte ordered
   /w            field  >in-lport	\ Local port, network byte ordered
constant /inpcb

: inpcb>so ( inpcb -- sockaddr )  >in-socket @ ;

: in-lport@ ( inpcb -- port )  >in-lport ntohw@ ;
: in-fport@ ( inpcb -- port )  >in-fport ntohw@ ;

\ Allocate an INPCB for a protocol.
: inpcb-alloc ( qhead -- inpcb )
   /inpcb dup alloc-mem tuck swap erase		( qhead inpcb )
   tuck enqueue					( inpcb )
;

\ Deallocate an INPCB.
: inpcb-free ( inpcb -- )
   dup remqueue					( inpcb )
   /inpcb free-mem				( )
;

\ Bind local address and port number to a socket.
: inpcb-bind ( inpcb laddr lport -- )
   nip  over >in-lport htonw!   my-ip-addr swap >in-laddr copy-ip-addr
;

\ Record remote IP address and port number for a socket.
: inpcb-connect ( inpcb faddr fport -- )
   swap dup inaddr-any?  if  drop inaddr-broadcast  then
   rot  tuck >in-faddr copy-ip-addr  >in-fport htonw!
;

\ Disconnect from remote address and port number.
: inpcb-disconnect ( inpcb -- )
   0 over >in-fport htonw!  inaddr-any swap >in-faddr copy-ip-addr
;

\ Return local address and port number.
: in-getsockaddr ( inpcb insock -- )
   swap  dup >in-laddr  swap in-lport@  insock-init
;

\ Return foreign address and port number.
: in-getpeeraddr ( inpcb insock -- )
   swap  dup >in-faddr  swap in-fport@  insock-init
;

[ifdef] DEBUG
: .inpcb ( inpcb -- )
   dup >in-laddr .ipaddr  2 spaces  dup in-lport@ .d  2 spaces
   dup >in-faddr .ipaddr  2 spaces      in-fport@ .d  cr
;
[then]

headers
