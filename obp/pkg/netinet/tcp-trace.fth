\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-trace.fth
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
id: @(#)tcp-trace.fth 1.1 04/09/07
purpose: TCP trace support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ When debugging support is enabled, tcp-trace adds an entry to a
\ trace buffer recording the event type, the state of the TCP control
\ block, and the TCP/IP packet header for input/output events. This
\ provides complete TCP state information (recorded without impacting
\ the actual transfer) which can be analysed post-mortem. The
\ trace buffer is implemented as circular buffer.

headerless

\ TCP trace events
0  constant  TR_OUTPUT	\ Before call to ip-output to send segment
1  constant  TR_INPUT	\ Before incoming segment is processed
2  constant  TR_SOCKET	\ Before processing TCP PRREQ

[ifndef] DEBUG

: tcp-trace ( tcb pkt event req -- )  2drop 2drop ;

[else]

struct
   /l                  field  >td-event		\ TCP event (TR_*)
   /tcp-control-block  field  >td-tcb		\ TCP control block
   /tcpip-header       field  >td-pkthdr	\ TCP and IP headers
   /l                  field  >td-req		\ PRREQ value for TD_SOCKET
constant /tcptrace-record

d# 100  constant  TCP_NTRACE		\ Max number of records
0       value     tcptrace-buffer	\ Buffer
0       value     tcptrace-nrecords	\ Total records logged

: index>tcptrace-entry ( index -- adr ) 
   /tcptrace-record *  tcptrace-buffer +
;

: tcptrace-init ( -- )
   tcptrace-buffer 0=  if
      /tcptrace-record TCP_NTRACE *  alloc-mem  to tcptrace-buffer
   then
   0 to tcptrace-nrecords
;

: tcp-trace ( tcb pkt event req -- )
   tcptrace-nrecords TCP_NTRACE mod		( tcb pkt event req n )
   index>tcptrace-entry >r			( tcb pkt event req ) ( r: adr )
   r@ /tcptrace-record erase			( tcb pkt event req )
   r@ >td-req    l!				( tcb pkt event )
   r@ >td-event  l!				( tcb pkt )
   ?dup  if					( tcb pkt )
      r@ >td-pkthdr /tcpip-header move		( tcb )
   then						( tcb )
   ?dup  if					( tcb )
      r@ >td-tcb /tcp-control-block move	( )
   then						( )
   tcptrace-nrecords 1+  to tcptrace-nrecords	( )
   r> drop					( ) ( r: )
;

: show-tcptrace-data ( xt -- )
   tcptrace-nrecords TCP_NTRACE >  if
      TCP_NTRACE tcptrace-nrecords over mod  do
         i index>tcptrace-entry over execute
      loop
   then
   tcptrace-nrecords TCP_NTRACE mod 0  do
      i index>tcptrace-entry over execute
   loop  drop
;

[then]

headers
