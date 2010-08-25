\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp.fth
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
id: @(#)tcp.fth 1.1 04/09/07
purpose: TCP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 793: Transmission Control Protocol

fload ${BP}/pkg/netinet/tcp-h.fth
fload ${BP}/pkg/netinet/tcpbuf.fth
fload ${BP}/pkg/netinet/tcb.fth
fload ${BP}/pkg/netinet/tcp-trace.fth

headerless

/queue-head  instance buffer:  tcp-inpcb-list	\ Head of TCP's INPCB list

: tcp-init ( -- )
   tcp-inpcb-list queue-init
[ifdef] DEBUG
   tcptrace-init
[then]
;

: tcp-close ( -- )  ;

\ Compute TCP packet checksum.
: tcp-checksum ( ip-pkt -- chksum )
   IPPROTO_TCP  over >ip-src  /ip-addr    (in-cksum)
                over >ip-dest /ip-addr    (in-cksum)
   swap  ippkt>payload  rot over +  -rot  in-cksum
;

\ ISN selection. This must be a reasonably random number.
: tcp-iss ( -- iss )  random ;

\ Initialize TCP send sequence variables.
: tcp-sendseq-init ( tcb -- )
   tcp-iss swap  2dup snd-una!  2dup snd-nxt!  2dup snd-wl2!  snd-max!
;

\ Estimating mean round trip time and variance. Use the "fast algorithm
\ for RTT mean and variation" from "Congestion Avoidance and Control",
\ Jacobson, V. and M. Karels, Nov 1988.
\
\ SRTT and RTTVAR are stored as fixed point numbers with scaling factors
\ of 8 and 4 respectively. On the first RTT measurement (SRTT = 0), the 
\ values stored in SRTT and RTTVAR reflect their scaling factors. For 
\ subsequent measurements, the code becomes 
\
\	error = measurement - (average >> 3);
\	average = average + error;
\	if (error < 0)
\		error = -error;
\	error = error - (variance >> 2);
\	variance = variance + error;
\	RTO = (average >> 3) + variance;
\
\ reflecting alpha = 1/8, beta = 1/4, and RTO = A + 4D. 

\ Set next retransmission timeout interval, enforcing lower and upper
\ bounds for the timeout.
: tcp-set-rto ( tcb rto -- ) d# 1000 max  d# 60000 min  swap tcb-rto! ;

\ Update RTT estimators and compute RTO, enforcing lower and upper
\ bounds for the timeout
: tcp-update-rto ( tcb rtt -- )
   2dup swap >tcb-rtt l!				( tcb rtt )
   over tcb-srtt@ 0<>  if				( tcb rtt )
      over tcb-srtt@  3 rshift  -			( tcb error )
      2dup over tcb-srtt@ +  swap tcb-srtt!		( tcb error )
      abs  over tcb-rttvar@  2 rshift -			( tcb error' )
      over tcb-rttvar@ +  over tcb-rttvar!		( tcb )
   else							( tcb rtt )
      2dup 3 lshift  swap tcb-srtt!			( tcb rtt )
      1 lshift       over tcb-rttvar!			( tcb )
   then							( tcb )
   dup tcb-srtt@ 3 rshift  over tcb-rttvar@ +		( tcb rto )
   tcp-set-rto						( )
;

\ Back off the timer on retransmissions.
: tcp-backoff ( tcb -- )  dup tcb-rto@ 2*  tcp-set-rto ;

headers

fload ${BP}/pkg/netinet/tcp-output.fth
fload ${BP}/pkg/netinet/tcp-timer.fth
fload ${BP}/pkg/netinet/tcp-input.fth

headerless

: tcp-connected? ( tcb -- flag )
   tcb-state@  TCPS_ESTABLISHED =
;

: tcp-disconnected? ( tcb -- flag )
   tcb-state@  dup TCPS_CLOSED =  swap TCPS_TIME_WAIT =  or
;

\ Process packets until desired state is reached or an error is seen.
: tcp-state-wait ( tcb acf -- )
   begin						( tcb acf )
      2dup execute 0=  2 pick tcb-error@ 0=  and	( tcb acf flag )
   while						( tcb acf )
      tcp-poll						( tcb acf )
   repeat  2drop					( )
;

\ Pushed data can be delivered if we have received all data up through 
\ the recorded push sequence. 

: tcp-pushdata? ( tcb -- flag )
   dup tcb-flags@ TF_PUSH and  if			( tcb )
      dup rcv-nxt@  swap >tcb-pushseq l@  seq>=		( flag )
   else							( tcb )
      drop false					( false )
   then							( flag )
;

\ Check if the read request can be satisfied. Data in the receive
\ buffer can be read if we have enough data, or we are not expecting
\ any more data, or data is being pushed. 

: tcp-cangetdata? ( tcb len -- cangetdata? )
   over tcb-error@ 0=  if				( tcb len )
      over tcb>rcvbuf tcpbuf-count@ <=			( tcb flag )
      over tcp-pushdata? or				( tcb flag' )
      swap tcp-receive-done?  or			( cangetdata? )
   else							( tcb len )
      2drop false					( false )
   then							( cangetdata? )
;

\ Copy data from TCP receive buffer to an user buffer. If the window can
\ now be opened up at least 50% of the maximum window we ever advertised,
\ send a window update. 
 
: tcp-getdata ( tcb adr len -- nread )
   rot >r						( adr len ) ( r: tcb )

   \ Read data from the receive buffer
   r@ tcb>rcvbuf  dup  2swap 0 -rot tcpbuf-read		( buf nread )
   2dup tcpbuf-drop					( buf nread )

   \ Clear PUSH state if all outstanding data has been
   \ delivered to the application.
   over tcpbuf-count@ 0=  if				( buf nread )
      r@ TF_PUSH tcb-clear-flags			( buf nread )
   then							( buf nread )

   \ Schedule a window update if one can be sent. 
   over tcpbuf-space@ r@ rcv-wnd@ -			( buf nread incr )
   rot  tcpbuf-size@ 2/  >=  if				( nread )
      r@ TF_ACKNOW tcb-set-flags			( nread )
   then							( nread )

   r> tcp-output					( nread ) ( r: )
;

\ Check if we can accept a send request. 
: tcp-canputdata? ( tcb len -- flag )
   over tcb-error@ 0=  if			( tcb len )
      swap  tcb>sndbuf  tcpbuf-space@  <=	( flag )
   else						( tcb len )
      2drop false				( false )
   then						( flag )
;

\ Copy data from an user buffer to the end of the send buffer.
: tcp-putdata ( tcb adr len -- len' )
   rot tcb>sndbuf  dup >r			( adr len buf ) ( r: buf )
   dup tcpbuf-count@  2swap  tcpbuf-write	( len' )
   r> over tcpbuf-count+!			( len' ) ( r: )
;

\ Initiate a connection. 
: tcp-open-connection ( tcb -- 0 | error )
   tcp-start-timers					( tcb )
   dup tcp-sendseq-init					( tcb )
   dup >tcbt-connect TCP_CONN_TIMEOUT set-timer		( tcb )
   TCPS_SYN_SENT over tcb-state!			( tcb )
   dup tcp-output					( tcb )
   dup ['] tcp-connected? tcp-state-wait		( tcb )
   dup >tcbt-connect clear-timer drop			( tcb )
   tcb-error@						( result )
;

\ Accept incoming connections.
: tcp-accept-connection ( tcb -- 0 | error# )
   tcp-start-timers					( tcb )
   dup ['] tcp-connected? tcp-state-wait		( tcb )
   tcb-error@						( result )
;

\ Initiate a TCP disconnect.
: tcp-disconnect ( tcb -- )
   dup tcb-state@  case
      TCPS_SYN_RCVD    of  TCPS_FIN_WAIT_1 over tcb-state!  endof
      TCPS_ESTABLISHED of  TCPS_FIN_WAIT_1 over tcb-state!  endof
      TCPS_CLOSE_WAIT  of  TCPS_LAST_ACK   over tcb-state!  endof
   endcase
   tcp-output
;

\ Close a connection.
: tcp-close-connection ( tcb -- )
   tcp-drain-input					( tcb )
   dup tcb-state@  TCPS_SYN_SENT <=  if			( tcb )
      TCPS_CLOSED swap tcb-state!			( )
   else							( tcb )
      dup tcb>rcvbuf tcpbuf-count@ 0<>	if		( tcb )
         TCPS_CLOSED over tcb-state!  tcp-output	( )
         tcp-drain-input				( )
      else						( tcb )
         dup tcp-disconnect				( tcb )
         ['] tcp-disconnected? tcp-state-wait		( )
      then						( )
   then							( )
;

fload ${BP}/pkg/netinet/tcp-debug.fth	\ Post-mortem debugging routines

headers
