\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: link-params.fth
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
id: @(#) link-params.fth 1.2 03/08/23
purpose: Declarations for storing and setting up link information.
copyright: Copyright 1999-2003 Sun Microsystems, Inc. All Rights Reserved.
copyright: Use is subject to license terms.

headerless

\ Values for transceiver in use.
0   constant    no-xcvr
1   constant    internal-xcvr
2   constant    external-xcvr
3   constant    pcs-xcvr

no-xcvr  instance value xcvr-in-use

\ Link speeds.
d#    0  constant  auto-speed
d#   10  constant  10Mbps
d#  100  constant  100Mbps
d# 1000  constant  1000Mbps

\ Link duplex modes.
0  constant  auto-duplex
1  constant  half-duplex
2  constant  full-duplex

\ Gigabit link clock modes.
0  constant  auto-link-clock
1  constant  master-link-clock
2  constant  slave-link-clock

\ Link speed, duplex and link-clock selected by user.
auto-speed      instance value  user-speed
auto-duplex     instance value  user-duplex
auto-link-clock instance value  user-link-clock

\ Chosen link speed and duplex modes.
0  instance value  chosen-speed
0  instance value  chosen-duplex

\ MAC modes.
1  constant  int-loopback
2  constant  promiscuous

0 instance value  mac-mode

: full-duplex-link? ( -- flag )  chosen-duplex full-duplex =  ;
: half-duplex-link? ( -- flag )  chosen-duplex half-duplex =  ;

: pcs-xcvr? ( -- flag )  xcvr-in-use  pcs-xcvr =  ;
: mif-xcvr? ( -- flag )  xcvr-in-use  pcs-xcvr <> ; 

: set-chosen-speed&duplex ( speed mode -- )
   to chosen-duplex  to chosen-speed
;

: .link-speed,duplex ( speed mode -- )
   swap  case
      10Mbps    of    ." 10 Mbps "     endof
      100Mbps   of    ." 100 Mbps "    endof
      1000Mbps  of    ." 1000 Mbps "   endof
   endcase
   case
      half-duplex  of  ." half duplex "  endof
      full-duplex  of  ." full duplex "  endof
   endcase
;

: speed=auto ( -- )   auto-speed  to user-speed ;
: speed=10   ( -- )   10Mbps      to user-speed ;
: speed=100  ( -- )   100Mbps     to user-speed ;
: speed=1000 ( -- )   1000Mbps    to user-speed ;

: duplex=auto ( -- )  auto-duplex to user-duplex ;
: duplex=half ( -- )  half-duplex to user-duplex ;
: duplex=full ( -- )  full-duplex to user-duplex ;

: link-clock=auto   ( -- )  auto-link-clock   to user-link-clock ;
: link-clock=master ( -- )  master-link-clock to user-link-clock ;
: link-clock=slave  ( -- )  slave-link-clock  to user-link-clock ;

: mode=promiscuous ( -- )  promiscuous to mac-mode ;

headers
