\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dhcp.fth
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
id: @(#)dhcp.fth 1.1 04/09/07
purpose: DHCP support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 2131: Dynamic Host Configuration Protocol
\ RFC 2132: DHCP Options and BOOTP Vendor Extensions
\ RFC 1534: Interoperation Between DHCP and BOOTP

fload ${BP}/pkg/netinet/dhcp-h.fth

headerless

0         instance value     dhcp-sockid
/insock   instance buffer:   dhcp-srv-addr
/insock   instance buffer:   dhcp-cli-addr

d# 32     instance buffer:   dhcp-classid

/ip-addr  instance buffer:   dhcp-offered-ip
/ip-addr  instance buffer:   dhcp-server-id

0         instance value     dhcp-sndbuf
          instance variable  dhcp-sndbuflen
0         instance value     dhcp-rcvbuf

0         instance value     chosen-bootreply	\ Best offer
0         instance value     /chosen-bootreply
0         instance value     best-offer-points
false     instance value     bootp-config?	\ Is best offer a BOOTREPLY?

/timer    instance buffer:   dhcp-timer

          instance variable  dhcp-state		\ DHCP FSM state
          instance variable  dhcp-xid		\ Transaction identifier

\ Read a byte and advance the pointer.
: c@++ ( adr -- adr+1 c )  dup ca1+ swap c@ ;

\ Find an option in the specified area of a packet.
: (find-dhcp-option) ( adr len option# -- optadr optlen true | false )
   >r over ca+ swap                 		( end start ) ( r: option# )
   begin  2dup >  while
      c@++  case
         CD_PAD of                              endof
         CD_END of  r> 3drop false exit         endof
         r@     of  r> drop nip c@++ true exit  endof
         ( default )
         drop c@++ ca+ 0
      endcase
   repeat
   r> 3drop false
;

\ Find the specified DHCP option. Options in a DHCP message may extend
\ to the 'sname' and 'file' fields if an 'option overload' option is
\ present in the variable length options field.
: find-dhcp-option ( pkt len option# -- optadr optlen true | false )
   2 pick  >dhcp-cookie ntohl@  BOOTMAGIC <>  if
      3drop false exit
   then
   >r						( pkt,len ) ( r: opt# )
   over >dhcp-options  over /dhcp-header -	( pkt,len opts,len )
   2dup r@ (find-dhcp-option)  if		( pkt,len opts,len optadr,len )
      2swap 2drop 2swap 2drop true		( optadr,len true )
   else						( pkt,len opts,len )
      CD_OPTION_OVERLOAD (find-dhcp-option) if	( pkt,len ovloption,len )
         drop nip c@  dup 1 3 between if	( pkt ovlopt-value )
            case
               1  of  >dhcp-file  d# 128  endof
               2  of  >dhcp-sname d# 64   endof
               3  of  >dhcp-sname d# 192  endof
            endcase				( adr,len )
            r@ (find-dhcp-option)		( optadr,len true | false )
         else					( pkt n )
            2drop false				( false )
         then					( optadr,len true | false )
      else					( pkt,len )
         2drop false				( false )
      then					( optadr,len true | false )
   then						( optadr,len true | false )
   r> drop					( optadr,len true | false )
;

\ Determine if the packet contains a specific option.
: dhcp-option-found? ( pkt len option# -- found? )
   find-dhcp-option  if  2drop true  else  false  then
;

\ Find a vendor specific option.
: find-vendor-option ( pkt len vendor-option# -- optadr optlen true | false )
   >r						( pkt len ) ( r: opt# )
   CD_VENDOR_SPEC find-dhcp-option  if  	( encap-options,len ) 
      r@ (find-dhcp-option) 			( optadr opten true | false ) 
   else						( )
      false					( false )
   then						( optadr optlen true | false )
   r> drop					( optadr optlen true | false )
;

\ Add an option with a 8-bit value to the packet
: add-dhcpopt-byte ( adr code byte -- adr' )
   rot  >r					( code byte ) ( r: adr )
   swap  r@ >dhcpopt-code  c!			( byte )
   /c    r@ >dhcpopt-len   c!			( byte )
         r@ >dhcpopt-data  c!			( ) 
   r>  3 ca+					( adr' ) ( r: )
;

\ Add an option with a 16-bit value to the packet
: add-dhcpopt-word ( adr code value -- adr' )
   rot >r					( code value ) ( r: adr )
   swap  r@ >dhcpopt-code  c!			( value )
   /w    r@ >dhcpopt-len   c!			( value )
         r@ >dhcpopt-data  htonw!			( )
   r>  4 ca+					( adr' ) ( r: )
;

\ Add an option encoding a stream of bytes to the packet.
: add-dhcpopt-bytes ( adr code data len -- adr' )
   ?dup  if					( adr code data len ) 
      3 roll >r					( code data len ) ( r: adr )
      rot   r@ >dhcpopt-code       c!		( data len )
      dup   r@ >dhcpopt-len        c!		( data len )
      tuck  r@ >dhcpopt-data swap  move		( len )
      r> swap 2+ ca+				( adr' ) ( r: )
   else						( adr code data )
      2drop					( adr' )
   then						( adr' )
;

\ Maximum length of the DHCP message we are willing to accept.
: /dhcp-maxmsg ( -- n )  if-mtu@ /udpip-header - ;

\ The vendor class identifier is constructed from the root node's 
\ "name" property, with commas (,) replaced with periods (.).
: init-dhcp-vendor-classid ( -- )
   " /" " name" get-property  decode-string 2swap 2drop		( $ )
   dhcp-classid pack count bounds ?do				( )
      i c@ ascii , =  if  ascii . i c!  then			( )
   loop								( )
;

\ DHCP initialization. Create a socket, initialize the client and 
\ server socket address structures, and bind local address to the
\ socket. Allocate buffers to send/receive/store DHCP packets and 
\ determine the vendor class identifier to use. 

: dhcp-init ( -- )
   AF_INET SOCK_DGRAM IPPROTO_UDP socreate to dhcp-sockid	( )

   dhcp-cli-addr my-ip-addr       IPPORT_BOOTPC insock-init	( )
   dhcp-srv-addr inaddr-broadcast IPPORT_BOOTPS insock-init	( )

   /dhcp-maxmsg  dup alloc-mem  to dhcp-sndbuf			( n )
                 dup alloc-mem  to dhcp-rcvbuf			( n )
                     alloc-mem  to chosen-bootreply		( )

   dhcp-sockid  dhcp-cli-addr /insock  sobind 		( )

   init-dhcp-vendor-classid					( )
;

\ DHCP state cleanup. Free the DHCP packet buffers and close the 
\ connection. 

: dhcp-close ( -- )
   dhcp-sndbuf /dhcp-maxmsg  tuck  free-mem		( n )
   dhcp-rcvbuf               over  free-mem		( n )
   chosen-bootreply          swap  free-mem		( )
   dhcp-sockid soclose					( )
;

\ Filling in DHCP message options. All DHCP messages include the DHCP 
\ message type and the client identifier (if one is in use). DHCP_REQUEST
\ and DHCP_DECLINE messages must fill the DHCP server identifier and the 
\ offered IP address. Messages other than DHCP_DECLINE must fill in the 
\ DHCP vendor class identifier, the maximum DHCP message size we are 
\ willing to accept, and the list of requested parameters. We explicitly 
\ request values for subnet mask (Option 1), Router (Option 3), Hostname 
\ (Option 12), and Vendor specific information (Option 43). 

: add-dhcp-options ( pkt type -- pktlen )
   >r  dup >dhcp-options			( pkt adr ) ( r: type )

   CD_DHCP_TYPE  r@               add-dhcpopt-byte
   CD_CLIENTID   client-id count  add-dhcpopt-bytes

   r@ DHCP_DECLINE <>  if
      CD_CLASSID       dhcp-classid count  add-dhcpopt-bytes
      CD_REQUEST_LIST  " "(01 03 0c 2b)"   add-dhcpopt-bytes
      CD_MAXMSG_SIZE   /dhcp-maxmsg        add-dhcpopt-word
      CD_HOSTNAME      hostname count      add-dhcpopt-bytes
   then

   r> dup DHCP_REQUEST =  swap DHCP_DECLINE =  or  if
      CD_SERVER_ID   dhcp-server-id  /ip-addr  add-dhcpopt-bytes
      CD_REQ_IPADDR  dhcp-offered-ip /ip-addr  add-dhcpopt-bytes
   then

   CD_END over c!  ca1+  swap -			( pktlen )
;

\ Common code to construct DHCP message to be sent. 
: init-dhcp-packet ( type -- )
   dhcp-sndbuf dup >r  /dhcp-maxmsg erase		( type ) ( r: pkt ) 

   BOOTREQUEST    r@ >dhcp-op           c!
   if-htype@      r@ >dhcp-htype        c!
   if-addrlen@    r@ >dhcp-hlen         c!
   if-hwaddr      r@ >dhcp-chaddr       copy-hw-addr
   dhcp-xid @     r@ >dhcp-xid          htonl!
   my-ip-addr     r@ >dhcp-ciaddr       copy-ip-addr
   BOOTMAGIC      r@ >dhcp-cookie       htonl!

   r> swap add-dhcp-options  dhcp-sndbuflen !		( ) ( r: )
;

\ Transmit formatted DHCP message.
: send-dhcp-packet ( -- )
   dhcp-sockid  dhcp-sndbuf dhcp-sndbuflen @		( sockid pkt len )
   DHCP_MIN_PKTLEN max					( sockid pkt len' )
   0 dhcp-srv-addr /insock  sosendto  drop		( )
;

\ Managing DHCP retransmissions. Use a randomized exponential backoff 
\ to determine delay between retransmissions. On retries, the delay is
\ doubled (for a maximum of 64 seconds), and randomized by a random 
\ number in the range +/-1.023 seconds.

: dhcp-backoff ( -- )
   dhcp-timer clear-timer   2*  d# 64000 min			( timeout )
   random  dup d# 22 rshift  swap 0<  if  negate  then  +	( timeout' )
   dhcp-timer swap set-timer					( )
;

: retransmit-dhcp-packet ( -- )
   send-dhcp-packet  dhcp-backoff
;

\ Determine DHCP packet type. BOOTP packets are tagged as type 0.
: dhcp-packet-type ( pkt len -- type )
   over >dhcp-cookie ntohl@  BOOTMAGIC =  if			( pkt,len )
      CD_DHCP_TYPE find-dhcp-option  if  drop c@  else 0 then	( type )
   else								( pkt,len )
      2drop 0							( 0 )
   then								( type )
;

\ Receive data arriving on the socket. 
: (receive-dhcp-packet) ( -- pkt len )
   dhcp-sockid dhcp-rcvbuf tuck /dhcp-maxmsg 0 0 0 sorecvfrom
;

\ Incoming responses must be BOOTREPLY packets, and the xid should match.
: receive-dhcp-packet ( -- pkt len true | false )
   (receive-dhcp-packet)  dup 0=        if  2drop false exit  then
   over >dhcp-op c@  BOOTREPLY <>       if  2drop false exit  then
   over >dhcp-xid ntohl@  dhcp-xid @ <> if  2drop false exit  then
   true
;

\ Receive OFFER messages from the server. BOOTP responses must be
\ accepted as well.
: receive-dhcp-offer ( -- pkt len true | false )
   receive-dhcp-packet 0=  if  false exit  then		( pkt len )
   2dup dhcp-packet-type				( pkt len type )
   dup                 0=  if  drop true exit    then	( pkt len type )
   DHCP_OFFER          <>  if  2drop false exit  then	( pkt len )
   2dup CD_SERVER_ID find-dhcp-option if		( pkt len optadr,len )
      2drop true					( pkt len true )
   else							( pkt len )
      ." Ignoring OFFER with missing DHCP server identifier" cr
      2drop false					( false )
   then							( pkt len true | false )
;

\ Receive an ACK/NAK response from the server.
: receive-dhcp-ack/nak ( -- pkt len true | false )
   receive-dhcp-packet 0=  if  false exit  then		( pkt len )
   2dup dhcp-packet-type				( pkt len type )
   dup DHCP_ACK <>  swap DHCP_NAK <>  and  if		( pkt len )
      2drop false					( false )
   else							( pkt len )
      true						( pkt len true )
   then							( pkt len true | false )
;

\ Receive an ACK in response to the INFORM message we sent. Responses
\ from a BOOTP server must be accepted as well. 
: receive-dhcpinform-response ( -- pkt len true | false ) 
   receive-dhcp-packet 0=  if  false exit  then		( pkt len )
   2dup dhcp-packet-type				( pkt len type )
   dup DHCP_ACK <>  swap 0<>  and  if			( pkt len )
      2drop false					( false )
   else							( pkt len )
      true						( pkt len true )
   then							( pkt len true | false )
;

\ Stash away a response received from the server. 
: store-dhcp-response ( adr len -- )
   dup >r  chosen-bootreply swap move  r> to /chosen-bootreply
;

\ Wait for the expected response.
: (dhcp-response-wait) ( xt -- pkt len true | false )
   begin                                                ( xt )
      dhcp-timer timer-expired?                         ( xt timed-out? )
   0= while                                             ( xt )
      dup execute  if                                   ( xt pkt len )
         rot drop true exit                             ( pkt len true )
      then                                              ( xt )
   repeat                                               ( xt )
   drop false                                           ( false )
;

\ Wait for expected response, retransmitting the sent packet if necessary.
: dhcp-response-wait ( xt ntries -- pkt len true | false )
   begin                                          	( xt ntries )
      over (dhcp-response-wait)  if                     ( xt ntries pkt len )
         2swap 2drop true exit                          ( pkt len true )
      then                                              ( xt ntries )
      ." Timed out waiting for BOOTP/DHCP reply" cr	( xt ntries )
      1-                                                ( xt ntries' )
   dup 0 u>  while                                      ( xt ntries' )
      retransmit-dhcp-packet  				( xt ntries' )
   repeat                                               ( xt ntries' )
   2drop false                                          ( false )
;

\ Wait for a minimum of 10 seconds if restarting the configuration
\ process after a failure.
: dhcp-restart ( -- )
   d# 10.000 ms  DHCPS_INIT dhcp-state !
;

\ INIT state processing. Select a random transaction identifier to use
\ in DHCP packets. Move to INFORM state if using an externally configured 
\ IP address; else move to SELECTING state.

: dhcps-init ( -- )
   random dhcp-xid l!
   my-ip-addr inaddr-any?  if  DHCPS_SELECTING  else  DHCPS_INFORM  then
   dhcp-state !
;

\ INFORM state processing. Send a DHCPINFORM and wait for a DHCPACK.
\ If a DHCPACK is not received even after 4 retries, enter CONFIGURED 
\ state and hope for the best. 

: dhcps-inform ( -- )
   DHCP_INFORM init-dhcp-packet  send-dhcp-packet		( )
   dhcp-timer d# 4000 set-timer					( )
   ['] receive-dhcpinform-response 4  dhcp-response-wait  if	( pkt len )
      store-dhcp-response					( )
      DHCPS_BOUND dhcp-state !					( )
   else
      DHCPS_CONFIGURED dhcp-state !				( )
   then								( )
;

\ Selecting the best DHCPOFFER. We select the best OFFER from the possibly 
\ many incoming OFFER messages. OFFERs are evaluated using a points-based
\ system we share with inetboot/wanboot. We prefer DHCP configurations
\ which provide the most configuration information.

: compute-offer-points ( pkt len -- #points )
   over >dhcp-cookie ntohl@  BOOTMAGIC <>  if
      2drop 0 exit
   then

   d# 5
   CD_DHCP_TYPE   2over rot dhcp-option-found? if  d# 30 +  then
   CD_VENDOR_SPEC 2over rot dhcp-option-found? if  d# 80 +  then
   CD_SUBNETMASK  2over rot dhcp-option-found? if  1+       then
   CD_ROUTER      2over rot dhcp-option-found? if  1+       then
   CD_HOSTNAME    2over rot dhcp-option-found? if  d# 5 +   then

   CD_OPTION_OVERLOAD 2over rot dhcp-option-found? 0=  if
      2 pick  >dhcp-sname c@ 0<>  if  d# 10 +  then
      2 pick  >dhcp-file  c@ 0<>  if  d# 5  +  then
   then

   2 pick  >dhcp-siaddr inaddr-any? 0=  if  d# 10 +  then
   nip nip
;

\ Process incoming offer and keep track of the best offer received. 
: process-offer ( pkt len -- )
   2dup compute-offer-points dup best-offer-points <=  if	( pkt len pts )
      3drop exit						( )
   then								( pkt len pts )
   to best-offer-points						( pkt len )
   store-dhcp-response						( )
;

\ Record information from the OFFER we selected. 
: process-best-offer ( -- )
   chosen-bootreply /chosen-bootreply				( pkt len )
   2dup  dhcp-packet-type 0=  to bootp-config?			( pkt len )
   over >dhcp-yiaddr dhcp-offered-ip copy-ip-addr		( pkt len )
   CD_SERVER_ID find-dhcp-option  if				( opt-adr,len )
      drop dhcp-server-id  copy-ip-addr				( )
   then								( )
;

\ SELECTING state processing. Broadcast a DISCOVER and sift through
\ the OFFERs to select the best one.  We "collect" OFFERs for a period 
\ of 4 seconds after the first OFFER is received. If the best offer
\ is a BOOTP configuration, move to the BOUND state, else move to the 
\ REQUESTING state. 

: dhcps-selecting ( -- )
   DHCP_DISCOVER init-dhcp-packet  send-dhcp-packet		( )
   dhcp-timer d# 8000 set-timer					( )
   ['] receive-dhcp-offer dhcp-max-retries 			( xt ntries )
   dhcp-response-wait  0=  if					( )
      ." No DHCP response after"  dhcp-max-retries .d ." tries" cr
      -1 throw
   then                                                 	( pkt len )
   process-offer                                        	( )
   dhcp-timer d# 4000 set-timer					( )
   begin							( )
      ['] receive-dhcp-offer (dhcp-response-wait)
   while							( pkt len )
      process-offer						( )
   repeat							( )
   process-best-offer						( )
   bootp-config? if DHCPS_BOUND else DHCPS_REQUESTING then  dhcp-state !
;

\ REQUESTING state processing. Broadcast a DHCPREQUEST requesting offered
\ parameters from one server (and implicitly declining OFFERS from other 
\ servers) and wait for a DHCPACK. On arrival of a DHCPACK, move to the 
\ VERIFYING state to perform a check on the offered IP address. 
\
\ If a DHCPNAK is received, or there is no response to the DHCPREQUEST
\ even after 4 retries, restart the initialization process.

: dhcps-requesting ( -- )
   DHCP_REQUEST init-dhcp-packet  send-dhcp-packet		( )
   dhcp-timer d# 4000 set-timer					( )
   ['] receive-dhcp-ack/nak 4 dhcp-response-wait  if		( pkt len )
      2dup  dhcp-packet-type DHCP_ACK =  if			( pkt len )
         store-dhcp-response					( )
         DHCPS_VERIFYING dhcp-state !				( )
      else							( pkt len )
         2drop  dhcp-restart					( )
      then							( )
   else								( )
      dhcp-restart						( )
   then								( )
;

\ VERIFYING state processing. Issue an ARP request for the offered 
\ IP address. If the IP address appears to be in use, send a DHCPDECLINE
\ message to the server and restart the initialization process; else,
\ move to the BOUND state.

: dhcps-verifying ( -- )
   dhcp-offered-ip 1 arp-check if
      ." IP Address " dhcp-offered-ip .ipaddr ."  already in use" cr
      DHCP_DECLINE init-dhcp-packet  send-dhcp-packet
      dhcp-restart
   else
      dhcp-offered-ip my-ip-addr copy-ip-addr
      DHCPS_BOUND dhcp-state !
   then
;

\ BOUND state processing. Extract n/w and boot configuration information
\ we care about from the DHCP/BOOTP response. We dont deal with IP
\ address lease times, pushing that responsibility to DHCP modules
\ in the OS. 

: dhcp-set-bootsrv,file ( pkt len -- )

   \ Check if boot server and filename are known.
   bootfile count is-uri?            if  2drop exit  then	( pkt len )
   bootfile count nip  if					( pkt len )
      tftp-server-ip inaddr-any? 0=  if  2drop exit  then
   then								( pkt len )

   \ If the package arguments did not specify use of TFTP, and
   \ the DHCP response provides a (TFTP or HTTP) URI, set the
   \ bootfile and exit.
   \
   \ If the package arguments specifies use of TFTP, and the
   \ DHCP response provides a TFTP URI, then either the TFTP
   \ server or the filename is being overridden. Decode the
   \ URI and set those fields appropriately.
   \
   \ Else, if TFTP must be used, but a HTTP URL was provided
   \ in the DHCP response, ignore the URL specification.

   2dup VS_BOOT_URI find-vendor-option if			( pkt len $ )
      2dup check-uri$-form					( pkt len $ )
      tftp-server-ip inaddr-any? bootfile count nip 0= and if	( pkt len $ )
         bootfile pack drop  2drop exit				( )
      then							( pkt len $ )
      2dup is-tftp-uri?  if					( pkt len $ )
         tftp-server-ip inaddr-any?  if				( pkt len $ )
            2dup tftpuri>srv tftp-server-ip inet-aton drop	( pkt len $ )
         then							( pkt len $ )
         bootfile count nip 0=  if				( pkt len $ )
            2dup tftpuri>file bootfile pack drop		( pkt len $ )
         then							( pkt len $ )
         2drop 2drop exit					( )
      then  2drop						( pkt len )
   then								( pkt len )

   \ Extract TFTP boot information from the standard bootfile
   \ and TFTP server fields.

   bootfile count  nip 0=  if					( pkt len )
      2dup CD_BOOTFILE_NAME find-dhcp-option 0=	 if		( pkt len )
         over >dhcp-file dup cstrlen				( pkt len $ )
      then  bootfile pack drop					( pkt len )
   then								( pkt len )
   tftp-server-ip inaddr-any?  if				( pkt len )
      over >dhcp-siaddr tftp-server-ip copy-ip-addr		( pkt len )
   then								( pkt len )
   2drop							( )
;

: dhcps-bound ( -- )
   chosen-bootreply /chosen-bootreply			( pkt,len )
   my-netmask inaddr-any?  if				( pkt,len )
      2dup CD_SUBNETMASK find-dhcp-option  if		( pkt,len adr,len ) 
         drop my-netmask copy-ip-addr			( pkt,len )
      then						( pkt,len )
   then							( pkt,len )
   router-ip inaddr-any?  if				( pkt,len )
      2dup CD_ROUTER find-dhcp-option  if		( pkt,len adr,len )
         drop router-ip copy-ip-addr			( pkt,len )
      then						( pkt,len )
   then							( pkt,len )
   2dup dhcp-set-bootsrv,file				( pkt,len )
   http-proxy count nip 0=  if				( pkt,len )
      2dup VS_HTTP_PROXY find-vendor-option  if		( pkt,len proxy$ )
         2dup check-htproxy$-form http-proxy pack drop	( pkt,len )
      then						( pkt,len )
   then							( pkt,len )
   2drop						( )
   DHCPS_CONFIGURED dhcp-state !			( )
;

: "bootp-response" ( -- $ )  " bootp-response" ;	\ Space savings

\ CONFIGURED state processing. Publish contents of DHCPACK, if one was
\ received, in /chosen:bootp-response.
: dhcps-configured ( -- )
   chosen-bootreply /chosen-bootreply dup  if
      encode-bytes "bootp-response" set-chosen-property
   else
      2drop
   then
;

: (do-dhcp) ( -- )
   DHCPS_INIT dhcp-state !
   begin
      dhcp-state @  case
         DHCPS_INIT       of   dhcps-init              endof
         DHCPS_INFORM     of   dhcps-inform            endof
         DHCPS_SELECTING  of   dhcps-selecting         endof
         DHCPS_REQUESTING of   dhcps-requesting        endof
         DHCPS_VERIFYING  of   dhcps-verifying         endof
         DHCPS_BOUND      of   dhcps-bound             endof
         DHCPS_CONFIGURED of   dhcps-configured  exit  endof
      endcase
   again
;

: do-dhcp ( -- )
   dhcp-init					( )
   ['] (do-dhcp) catch				( throw? )
   dhcp-close					( throw? )
   throw					( )
;

headers
