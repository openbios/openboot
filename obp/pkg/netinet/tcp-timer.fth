\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcp-timer.fth
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
id: @(#)tcp-timer.fth 1.1 04/09/07
purpose: TCP timer management
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

/timer instance buffer:  tcp-fast-timer		\ 200 ms timer
/timer instance buffer:  tcp-slow-timer		\ 500 ms timer

: tcp-start-fasttimer ( -- )  tcp-fast-timer d# 200 set-timer ;
: tcp-start-slowtimer ( -- )  tcp-slow-timer d# 500 set-timer ; 

\ Start tracking fast and slow timeouts.
: tcp-start-timers ( -- )
   tcp-start-fasttimer  tcp-start-slowtimer		( )
;

\ Delayed ACK processing routine called once every 200 ms
: tcp-do-delacks ( inpcb -- )
   inpcb>tcb  dup tcb-flags@  TF_DELACK and if		( tcb )
      dup TF_ACKNOW tcb-set-flags			( tcb )
      dup tcp-output					( tcb )
   then  drop						( )
;

\ TCP protocol timeout routine called every 500 ms. Check timers
\ in all TCBs and causes FSM actions if timers have expired.
: tcp-process-timeouts ( inpcb -- )
   inpcb>tcb						( tcb )
   dup >tcbt-rexmit timer-expired?  if			( tcb )
      tcp-retransmit exit				( )
   then							( tcb )
   dup >tcbt-connect timer-expired?  if			( tcb )
      ETIMEDOUT tcp-drop exit				( )
   then  drop						( )
;

\ Handle TCP timer events
: tcp-do-timer-events ( -- )
   tcp-fast-timer timer-expired?  if				( )
      tcp-start-fasttimer					( )
      tcp-inpcb-list ['] tcp-do-delacks queue-iterate		( )
   then								( )
   tcp-slow-timer timer-expired?  if				( )
      tcp-start-slowtimer					( )
      tcp-inpcb-list ['] tcp-process-timeouts queue-iterate	( )
   then								( )
;

headers
