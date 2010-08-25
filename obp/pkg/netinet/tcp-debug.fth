\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-debug.fth
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
id: @(#)tcp-debug.fth 1.1 04/09/07
purpose: TCP debug support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Post-mortem debugging support routines.

[ifdef] DEBUG

headerless

create tcp-state-names
   " CLOSED"		pstring,
   " LISTEN"		pstring,
   " SYN_SENT"		pstring,
   " SYN_RCVD"		pstring,
   " ESTABLISHED"	pstring,
   " CLOSE_WAIT"	pstring,
   " FIN_WAIT_1"	pstring,
   " CLOSING"		pstring,
   " LAST_ACK"		pstring,
   " FIN_WAIT_2"	pstring,
   " TIME_WAIT"		pstring,

create soreq-names
   " ATTACH"		pstring,
   " DETACH"		pstring,
   " BIND"		pstring,
   " CONNECT"		pstring,
   " LISTEN"		pstring,
   " ACCEPT"		pstring,
   " SEND"		pstring,
   " SENDTO"		pstring,
   " RECV"		pstring,
   " RECVFROM"		pstring,

: find-string ( table index -- $ )   0 ?do  count ca+  loop  count  ;

: tcp-state-name ( record -- $ )
   tcp-state-names  swap >td-tcb tcb-state@  find-string
;

: tcp-event-name ( record -- $ )
   dup >td-event l@  case                               
      TR_INPUT  of  drop " Input"   endof
      TR_SOCKET of
         soreq-names swap >td-req l@  find-string
      endof
      TR_OUTPUT of
         >td-tcb tcp-retransmitting? if  " Rexmit"  else  " Output"  then
      endof
   endcase 
;

: ftype ( adr len field-width -- )
   over - >r  type  r>  dup 0>  if  spaces  else  drop  then
;

\ Display information from TCP/IP header as  
\   [FLAGS]  SEG.SEQ:SEG.END(SEG.LEN)  SEG.ACK  SEG.WND
: show-packet-info ( pkt -- )
   dup ip-len@ 0=  if  drop exit  then			( pkt )
   dup tcp-flags@					( pkt flags )
   ." ["						( pkt flags )
   dup TH_ACK invert and  if				( pkt flags )
      dup TH_SYN and  if  ." S"  then			( pkt flags )
      dup TH_FIN and  if  ." F"  then			( pkt flags )
      dup TH_PSH and  if  ." P"  then			( pkt flags )
          TH_RST and  if  ." R"  then			( pkt )
   else							( pkt flags )
      drop ." ."					( pkt )
   then							( pkt )
   ." ] " 						( pkt )
   base @ >r  decimal					( pkt ) ( r: base )
   dup seg-seq@  over seg-len@				( pkt seg.seq seg.len )
   over    (u.) type  ." :"				( pkt seg.seq seg.len )
   tuck +  (u.) type  ." ("				( pkt seg.len )
           (u.) type  ." )"  space			( pkt )
   dup is-tcpack?  if					( pkt )
      ." ack "  dup seg-ack@  u.			( pkt )
   then							( pkt )
   ." win "  seg-wnd@  u.  				( )
   r> base !                                            ( ) ( r: )
;

\ Show a one line summary of the TCP event formatted as
\   <tcp-state> <soreq-name> 		(for TR_SOCKET events)
\   <tcp-state> <event>  <pkt-info>	(for TR_INPUT/TR_OUTPUT events)
: show-tcptrace-event ( record -- )
   dup tcp-state-name  d# 12 ftype
   dup tcp-event-name  d#  7 ftype
   dup >td-event l@  TR_SOCKET <>  if
      dup >td-pkthdr show-packet-info
   then  drop cr
;

\ Dump out information from TCB.
: show-tcb-vars ( tcb -- )
   dup tcb>inpcb 0=  if exit  then
   base @ >r  decimal
   2 spaces
   ." rcv.nxt  = "  dup rcv-nxt@  .
   ." rcv.wnd  = "  dup rcv-wnd@  . cr
   2 spaces
   ." snd.una  = "  dup snd-una@  .
   ." snd.nxt  = "  dup snd-nxt@  .
   ." snd.max  = "  dup snd-max@  . cr
   2 spaces
   ." snd.wl1  = "  dup snd-wl1@  .
   ." snd.wl2  = "  dup snd-wl2@  .
   ." snd.wnd  = "  dup snd-wnd@  . cr
   2 spaces
   ." snd.cwnd = "  dup snd-cwnd@ .
   ." ssthresh = "  dup ssthresh@ . cr
   2 spaces
   ." rttseq   = "  dup >tcb-rttseq l@ .
   ." rtt = "       dup >tcb-rtt    l@ .
   ." srtt = "      dup >tcb-srtt   l@ 3 rshift .
   ." rttvar = "    dup >tcb-rttvar l@ 2 rshift .
   ." rto = "           >tcb-rto    l@ . cr
   r> base !
;

: show-tcptrace-record ( record -- )
   dup show-tcptrace-event  >td-tcb show-tcb-vars  cr
;

headers

\ Show all available information.
: show-log ( -- )
   ['] show-tcptrace-record show-tcptrace-data
;

\ Show TCP event summary (1 line per event).
: show-tcp-events ( -- )
   ['] show-tcptrace-event show-tcptrace-data
;

headerless

[then]
