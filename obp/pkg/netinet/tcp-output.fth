\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-output.fth
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
id: @(#)tcp-output.fth 1.1 04/09/07
purpose: TCP output routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Flags used when sending segments. Basic flags are determined by state. A
\ FIN is sent only if all data queued for output is included in the segment.
create tcp-outflags
   TH_RST TH_ACK or     c,          \ CLOSED
   0                    c,          \ LISTEN
   TH_SYN               c,          \ SYN_SENT
   TH_SYN TH_ACK or     c,          \ SYN_RCVD
   TH_ACK               c,          \ ESTABLISHED
   TH_ACK               c,          \ CLOSE_WAIT
   TH_FIN TH_ACK or     c,          \ FIN_WAIT_1
   TH_FIN TH_ACK or     c,          \ CLOSING
   TH_FIN TH_ACK or     c,          \ LAST_ACK
   TH_ACK               c,          \ FIN_WAIT_2
   TH_ACK               c,          \ TIME_WAIT

: tcp-outflags@ ( tcb -- flags )  tcp-outflags  swap tcb-state@ ca+  c@ ;

\ Fill options in outgoing SYN.
: tcp-fill-options ( tcb pkt -- )
   dup is-tcpsyn?  if						( tcb pkt )
      swap tcb-mss@  over dup tcpip-hlen@ ca+			( pkt mss adr )
      TCPOPT_MSS over c!  ca1+  4 over c!  ca1+  htonw!		( pkt )
      dup tcp-hlen@  4 +  swap tcp-hlen!			( )
   else								( tcb pkt )
      2drop							( )
   then								( )
;

\ Set retransmission timer based on current RTO value.
: tcp-set-rexmit-timer ( tcb -- )
   dup >tcbt-rexmit  swap tcb-rto@  set-timer
;

\ Cancel retranmission timer event.
: tcp-clear-rexmit-timer ( tcb -- )
   >tcbt-rexmit clear-timer  drop
;

\ Determine the location (as offset in current send window) and size of 
\ data that can be sent in a segment. The usable send window is the minimum 
\ of the offered and congestion windows, minus any data in flight. The 
\ size of data we could send is the minimum of the usable window, the MSS, 
\ or the amount of data at hand.

: tcp-snddata,len ( tcb -- offset len )
   dup >r						( tcb ) ( r: tcb )
   tcb>sndbuf tcpbuf-count@				( nbytes )
   r@  dup snd-nxt@  swap snd-una@ -			( nbytes #sent )
   tuck -  swap						( tosend #sent )
   r@  dup snd-wnd@  swap snd-cwnd@  min  over -	( tosend #sent wnd )
   rot  min   0 max					( #sent cansend )
   r>  tcb-mss@  min					( #sent len ) ( r: )
;

\ Fill segment data.
: tcp-fill-segdata ( tcb pkt -- datalen )
   over tcp-snddata,len  ?dup if		( tcb pkt offset len )
      >r >r					( tcb pkt ) ( r: len offset )
      dup tcpip-hlen@ ca+  swap tcb>sndbuf	( adr buf )
      r> rot r> tcpbuf-read			( len' ) ( r: )
   else						( tcb pkt offset )
      3drop 0					( 0 )
   then						( datalen )
;

\ Format segment that must be sent. Set PSH if all data in the send buffer 
\ is being sent in this segment. If the send buffer is not being emptied
\ by this output operation, clear FIN (in case it is set by tcp-outflags).

: tcp-fill-segment ( tcb pkt -- )
   >r
   IPPROTO_TCP              r@ >ip-protocol  c!			( tcb )
   my-ip-addr               r@ >ip-src       copy-ip-addr	( tcb )
   dup tcb>inpcb >in-faddr  r@ >ip-dest      copy-ip-addr	( tcb )
   IP_DEFAULT_TTL           r@ >ip-ttl       c!			( tcb )
   0                        r@ >ip-service   c!			( tcb )
   dup tcb>inpcb in-lport@  r@ >tcp-sport    htonw!		( tcb )
   dup tcb>inpcb in-fport@  r@ >tcp-dport    htonw!		( tcb )
   dup snd-nxt@             r@ >tcp-seq      htonl!		( tcb )
   dup rcv-nxt@             r@ >tcp-ack      htonl!		( tcb )
   dup rcv-wnd@             r@ >tcp-window   htonw!		( tcb )
   0                        r@ >tcp-urgptr   htonw!		( tcb )
   /tcp-header 2 lshift     r@ >tcp-offset   c!			( tcb )
   dup tcp-outflags@        r@ >tcp-flags    c!			( tcb )

   dup r@  tcp-fill-options					( tcb )
   dup r@  tcp-fill-segdata					( tcb len )
   r@ tcpip-hlen@  over +   r@ >ip-len       htonw!		( tcb len )

   ?dup  if							( tcb len )
      over snd-nxt@ +						( tcb s1 )
      over dup tcb>sndbuf tcpbuf-count@  swap snd-una@ +	( tcb s1 s2 )
      2dup  seq<  if						( tcb s1 s2 )
         2drop  r@ TH_FIN tcp-clear-flags			( tcb )
      else							( tcb s1 s2 )
         seq=  if						( tcb )
            r@ tcp-flags@  TH_PSH or  r@ tcp-flags!		( tcb )
         then							( tcb )
      then  							( tcb )
   then  drop							( )

   0                        r@ >tcp-cksum   htonw!		( )
   r@ tcp-checksum          r@ >tcp-cksum   htonw!		( )
   r> drop							( ) ( r: )
;

\ Determine if a segment must be sent. A segment must be sent if we need
\ to transmit data, critical controls (SYN, FIN or RST), or if we owe
\ peer an ACK. If we are sending data, we send more only if all outstanding
\ data has been acknowledged or we can send a full-sized segment.

: tcp-send-segment? ( tcb -- flag )
   \ Send if we owe peer an ACK
   dup tcb-flags@ TF_ACKNOW and  if  drop true exit  then	( tcb )

   \ Send if we need to send a SYN or RST
   dup tcp-outflags@  TH_SYN TH_RST or  and  if			( tcb )
      drop true exit						( true )
   then								( tcb )
   
   \ If we need to send a FIN but haven't yet done so, or we are
   \ retransmitting the FIN, we need to send this segment.
   dup tcp-outflags@ TH_FIN and  if				( tcb )
      dup tcb-flags@ TF_SENTFIN and 0=  if			( tcb )
         drop true exit						( true )
      then							( tcb )
      dup snd-nxt@  over snd-una@  seq=  if			( tcb )
         drop true exit						( true )
      then							( tcb  )
   then								( tcb )

   \ Determine length of data we can send in this segment
   dup  tcp-snddata,len nip					( tcb len )

   \ If there is unacknowledged data, we can send if we
   \ have at least one full-sized segment to send.
   over dup snd-nxt@  swap snd-una@ -  if			( tcb len )
      2dup swap tcb-mss@ <  if					( tcb len )
         2drop false exit					( false )
      then							( tcb len )
   then								( tcb len )

   \ Send segment if it contains data
   nip  0<>                                                     ( flag )
;

\ Compute receive window size to be advertised. Never shrink the window,
\ and perform receive side SWS avoidance. Don't advertise a window
\ larger than the one we are currently advertising (which can be 0) until
\ the window can be increased by either one segment or by one-half of
\ the receive buffer space.

: tcp-rwindow-update ( tcb -- )
   dup tcb>rcvbuf						( tcb buf )
   2dup tcpbuf-space@  swap rcv-wnd@ -				( tcb buf incr )
   >r  tcpbuf-size@ 2/  over tcb-mss@ min  r> tuck swap >=  if	( tcb incr )
      over rcv-wnd@  +  swap rcv-wnd!				( )
   else								( tcb incr )
      2drop
   then
;

\ Format and send the TCP segment. If we are sending data or SYN/FIN
\ segments, schedule retransmission and arrange to gather round trip
\ time estimates.

: tcp-send-segment ( tcb -- )

   \ Allocate a packet buffer
   pkt-alloc ?dup 0=  if  drop exit  then		( tcb pkt )

   \ Dont use a new sequence number if resending a FIN.
   swap  dup tcp-outflags@ TH_FIN and  if		( pkt tcb )
      dup tcb-flags@ TF_SENTFIN and  if			( pkt tcb )
         dup snd-nxt@  over snd-max@  seq=  if		( pkt tcb )
            dup snd-nxt@ 1-  over snd-nxt!		( pkt tcb )
         then						( pkt tcb )
      then						( pkt tcb )
   then  swap						( tcb pkt )

   \ Determine window size to advertise.
   over tcp-rwindow-update				( tcb pkt )

   \ Fill in the segment.
   2dup tcp-fill-segment				( tcb pkt )

   \ Mark transmission of FIN.
   tuck is-tcpfin? if					( pkt tcb )
      dup TF_SENTFIN tcb-set-flags			( pkt tcb )
   then							( pkt tcb )

   \ Advance SND.NXT over sequence space of this segment.
   over seg-len@  over snd-nxt@ +  over snd-nxt!	( pkt tcb )

   \ Update SND.MAX, and time this transmission if this is
   \ not a retransmission and we are not timing anything.
   dup snd-nxt@  over snd-max@  seq>  if		( pkt tcb )
      dup snd-nxt@  over snd-max!			( pkt tcb )
      dup tcb-flags@ TF_RTTGET and  0= if		( pkt tcb )
         dup TF_RTTGET tcb-set-flags			( pkt tcb )
         over seg-seq@  over >tcb-rttseq l!		( pkt tcb )
      then						( pkt tcb )
   then							( pkt tcb )

   \ Set retransmit timer if it isn't currently set and
   \ this is not just an ACK.
   over seg-len@ 0<>  if				( pkt tcb )
      dup >tcbt-rexmit timer-running? 0=  if		( pkt tcb )
         dup tcp-set-rexmit-timer			( pkt tcb )
      then						( pkt tcb )
   then  swap						( tcb pkt )

   2dup TR_OUTPUT 0 tcp-trace				( tcb pkt )

   \ Send the segment. Any pending ACK has now been sent. 
   \ Failures are recorded in the TCB.
   ip-output  dup 0<  if				( tcb error# )
      swap tcb-error!					( )
   else							( tcb #sent )
      drop  TF_ACKNOW TF_DELACK or tcb-clear-flags	( )
   then							( )
;

\ Generate an acceptable reset (RST) in response to a bad incoming packet.
\ A RST is never sent in response to a RST.

: tcp-reset ( tcb pkt -- )
   dup is-tcprst?     if  2drop exit  then		( tcb pkt )
   pkt-alloc ?dup 0=  if  2drop exit  then   		( tcb pkt rstpkt )

   IPPROTO_TCP             over >ip-protocol  c!
   my-ip-addr              over >ip-src       copy-ip-addr
   over >ip-src            over >ip-dest      copy-ip-addr
   IP_DEFAULT_TTL          over >ip-ttl       c!
   0                       over >ip-service   c!
   over >tcp-dport ntohw@  over >tcp-sport    htonw!
   over >tcp-sport ntohw@  over >tcp-dport    htonw!

   over is-tcpack?  if
      over seg-ack@        over >tcp-seq      htonl!
      TH_RST               over >tcp-flags    c!
   else
      0                    over >tcp-seq      htonl!
      TH_RST TH_ACK or     over >tcp-flags    c!
   then							( tcb pkt rstpkt )
   swap seg-lastseq@ 1+    over >tcp-ack      htonl!	( tcb rstpkt )

   0                       over >tcp-window   htonw!    
   0                       over >tcp-urgptr   htonw!
   /tcp-header 2 lshift    over >tcp-offset   c!
   0                       over >tcp-cksum    htonw!
   /tcpip-header           over >ip-len       htonw!
   dup tcp-checksum        over >tcp-cksum    htonw!	( tcb rstpkt )

   tuck TR_OUTPUT 0 tcp-trace				( rstpkt ) 

   ip-output  drop					( )
;

\ TCP output routine. Send all the data we can.
: tcp-output ( tcb -- )
   dup  tcb>sndbuf tcpbuf-count@			( tcb nbytes )
   over dup snd-nxt@  swap snd-una@ - -			( tcb #unsent )
   over tcb-mss@ >  if					( tcb )
      begin  dup tcp-send-segment?  while		( tcb )
         dup tcp-send-segment				( tcb )
      repeat  drop					( )
   else							( tcb )
      dup tcp-send-segment?  if				( tcb )
         dup tcp-send-segment				( tcb )
      then  drop					( )
   then  						( )
;

\ Force the connection to be dropped, reporting the specified error.
\ If the connection is synchronized, then a RST must be sent to peer.

: tcp-drop ( tcb error# -- )
   swap  dup tcb-state@ TCPS_SYN_RCVD >=  if		( error# tcb )
      TCPS_CLOSED over tcb-state!			( error# tcb )
      dup tcp-output					( error# tcb )
   then							( error# tcb )
   dup tcb-kill-timers					( error# tcb )
   tcb-error!						( )
;

\ Handle retransmission timeouts.
: tcp-retransmit ( tcb -- )

   \ Clear timer and apply backoff.
   dup tcp-clear-rexmit-timer  dup tcp-backoff		( tcb )

   \ Enforce maximum retransmission count.
   dup >tcb-nrexmits l@  1+  dup TCP_MAXRETRIES >  if	( tcb ntries )
      drop  ETIMEDOUT tcp-drop  exit			( )
   then  over >tcb-nrexmits l!				( tcb )

   \ Reduce ssthresh to max(flightsize/2, 2*mss)
   dup snd-nxt@  over snd-una@ -  2/			( tcb flightsize/2 )
   over tcb-mss@ 2*  max  over ssthresh!		( tcb )

   \ Shrink congestion window to 1 segment.
   dup tcb-mss@  over snd-cwnd!				( tcb )

   \ Force retransmission of oldest unacknowledged data.
   dup snd-una@  over snd-nxt!				( tcb )
   tcp-output						( )
;

headers
