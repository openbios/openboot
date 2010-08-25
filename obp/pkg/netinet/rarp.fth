\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: rarp.fth
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
id: @(#)rarp.fth 1.1 04/09/07
purpose: RARP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 903: Reverse Address Resolution Protocol

headerless

\ On receiving a RARP reply, add an ARP table translation for the responder 
\ as this may eliminate the need for a subsequent ARP request. It is legal
\ for the responder to not fill in its IP address in RARP replies. 

: process-rarp-response ( pkt -- )
   dup >arp-tpa my-ip-addr copy-ip-addr			( pkt )
   dup >arp-spa  inaddr-any? 0=  if			( pkt )
      dup >arp-spa over >arp-sha arp-add-entry		( pkt )
   then  drop						( )
;

\ Handle incoming RARP packets.
: rarp-input ( pkt len -- )
   over swap arp-packet-ok?  if				( pkt )
      dup >arp-op ntohw@  RARP_REPLY =  if		( pkt )
         dup >arp-tha  if-hwaddr  hwaddr=  if		( pkt )
            dup process-rarp-response			( pkt )
         then						( pkt )
      then						( pkt )
   then							( pkt )
   pkt-free						( pkt )
;
['] rarp-input  to (rarp-input)

\ Broadcast RARP requests to obtain my IP address. Use exponential
\ backoffs (with a maximum timeout of 32 seconds) between retries.

/timer  instance buffer:  rarp-timer

: rarp-backoff ( -- )
   rarp-timer dup clear-timer 2* d# 32000 min set-timer
;

: do-rarp ( -- )
   rarp-timer d# 1000 set-timer
   begin  my-ip-addr inaddr-any?  while
      ." Requesting Internet Address for " if-hwaddr if-showaddr cr
      my-ip-addr if-hwaddr RARP_REQ RARP_TYPE send-arp/rarp-packet
      begin
         if-poll
         my-ip-addr inaddr-any? 0=  rarp-timer timer-expired?  or
      until
      rarp-backoff
   repeat
;

headers
