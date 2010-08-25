\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pkg.fth
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
id: @(#)pkg.fth 1.1 06/02/16
purpose: Intel Ophir/82571 external interface
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 instance value obp-tftp

: init-obp-tftp ( tftp-args$ -- okay? )
   " obp-tftp" find-package  if  
      open-package  
   else  
      ." Can't open OBP standard TFTP package"  cr
      2drop 0  
   then
   dup to obp-tftp
;

: (setup-link) ( -- link-up? )
   net-on  if
      setup-transceiver 		( link-up? )
   else
      false				( link-up? )
   then
;

\ Needed?
: (restart-net) ( -- link-up? )  
   false to restart?
   (setup-link)
;

['] (restart-net) to restart-net

: setup-link ( -- [ link-status ] error? ) 
   ['] (setup-link) catch
;

: bringup-link ( -- ok? )
   d# 20000 get-msecs +  false
   begin
      over timed-out? 0=  over 0=  and
   while
      setup-link  if  2drop false exit  then    ( link-up? )
      if 
         drop true
      else
         " Retrying network initialization"  diag-type-cr
      then
   repeat nip
;

external

: close	 ( -- )
   obp-tftp ?dup  if  close-package  then
   reg-base  if  net-off unmap-resources  then
;

: open  ( -- flag )
   map-resources
   my-args parse-devargs
   init-obp-tftp 0= if  close false exit  then
   bringup-link ?dup 0=  if  close false exit  then
   publish-properties
   mac-address encode-bytes  " mac-address" property
;

headers

[ifdef] Ontario
\ The following code compares the MAC address assigned by the system
\ to the MAC address programmed in the Ophir EEPROM. This step is 
\ required because Intel reloads the MAC addresses from the EEPROM 
\ when the controler is reset (going into loopback mode during SunVTS 
\ for example) so we have to make sure the EEPROM matches what we 
\ assign the device
: update-mac-address ( -- )
   map-resources			(  )
   " local-mac-address" 		( propstr,len )
   get-my-property 2drop		( mac-adr-ptr )
   dup w@ wbflip >r			( mac-adr-ptr )( R: mac0 )
   dup 2 + w@ wbflip >r			( mac-adr-ptr )( R: mac0 mac1 )
   4 + w@ 1 invert and wbflip r> r>	( mac2' mac1 mac0 )
   3dup false				( mac2' mac1 mac0 mac2' mac1 mac0 flag )
   swap 0 eeprom-w@ <> or		( mac2' mac1 mac0 mac'2 mac1 flag )
   swap 1 eeprom-w@ <> or		( mac2' mac1 mac0 mac2' flag )
   swap 2 eeprom-w@ <> or if		( mac2' mac1 mac0 )
      0 eeprom-w! 1 eeprom-w!		( mac2' )
      2 eeprom-w! checksum		( checksum )
      h# 3f eeprom-w!			(  )
   else					( mac2' mac1 mac0 )
      3drop				(  )
   then					(  )
   unmap-resources			(  )
;

update-mac-address

[then]

: xmit  ( buffer length -- #sent )
   link-up? 0=  if
      \ >>> cmn-xxx
      " Link is down. Restarting network initialization" diag-type-cr
      restart-net if
          2drop 0 exit
      then
   then                                                  ( buffer len )
   get-tx-buffer swap                                    ( buffer txbuf len )
   2dup >r >r cmove r> r>                                ( txbuf len )
   tuck                                                  ( len txbuf len )
   d# 64  max						 ( len txbuf len' )
   transmit 0=  if  drop 0  then                         ( #sent )
;

: poll  ( buffer len -- #rcvd )
   receive-ready?  0=  if  
      2drop 0 exit  
   then
   receive ?dup  if                           ( buffer len handle pkt pktlen )
      rot >r rot min >r swap r@ cmove r> r>   ( #rcvd handle ) 
   else                                       ( buffer len handle pkt )
      drop nip nip 0 swap                     ( 0 handle )
   then
   return-buffer    
;

external

: read  ( buf len -- -2 | actual-len )
   poll  ?dup  0=  if  -2  then
;

: write  ( adr len -- len' )
   xmit
;

: load  ( adr -- size )
   " load" obp-tftp $call-method 
;

: watch-net  ( -- )
   map-resources
   my-args parse-devargs 2drop		( )
   promiscuous to mac-mode
   bringup-link				( ok? )	
   if  watch-test  then
   net-off
   unmap-resources
;

headers

: reset  ( -- )
   reg-base  if
      net-off unmap-resources
   else
      map-regs net-off unmap-regs
   then
;
