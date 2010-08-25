\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-h.fth
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
id: @(#)tcp-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

struct
   /ip-header   field   >tcp-iphdr	\ IP header, no options
   /w           field   >tcp-sport     	\ Source port
   /w           field   >tcp-dport     	\ Destination port
   /l           field   >tcp-seq	\ Sequence number
   /l           field   >tcp-ack	\ Acknowledgement number
   /c           field   >tcp-offset	\ Data offset (4 bits), Rsvd (4 bits) 
   /c           field   >tcp-flags	\ Flags
   /w           field   >tcp-window	\ Advertised window
   /w           field   >tcp-cksum	\ Checksum
   /w           field   >tcp-urgptr	\ Urgent pointer
    0           field   >tcp-options	\ options
constant /tcpip-header

d# 20  constant /tcp-header

\ TCP flags (Control bits)
1      constant TH_FIN		\ No more data from sender
2      constant TH_SYN		\ Synchronize sequence numbers
h# 04  constant TH_RST		\ Reset connection
h# 08  constant TH_PSH		\ Push function
h# 10  constant TH_ACK		\ Ack# is valid
h# 20  constant TH_URG		\ Urgent pointer is valid

\ TCP options
0  constant TCPOPT_EOL		\ End of Option list
1  constant TCPOPT_NOP		\ NOOP
2  constant TCPOPT_MSS		\ Maximum segment size

\ TCP FSM states
0      constant TCPS_CLOSED		\ Closed
1      constant TCPS_LISTEN		\ Listening for connection
2      constant TCPS_SYN_SENT		\ Sent SYN (active open)
3      constant TCPS_SYN_RCVD		\ Sent and received SYN, awaiting ACK
d#  4  constant TCPS_ESTABLISHED	\ Established (Data transfer)
d#  5  constant TCPS_CLOSE_WAIT		\ Received FIN; waiting for close
d#  6  constant TCPS_FIN_WAIT_1		\ Have closed; Sent FIN
d#  7  constant TCPS_CLOSING		\ Simultaneous close, awaiting FIN ACK
d#  8  constant TCPS_LAST_ACK		\ Passive close, awaiting FIN ACK
d#  9  constant TCPS_FIN_WAIT_2		\ Active close, FIN is ACKed
d# 10  constant TCPS_TIME_WAIT		\ In 2MSL state after active close

d# 536 constant	TCP_DEFAULT_MSS

: tcp-hlen@  ( pkt -- n )  >tcp-offset c@  h# f0 and  2 >> ;
: tcp-hlen!  ( n pkt -- )  swap  2 << h# f0 and  swap >tcp-offset c! ;

: tcpip-hlen@ ( pkt -- n )  tcp-hlen@ /ip-header + ;

: tcp-flags@ ( pkt -- flags )  >tcp-flags c@  ;
: tcp-flags! ( flags pkt -- )  >tcp-flags c!  ;

\ Routines to check TCP flags
: is-tcpfin? ( pkt -- flag )  tcp-flags@ TH_FIN and ;
: is-tcpsyn? ( pkt -- flag )  tcp-flags@ TH_SYN and ;
: is-tcprst? ( pkt -- flag )  tcp-flags@ TH_RST and ;
: is-tcppsh? ( pkt -- flag )  tcp-flags@ TH_PSH and ;
: is-tcpack? ( pkt -- flag )  tcp-flags@ TH_ACK and ;

: tcp-clear-flags ( pkt flags -- )
   invert  over tcp-flags@  and  swap tcp-flags!
;

: seg-ack@ ( pkt -- ack# )  >tcp-ack    ntohl@  ;
: seg-seq@ ( pkt -- seq# )  >tcp-seq    ntohl@  ;
: seg-wnd@ ( pkt -- n )     >tcp-window ntohw@  ;

\ Size of data in the segment. SYN and FIN are not counted here.
: seg-datalen@ ( pkt -- n )
   dup ippkt>payload nip swap tcp-hlen@ -
;

\ Segment length, including SYN and FIN.
: seg-len@ ( pkt -- n )
   dup seg-datalen@                 		( pkt datalen )
   over is-tcpsyn? if  1+  then     		( pkt datalen' )
   swap is-tcpfin? if  1+  then     		( seg.len )
;

\ Last sequence number occupied by a segment
: seg-lastseq@ ( pkt -- n )  dup seg-seq@  swap seg-len@ +  1- ;

\ Length of options in packet
: tcp-optlen@ ( pkt -- n )  tcpip-hlen@  0 >tcp-options - ;

\ TCP sequence number comparison routines
: seq<  ( s1 s2 -- flag )  -  0<  ;
: seq>  ( s1 s2 -- flag )  -  0>  ;
: seq<= ( s1 s2 -- flag )  -  0<= ;
: seq>= ( s1 s2 -- flag )  -  0>= ;
: seq=  ( s1 s2 -- flag )  -  0=  ;
: seq<> ( s1 s2 -- flag )  -  0<> ;

: seq-within ( n s1 s2 -- flag )
   >r over seq<=  swap  r> seq<  and
;

headers
