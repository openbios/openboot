\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcb.fth
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
id: @(#)tcb.fth 1.1 04/09/07
purpose: TCP control block management
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ TCP maintains one Transmission Control Block (TCB) for each connection.
\ The TCB contains all state information about the connection: window
\ sizes, sequence numbers in both directions, current round trip time
\ estimate, whether acknowledgement or retransmission is needed etc.
\
\ TCP's send and receive buffers are maintained as circular buffers.
\ The smoothed round trip time (SRTT) and the estimated variance (RTTVAR)
\ are stored as fixed point numbers with scaling factors of 8 and 4
\ respectively.
\
\ Segments can arrive out of order. The sequencing queue stores information
\ about blocks of data as they arrive until it can be assembled into a 
\ contiguous stream.

headerless

\ TCP control block; one per connection
struct
   /w           field  >tcb-state	\ TCP FSM state
   /w           field  >tcb-flags	\ TCP state flags
   /l           field  >tcb-error	\ Error flags
   /n           field  >tcb-inpcb	\ Backpointer to INPCB

   /queue-head  field  >tcb-segq	\ Sequencing queue 
   /tcp-buffer  field  >tcb-rcvbuf	\ Receive buffer (circular)
   /l           field  >rcv-nxt		\ Expected seq# on incoming segment 
   /l           field  >rcv-wnd		\ Current receive window
   /l           field  >tcb-pushseq	\ PUSH sequence number, if TF_PUSH 
   /l           field  >tcb-finseq	\ FIN sequence number, if TF_RCVDFIN
   /l           field  >tcb-mss		\ Maximum segment size

   /tcp-buffer  field  >tcb-sndbuf	\ Send buffer (circular)
   /l           field  >snd-una		\ Send Unacknowledged
   /l           field  >snd-nxt		\ Send Next
   /l           field  >snd-wnd		\ Send Window
   /l           field  >snd-wl1		\ Seq# used for last window update
   /l           field  >snd-wl2		\ Ack# used for last window update
   /l           field  >snd-cwnd	\ Congestion window
   /l           field  >ssthresh	\ Slow start threshold
   /l           field  >snd-max		\ Highest sequence number sent

   /timer       field  >tcbt-rexmit	\ Retransmission timer
   /timer       field  >tcbt-connect	\ Connection establishment timer
   /l           field  >tcb-nrexmits	\ Number of retransmissions

   /l           field  >tcb-rttseq	\ Sequence number being timed
   /l           field  >tcb-rtt		\ Measured round trip time
   /l           field  >tcb-srtt	\ Smoothed RTT (scaled by 8) 
   /l           field  >tcb-rttvar	\ Variance in RTT (scaled by 4) 
   /l           field  >tcb-rto		\ Current retransmission timeout
constant /tcp-control-block
	
\ Sequencing queue entry
struct
    /queue-entry  field  >tseg-link	\ Doubly linked sequencing queue
    /l            field  >tseg-seq	\ Seq number in segment
    /l            field  >tseg-len	\ Segment length
constant /tcp-segq-entry

\ TCP state flags
1      constant  TF_ACKNOW		\ Send ACK immediately
2      constant  TF_DELACK		\ ACK, but try to delay it
h#  4  constant  TF_RCVDFIN		\ FIN has been received
h#  8  constant  TF_SENTFIN		\ FIN has been sent
h# 10  constant  TF_RTTGET		\ A segment is being timed
h# 20  constant  TF_PUSH		\ PSH has been received 

d# 75000  constant  TCP_CONN_TIMEOUT    \ Initial Connection timeout
d# 12     constant  TCP_MAXRETRIES      \ Maximum number of retransmissions

: tcb>inpcb ( tcb -- inpcb )  >tcb-inpcb @ ;
: inpcb>tcb ( inpcb -- tcb )  >in-ppcb @ ;

: so>tcb ( sockaddr -- tcb )  so>inpcb inpcb>tcb ; 

: tcb-state@ ( tcb -- state )  >tcb-state w@ ;
: tcb-state! ( state tcb -- )  >tcb-state w! ;
: tcb-error@ ( error tcb -- )  >tcb-error l@ ;
: tcb-error! ( error tcb -- )  >tcb-error l! ;
: tcb-flags@ ( tcb -- flags )  >tcb-flags w@ ;
: tcb-flags! ( flags tcb -- )  >tcb-flags w! ;

: tcb-set-flags ( tcb flags -- )
   over tcb-flags@  or  swap tcb-flags!
;
: tcb-clear-flags ( tcb flags -- )
   invert  over tcb-flags@  and  swap tcb-flags!
;

: tcb-mss@ ( tcb -- n )  >tcb-mss l@ ;
: tcb-mss! ( n tcb -- )  >tcb-mss l! ;

: tcb>sndbuf ( tcb -- sndbuf )  >tcb-sndbuf ;
: tcb>rcvbuf ( tcb -- rcvbuf )  >tcb-rcvbuf ;

: rcv-nxt@ ( tcb -- n )  >rcv-nxt l@ ;
: rcv-nxt! ( n tcb -- )  >rcv-nxt l! ;
: rcv-wnd@ ( tcb -- n )  >rcv-wnd l@ ;
: rcv-wnd! ( n tcb -- )  >rcv-wnd l! ;

: rcv-lastseq@ ( tcb -- n )  dup rcv-nxt@  swap rcv-wnd@ +  1- ;

: snd-una@  ( tcb -- n )  >snd-una l@ ;
: snd-una!  ( n tcb -- )  >snd-una l! ;
: snd-nxt@  ( tcb -- n )  >snd-nxt l@ ;
: snd-nxt!  ( n tcb -- )  >snd-nxt l! ;
: snd-wl1@  ( tcb -- n )  >snd-wl1 l@ ;
: snd-wl1!  ( n tcb -- )  >snd-wl1 l! ;
: snd-wl2@  ( tcb -- n )  >snd-wl2 l@ ;
: snd-wl2!  ( n tcb -- )  >snd-wl2 l! ;
: snd-wnd@  ( tcb -- n )  >snd-wnd l@ ;
: snd-wnd!  ( n tcb -- )  >snd-wnd l! ;
: snd-max@  ( tcb -- n )  >snd-max l@ ;
: snd-max!  ( n tcb -- )  >snd-max l! ;
: snd-cwnd@ ( tcb -- n )  >snd-cwnd l@ ; 
: snd-cwnd! ( n tcb -- )  >snd-cwnd l! ;
: ssthresh@ ( tcb -- n )  >ssthresh l@ ;
: ssthresh! ( n tcb -- )  >ssthresh l! ;

: tcb-srtt@   ( tcb -- n )  >tcb-srtt l@ ;
: tcb-srtt!   ( n tcb -- )  >tcb-srtt l! ;
: tcb-rttvar@ ( tcb -- n )  >tcb-rttvar l@ ;
: tcb-rttvar! ( n tcb -- )  >tcb-rttvar l! ;
: tcb-rto@    ( tcb -- n )  >tcb-rto l@ ;
: tcb-rto!    ( n tcb -- )  >tcb-rto l! ;

: tcp-retransmitting? ( tcb -- flag ) >tcb-nrexmits l@ 0<> ;

\ Create and initialize a TCP control block. Use a receive buffer size 
\ which is an even multiple of MSS as this increases the percentage of 
\ full-sized segments used during bulk data transfers.
: tcb-alloc ( -- tcb )
   /tcp-control-block dup alloc-mem tuck swap erase	( tcb )
   dup >tcb-segq queue-init				( tcb )

   TCPS_CLOSED              over  tcb-state!		( tcb )
   if-mtu@ /tcpip-header -  over  tcb-mss!		( tcb )

   dup tcb>sndbuf  h# 2000  tcpbuf-init			( tcb )
   h# 4000  over tcb-mss@   tuck 1-  +  over /  *	( tcb rbsize )
   over tcb>rcvbuf  over    tcpbuf-init			( tcb rbsize )

                            over  rcv-wnd!		( tcb )
   dup tcb-mss@             over  snd-cwnd!		( tcb )
   d# 65535                 over  ssthresh!		( tcb )
   d# 3000                  over  tcb-rto!		( tcb )
;

\ Free resources held by a TCP control block.
: tcb-free ( tcb -- )
   dup tcb>sndbuf tcpbuf-free				( tcb )	
   dup tcb>rcvbuf tcpbuf-free				( tcb )
   dup >tcb-segq  begin  dup dequeue  ?dup while	( tcb segq elt )
      /tcp-segq-entry free-mem				( tcb segq )
   repeat  drop						( tcb )
   /tcp-control-block free-mem				( )
;

\ Kill all outstanding timers for this TCB.
: tcb-kill-timers ( tcb -- )
   dup >tcbt-rexmit  clear-timer drop			( tcb )
       >tcbt-connect clear-timer drop			( )
;

headers
