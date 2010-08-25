\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-input.fth
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
id: @(#)tcp-input.fth 1.1 04/09/08
purpose: TCP input and FSM management
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: tcp-find-option ( pkt option# -- adr len true | false )
   >r							( pkt ) ( r: option#  )
   dup  dup tcpip-hlen@ ca+  swap >tcp-options		( end start )
   begin  2dup >  while					( end nxt )
      dup c@  case
         TCPOPT_NOP of  ca1+                 endof
         TCPOPT_EOL of  r> 3drop false exit  endof
         r@         of
            nip dup ca1+ c@  r> drop  true exit
         endof
         ( default )
         drop dup ca1+ c@ ca+ 0
      endcase
   repeat						( end nxt' )
   r> 3drop  false					( false ) ( r: )
;

\ Drop the connection in response to a bad incoming segment, marking the
\ specified error in the TCB. Send an acceptable RST segment to peer.

: tcp-abort ( tcb pkt error# -- )
   >r  over swap tcp-reset  r>			( tcb error# )
   over tcb-error!				( tcb )
   TCPS_CLOSED over tcb-state!			( tcb )
   tcb-kill-timers				( )
;

\ Determine if a received segment is acceptable (states >= SYN_RCVD).
\ There are 4 cases for the acceptability test 
\   SEG.LEN     RCV.WND         Test
\     0            0        SEG.SEQ = RCV.NXT
\     0           >0        RCV.NXT =< SEG.SEQ < RCV.NXT+RCV.WND
\    >0            0        not acceptable
\    >0           >0        RCV.NXT =< SEG.SEQ < RCV.NXT+RCV.WND
\                           or RCV.NXT =< SEG.SEQ+SEG.LEN-1 < RCV.NXT+RCV.WND

: tcp-segok? ( tcb pkt -- ok? )
   over rcv-wnd@ 0=  if				( tcb pkt )
      dup seg-len@ 0=  if			( tcb pkt )
         seg-seq@  swap rcv-nxt@  seq=		( result )
      else					( tcb pkt )
         2drop false				( result )
      then					( result )
   else						( tcb pkt )
      >r					( tcb ) ( r: pkt )
      dup rcv-nxt@  swap rcv-wnd@  over +	( wnd.start wnd.end )
      2dup  r@ seg-seq@  -rot  seq-within	( wnd.start wnd.end flag )
      r@ seg-len@  if				( wnd.start wnd.end flag )
         r@ seg-lastseq@  2over seq-within or	( wnd.start wnd.end result )
      then  nip nip				( result )
      r> drop					( result ) ( r: )
   then						( result )
;

\ Generate an ACK in response to an incorrect incoming segment. The ACK
\ reports the correctly received sequence and the current window size. 
\ An ACK is generated only if the incoming segment is not a RST segment. 
 
: tcp-sendack ( tcb pkt -- )
   is-tcprst? 0=  if					( tcb )
      dup TF_ACKNOW tcb-set-flags  tcp-output		( )
   else							( tcb )
      drop						( )
   then							( )
;

\ Determine if the received ACK is acceptable (states >= ESTABLISHED).
\ If this ACKs something not sent yet (SEG.ACK > SND.NXT), an ACK should
\ be sent in response, and this segment must be dropped.

: tcp-ackok? ( tcb pkt -- flag )
   2dup seg-ack@  swap snd-nxt@  seq>  if		( tcb pkt )
      tcp-sendack false					( false )
   else							( tcb pkt )
      2drop true					( true )
   then							( flag )
;

\ Process incoming SYN and schedule an immediate ACK.
: tcp-process-syn ( tcb pkt -- )
   2dup seg-seq@ 1+  swap rcv-nxt!			( tcb pkt )
   2dup seg-wnd@     swap snd-wnd!			( tcb pkt )
   2dup seg-seq@     swap snd-wl1!			( tcb pkt )
   TCPOPT_MSS tcp-find-option  if			( tcb adr len )
      drop 2 ca+ ntohw@					( tcb mss )
   else							( tcb )
      TCP_DEFAULT_MSS					( tcb mss )
   then							( tcb mss )
   over tcb-mss@ min					( tcb mss' )
   over 2dup tcb-mss!  snd-cwnd!			( tcb )
   TF_ACKNOW tcb-set-flags				( )
;

\ Handle send window updates from remote end.
: tcp-swindow-update ( tcb pkt -- )
   swap							( pkt tcb )
   over seg-seq@  over snd-wl1@  seq<  if		( pkt tcb )
      2drop exit					( )
   then							( pkt tcb )
   over seg-seq@  over snd-wl1@  seq=  if		( pkt tcb )
      over seg-ack@  over snd-wl2@  seq<  if		( pkt tcb )
         2drop exit					( )
      then						( pkt tcb )
   then							( pkt tcb )
   over seg-wnd@  over snd-wnd!				( pkt tcb )
   over seg-seq@  over snd-wl1!				( pkt tcb )
   swap seg-ack@  swap snd-wl2!				( )
;

\ ACK processing. Accept send window updates, remove acknowledged data
\ from the retransmission queue, collect RTT estimates, manage the
\ retransmission timer, and update congestion window.

: tcp-process-ack ( tcb pkt -- )

   \ Check for send window updates from all legal ACKs.
   2dup tcp-swindow-update				( tcb pkt )

   \ If the ACK is a duplicate, it can be ignored.
   swap							( pkt tcb )
   over seg-ack@  over snd-una@  seq<=  if		( pkt tcb )
      2drop exit					( )
   then							( pkt tcb )

   \ Remove acknowledged bytes from the send buffer.
   over seg-ack@  over snd-una@ -			( pkt tcb #acked )
   over tcb>sndbuf swap  tcpbuf-drop			( pkt tcb )

   \ Update SND.UNA
   over seg-ack@  over snd-una!				( pkt tcb )

   \ Update RTT estimators if this ACK acknowledges the
   \ sequence number being timed and the segment was
   \ not retransmitted.
   dup tcb-flags@ TF_RTTGET and  if			( pkt tcb )
      over seg-ack@  over >tcb-rttseq l@  seq>=  if	( pkt tcb )
         dup TF_RTTGET tcb-clear-flags			( pkt tcb )
         dup tcp-retransmitting? 0=  if			( pkt tcb )
            dup dup >tcbt-rexmit get-timer		( pkt tcb tcb rtt )
            tcp-update-rto				( pkt tcb )
         then						( pkt tcb )
      then						( pkt tcb )
   then							( pkt tcb )

   \ If all outstanding data has now been acknowledged, 
   \ cancel the retransmission timer. Else, restart it
   \ using the current RTO estimate.
   over seg-ack@  over snd-max@  seq=  if		( pkt tcb )
      dup tcp-clear-rexmit-timer			( pkt tcb )
   else							( pkt tcb )
      dup tcp-set-rexmit-timer				( pkt tcb )
   then							( pkt tcb )

   \ Retransmitted data, if any, has now been ACKed.
   0  over >tcb-nrexmits  l!				( pkt tcb )

   \ The congestion window is increased by 1 segment per
   \ ACK during slow start, or by MSS*MSS/SND.CWND for 
   \ congestion avoidance.
   nip  dup snd-cwnd@  2dup swap ssthresh@  <  if	( tcb cwnd )
      over tcb-mss@ +					( tcb cwnd' )
   else							( tcb cwnd )
      over tcb-mss@  dup *  over /  +			( tcb cwnd' )
   then							( tcb cwnd' )
   swap snd-cwnd!					( )
;

\ Update receive sequence variables to reflect the sequence of
\ contiguous data received successfully. 
: tcp-rcvspace-update ( tcb seq len -- )
   +  over rcv-nxt@ -  dup if				( tcb n )
      2dup over rcv-nxt@ +       swap rcv-nxt!		( tcb n )
      2dup over rcv-wnd@ swap -  swap rcv-wnd!		( tcb n )
      over tcb>rcvbuf over       tcpbuf-count+!		( tcb n )
   then  2drop						( )
;

\ Adding entries to the sequencing queue. When an out-of-order data
\ segment arrives, record the sequence number and length of the
\ segment in an entry and do an ordered insert. Sequencing queue
\ entries are ordered on sequence numbers.

: tcpseg-higher-seq#? ( n entry -- n flag )
   >tseg-seq l@ over seq>=
;

: tcp-segq-insert ( tcb seq len -- )
   rot >tcb-segq >r					( seq len ) ( r: segq )
   /tcp-segq-entry alloc-mem				( seq len entry )
   tuck >tseg-len l!  2dup >tseg-seq l!			( seq entry )
   swap r@ ['] tcpseg-higher-seq#? find-queue-entry	( entry seq elt )
   nip  dup if						( entry elt )
      queue-prev swap insqueue				( )
   else							( entry 0 )
      drop r@ queue-last swap insqueue			( )
   then							( )
   r> drop						( ) ( r: )
;

\ Coalescing sequence queue entries. On arrival of an in-order data
\ segment, check to see if this segment fills any "holes" in the list.
\ The receive sequence space variables are updated to reflect the
\ sequence of contiguous data that has been received successfully.

: tcp-segq-join ( tcb seq len -- )
   2 pick >r   tcp-rcvspace-update			( ) ( r: tcb )
   r@ >tcb-segq  dup queue-first			( segq elt )
   begin						( segq elt )
      2dup queue-end? 0=  if				( segq elt )
         dup >tseg-seq l@  r@ rcv-nxt@  seq<=		( segq elt flag )
      else						( segq elt )
         false						( segq elt false )
      then						( segq elt flag )
   while						( segq elt )
      r@ over dup >tseg-seq l@ swap >tseg-len l@	( segq elt tcb seq len )
      tcp-rcvspace-update				( segq elt )
      dup queue-next  over remqueue  swap		( segq nextelt elt )
      /tcp-segq-entry free-mem				( segq nextelt )
   repeat  2drop					( )
   r> drop						( ) ( r: )
;

\ Copy data from segment into the (circular) receive buffer.
: tcp-copy-data ( tcb pkt seq len -- )
   2swap over >r				( seq len tcb pkt ) ( r: tcb )
   swap tcb>rcvbuf swap				( seq len buf pkt )
   3 pick					( seq len buf pkt seq )
   over seg-seq@ - /tcpip-header + +		( seq len buf adr )
   rot  2swap  swap				( adr len buf seq )
   r@ rcv-nxt@ -  over tcpbuf-count@ +		( adr len buf offset )
   2swap 					( buf offset adr len )
   tcpbuf-write					( len' )
   r> 2drop					( ) ( r: )
;

\ Trim segment so that it contains only data within advertised window. 
: tcp-trim-data ( tcb pkt -- start.seq datalen )
   over rcv-nxt@  over seg-seq@  2dup seq> if	( tcb pkt rcv.nxt seq )
      over swap - >r  over seg-datalen@  r> -	( tcb pkt start.seq len )
   else						( tcb pkt rcv.nxt seq )
      nip  over seg-datalen@			( tcb pkt start.seq len )
   then						( tcb pkt start.seq len )
   2swap					( start.seq len tcb pkt )
   2dup seg-lastseq@ swap rcv-lastseq@ seq> if	( start.seq len tcb pkt )
      dup TH_FIN tcp-clear-flags		( start.seq len tcb pkt )
      seg-lastseq@  swap rcv-lastseq@ -  -	( start.seq len' )
   else						( start.seq len tcb pkt )
      2drop					( start.seq len )
   then						( start.seq datalen )
;

\ Processing segment data. Copy data from the segment into the receive
\ buffer and update sequencing queue entries. We ACK every other segment
\ received. Out of order segments must be ACKed immediately. If data
\ is being "pushed", we record the push sequence number in the TCB.

: tcp-process-data ( tcb pkt -- )

   \ Check if the segment contains data.
   dup seg-datalen@ 0=  if  2drop exit  then		( tcb pkt )

   \ Trim segment to fit in window. 
   2dup tcp-trim-data					( tcb pkt seq len )

   \ Copy data from the segment.
   2over 2over tcp-copy-data				( tcb pkt seq len )

   \ Update sequencing queue entries and schedule an
   \ ACK as appropriate.
   2swap >r						( seq len tcb )( r:pkt )
   dup 2swap						( tcb tcb seq len )
   2 pick rcv-nxt@  2 pick  seq=  if			( tcb tcb seq len )
      tcp-segq-join					( tcb )
      dup  dup tcb-flags@  TF_DELACK and  if		( tcb tcb )
         TF_ACKNOW tcb-set-flags			( tcb )
      else						( tcb tcb )
         TF_DELACK tcb-set-flags			( tcb )
      then						( tcb )
   else							( tcb tcb seq len )
      tcp-segq-insert					( tcb )
      dup TF_ACKNOW tcb-set-flags			( tcb )
   then							( tcb )
   r>							( tcb pkt ) ( r: )

   \ Record PUSH sequence number, if any
   dup is-tcppsh?  if					( tcb pkt )
      2dup seg-lastseq@ 1+  swap >tcb-pushseq l!	( tcb pkt )
      over TF_PUSH tcb-set-flags			( tcb pkt )
   then  2drop						( )
;

\ FIN processing. Since segments can arrive out of order, we must
\ handle delayed controls. On receiving a FIN, information about it
\ is stored in the TCB. Once all data up though the FIN has been
\ received, we extend the receive sequence space past the FIN. 

: tcp-process-fin ( tcb pkt -- )

   \ If this a FIN, record its sequence number and
   \ schedule an immediate ACK.
   dup is-tcpfin?  if					( tcb pkt )
      2dup seg-lastseq@  swap >tcb-finseq l!		( tcb pkt )
      over TF_RCVDFIN TF_ACKNOW or tcb-set-flags	( tcb pkt )
   then  drop						( tcb )

   \ Advance RCV.NXT over FIN.
   dup tcb-flags@ TF_RCVDFIN and  if			( tcb )
      dup rcv-nxt@  over >tcb-finseq l@  seq=  if	( tcb )
         dup rcv-nxt@ 1+  over rcv-nxt!			( tcb )
      then						( tcb )
   then  drop						( )
;

\ Determine whether any more data can arrive on this connection.
: tcp-receive-done? ( tcb -- flag )
   dup tcb-flags@ TF_RCVDFIN and  if			( tcb )
      dup rcv-nxt@  swap >tcb-finseq l@ 1+  seq=	( flag )
   else							( tcb )
      drop false					( false )
   then							( flag )
;

\ Check whether our FIN has been acknowledged.
: tcp-ourfin-acked? ( tcb pkt -- flag )
   over tcb-flags@ TF_SENTFIN and  if			( tcb pkt )
      seg-ack@  swap snd-max@  seq=			( flag )
   else							( tcb pkt )
      2drop false					( false )
   then							( flag )
;

\ CLOSED state processing. Respond to all incoming segments with
\ an acceptable RST.

: tcps-closed ( tcb pkt -- )
   tcp-reset
;

\ LISTEN state processing. We are waiting for incoming connections. Our
\ simple implementation does not allocate a new TCB. On receipt of a SYN, 
\ determine MSS to use, record the sender's address and port numbers in 
\ the INPCB, initialize window information and enter SYN_RCVD state.

: tcps-listen ( tcb pkt -- )

   \ Ignore incoming RST segments. If the segment is
   \ an ACK, send an acceptable RST segment. Drop the
   \ segment if it is not a SYN.
   dup is-tcprst?     if  2drop exit      then		( tcb pkt )
   dup is-tcpack?     if  tcp-reset exit  then		( tcb pkt )
   dup is-tcpsyn? 0=  if  2drop exit      then		( tcb pkt )

   \ Record the remote client's IP address and port
   \ identifiers in our PCB.
   over tcb>inpcb					( tcb pkt pcb )
   over dup >ip-src swap >tcp-sport ntohw@		( tcb pkt faddr fport )
   inpcb-connect					( tcb pkt )

   \ Process SYN (schedules an immediate ACK)
   over swap tcp-process-syn				( tcb )

   \ Initialize send sequence variables
   dup tcp-sendseq-init					( tcb )

   \ Enter SYN_RCVD state and send <SYN,ACK>
   TCPS_SYN_RCVD over tcb-state!			( tcb )
   tcp-output						( )
;

\ SYN_SENT state processing. We are waiting for our SYN to be ACKed.
\ On receiving a SYN, determine MSS to use on this connection. If 
\ the segment ACKs our SYN, enter ESTABLISHED state. Else (no ACK), 
\ this is a simultaneous open, enter SYN_RCVD state.

: tcps-synsent ( tcb pkt -- )

   \ If this is an ACK, but not for our SYN, send a RST.
   dup is-tcpack?  if					( tcb pkt )
      over snd-nxt@  over seg-ack@  seq<>  if		( tcb pkt )
         tcp-reset exit					( )
      then						( tcb pkt )
   then							( tcb pkt )

   \ If this is a RST, and the ACK was acceptable, drop
   \ the connection. Otherwise (no ACK), drop the segment
   \ and return.
   dup is-tcprst?  if					( tcb pkt )
      dup is-tcpack?  if				( tcb pkt )
         ECONNREFUSED tcp-abort exit			( )
      then						( tcb pkt )
      2drop exit					( )
   then							( tcb pkt )

   \ If this is not a SYN, drop it and return.
   dup is-tcpsyn? 0=  if  2drop exit  then		( tcb pkt )

   \ Process SYN (schedules immediate ACK).
   2dup tcp-process-syn					( tcb pkt )

   \ Make appropriate state transition.
   dup is-tcpack?   if					( tcb pkt )
      over swap tcp-process-ack				( tcb )
      TCPS_ESTABLISHED over tcb-state!			( tcb )
   else							( tcb pkt )
      drop						( tcb )
      TCPS_SYN_RCVD over tcb-state!			( tcb )
   then                                                 ( tcb )
   tcp-output						( )
;

\ SYN_RCVD state processing. This state is entered either as a result
\ of a simultaneous open or after a SYN is received in the LISTEN state.
\ We are waiting for our SYN to be ACKed to move to ESTABLISHED state.

: tcps-synrcvd ( tcb pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  over is-tcpsyn?  or  if		( tcb pkt )
      ECONNRESET tcp-abort exit				( )
   then							( tcb pkt )

   \ If this is not an ACK, drop it and return
   dup is-tcpack? 0=  if  2drop exit  then		( tcb pkt )

   \ If this ACK is not acceptable, send a RST.
   over snd-una@  over seg-ack@  seq>  >r		( tcb pkt )
   over snd-max@  over seg-ack@  swap seq>  r> or  if	( tcb pkt )
      tcp-reset exit					( )
   then							( tcb pkt )

   \ Process the ACK.
   over swap tcp-process-ack				( tcb )

   \ Enter ESTABLISHED state
   TCPS_ESTABLISHED swap tcb-state!			( tcb )
;

\ ESTABLISHED state processing. Once the connection has been established
\ we remain in this state exchanging data and ACKs. Segments may
\ arrive out of order. If a FIN has arrived, we transition to the
\ CLOSE_WAIT state once all data up through the FIN has been received.

: tcps-established ( tcb tcpip-pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  over is-tcpsyn?  or  if		( tcb pkt )
      ECONNRESET tcp-abort exit				( )
   then							( tcb pkt )

   \ Process incoming ACKs.
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-process-ack					( tcb pkt )

   \ Process segment data and FIN.
   2dup tcp-process-data				( tcb pkt )
   2dup tcp-process-fin					( tcb pkt )

   \ If a FIN has arrived, and all data upto the FIN 
   \ has been received, enter CLOSE_WAIT state. 
   drop  dup tcp-receive-done?  if			( tcb )
      TCPS_CLOSE_WAIT over tcb-state!			( tcb )
   then  						( tcb )

   \ Send any necessary ACK
   tcp-output						( )
;

\ CLOSE_WAIT state processing. All data has been received, and the other
\ end has issued a "half-close". We are waiting for the application
\ to issue a "close" before moving to the LAST_ACK state. ACKs for
\ any data we may send must be processed.

: tcps-closewait ( tcb pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  over is-tcpsyn?  or  if		( tcb pkt )
      ECONNRESET tcp-abort  exit			( )
   then							( tcb pkt )

   \ Process incoming ACKs. 
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   tcp-process-ack					( ) 
;

\ LAST_ACK state processing.  A FIN has been sent when the application 
\ issues a "close", and we are awaiting an ACK for our FIN. We can 
\ return from "close" once our FIN has been ACKed.

: tcps-lastack ( tcb pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  if  0 tcp-abort exit          then	( tcb pkt )
   dup is-tcpsyn?  if  ECONNRESET tcp-abort exit then	( tcb pkt )

   \ Process incoming ACKs.
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-process-ack					( tcb pkt )

   \ Enter CLOSED state once our FIN is ACKed.
   over swap tcp-ourfin-acked?  if			( tcb )
      TCPS_CLOSED over tcb-state!			( tcb )
   then  drop						( )
;

\ FIN_WAIT_1 state processing. A FIN has been sent on "close". The other 
\ end may respond with a ACK for our FIN or with its own FIN or both. If 
\ the ACK arrives alone, move to FIN_WAIT_2. If only the FIN arrives, 
\ move to CLOSING. If both arrive, move to TIME_WAIT state.

: tcps-finwait1 ( tcb tcpip-pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  over is-tcpsyn?  or  if		( tcb pkt )
      ECONNRESET tcp-abort exit				( )
   then							( tcb pkt )

   \ Process incoming ACKs.
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-process-ack					( tcb pkt )

   \ Process segment data and FIN.
   2dup tcp-process-data				( tcb pkt )
   2dup tcp-process-fin					( tcb pkt )

   \ Make appropriate state transition.
   over swap  tcp-ourfin-acked?  if			( tcb )
      dup tcp-receive-done?  if				( tcb )
         TCPS_TIME_WAIT over tcb-state!			( tcb )
      else						( tcb )
         TCPS_FIN_WAIT_2 over tcb-state!		( tcb )
      then						( tcb )
   else							( tcb )
      dup tcp-receive-done?  if				( tcb )
         TCPS_CLOSING over tcb-state!			( tcb )
      then  						( tcb )     
   then							( tcb )

   \ Send any necessary ACK
   tcp-output						( )
;

\ CLOSING state processing. FINs have been exchanged, and we are
\ waiting for our FIN to be ACKed.

: tcps-closing ( tcb pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  if  0 tcp-abort exit          then	( tcb pkt )
   dup is-tcpsyn?  if  ECONNRESET tcp-abort exit then	( tcb pkt )

   \ Process incoming ACKs.
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-process-ack					( tcb pkt )

   \ Enter CLOSED state.
   drop  TCPS_CLOSED swap tcb-state!			( )
;

\ FIN_WAIT_2 state processing. Our FIN has been ACKed, and the connection
\ is "half-closed". We must process any incoming data while waiting for 
\ a FIN from the other end.

: tcps-finwait2 ( tcb pkt -- )

   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable segments.
   dup is-tcprst?  over is-tcpsyn? or  if		( tcb pkt )
      ECONNRESET tcp-abort exit				( )
   then							( tcb pkt )

   \ Process incoming ACKs.
   dup  is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-ackok? 0=  if  2drop exit  then		( tcb pkt )
   2dup tcp-process-ack					( tcb pkt )

   \ Process segment data and FIN.
   2dup tcp-process-data				( tcb pkt )
   2dup tcp-process-fin					( tcb pkt )

   drop  dup tcp-receive-done?  if			( tcb )
      TCPS_TIME_WAIT over tcb-state!			( tcb )
   then							( tcb )
   tcp-output						( )
;

\ TIME_WAIT state processing. The only segment that should arrive is
\ a retransmission of the remote FIN. Send an ACK. We dont implement
\ the 2 MSL timer.

: tcps-timewait ( tcb pkt -- )
   2dup tcp-segok? 0=  if  tcp-sendack exit  then	( tcb pkt )

   \ Handle unacceptable packets
   dup is-tcprst?  if  0 tcp-abort exit          then	( tcb pkt )
   dup is-tcpsyn?  if  ECONNRESET tcp-abort exit then	( tcb pkt )

   \ Process ACK
   dup is-tcpack? 0=  if  2drop exit  then		( tcb pkt )
   over swap tcp-process-ack				( tcb )

   \ Acknowledge receipt of segment
   dup TF_ACKNOW tcb-set-flags  tcp-output		( )
;

\ TCP FSM state switch table.
create tcp-state-table
   ' tcps-closed	,	\ CLOSED
   ' tcps-listen	,	\ LISTEN
   ' tcps-synsent	,	\ SYN_SENT
   ' tcps-synrcvd	,	\ SYN_RCVD
   ' tcps-established	,	\ ESTABLISHED
   ' tcps-closewait	,	\ CLOSE_WAIT
   ' tcps-finwait1	,	\ FIN_WAIT_1
   ' tcps-closing	,	\ CLOSING
   ' tcps-lastack	,	\ LAST_ACK
   ' tcps-finwait2	,	\ FIN_WAIT_2
   ' tcps-timewait	,	\ TIME_WAIT

\ Switch to routine corresponding to the current input state to process
\ the segment.
: tcp-process-segment ( tcb pkt -- )
   tcp-state-table  2 pick tcb-state@  na+ @  execute		( )
;

\ Check if segment is meant for this TCB/INPCB. 
: tcb-match? ( pkt inpcb -- pkt match? )
   over >tcp-dport ntohw@   over in-lport@   <>  if  drop false exit  then
   over >ip-dest            over >in-laddr ip<>  if  drop false exit  then
   dup inpcb>tcb tcb-state@ TCPS_LISTEN      =   if  drop true  exit  then
   over >ip-src             over >in-faddr ip<>  if  drop false exit  then
   over >tcp-sport ntohw@  swap in-fport@    =
;

\ TCP port demultiplexing.
: tcb-locate ( pkt -- tcb | 0 )
   tcp-inpcb-list  ['] tcb-match?  find-queue-entry nip  dup if
      inpcb>tcb
   then
;

\ Handle incoming segments. If no matching TCB is found, an acceptable 
\ RST is sent.
: tcp-input ( pkt -- )
   dup tcp-checksum 0=  if			( pkt )
      dup tcb-locate  over			( pkt tcb pkt )
      2dup TR_INPUT 0 tcp-trace			( pkt tcb pkt )
      over if					( pkt tcb pkt )
         tcp-process-segment			( pkt )
      else					( pkt 0 pkt )
         tcp-reset				( pkt )
      then					( pkt )
   then						( pkt )
   pkt-free					( )
;
['] tcp-input to (tcp-input)

: tcp-poll ( -- )
   tcp-do-timer-events  ip-poll
;

\ Drain input.
: tcp-drain-input ( -- )
   get-msecs  begin  dup get-msecs =  while  tcp-poll  repeat  drop
;

headers
