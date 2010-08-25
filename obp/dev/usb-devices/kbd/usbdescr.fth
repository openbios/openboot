\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usbdescr.fth
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
\ id: @(#)usbdescr.fth 1.7 04/09/22
\ purpose: 
\ copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

\ This file holds usb-specific methods for keyboards.

\ headerless			\ XXX keep heads for debugging
external


struct  \ Standard control transfer packet format, used for many HID
        \ transactions, including set-configuraion, get-configuration,
        \ get-interface, get-descriptor, and others.
   1  field >ctrl-pkt-breqtype 	\ bmRequestType
   1  field >ctrl-pkt-brequest	\ bRequest
   2  field >ctrl-pkt-wvalue	\ wValue
   2  field >ctrl-pkt-windex	\ wIndex
   2  field >ctrl-pkt-wlength	\ wLength
constant /ctrl-pkt

struct  \ HID descriptor, kbd - filled as the "data" in a Get Descriptor req.
   1  field >hid-descr-size	\ bLength
   1  field >hid-descr-type	\ bDescriptorType
   2  field >hid-release	\ bcdHID
   1  field >hid-country	\ bCountryCode
   1  field >hid-#descriptors	\ bNumDescriptors
   1  field >hid-type		\ bDescriptorType
   2  field >hid-repsize	\ wDescriptrorLength (of Report Descriptor)
constant /hid-descriptor
   
external
0 constant my-endpt	\ Always 0; endpt 0 for cntrl xfers for HID devices.
1 value my-int-endpt	\ actually set later by inheritance.
0 value my-addr		\ Set later with get-inherited-property.
true value my-speed	\ Set from property; low-speed default for Sun
8 value 0max-packet	\ Set from property; default for Sun
8 value my-int-max-packet	\ Set later from endpoints property;
			\ default for Sun
0 value my-interface	\ interface#=0 for kbd; default for Sun

0 ( instance ) value 1-byte^v

0 instance value attempt-cnt

\ Do some sort of control transfer.  Use a loop to make the attempt
\ several times and throw if unsuccessful (hw-err, nak or stall).
\ This is not used when getting the key reports since that process
\ will make an attempt to unstall (if necessary), and accepts a nak
\ as a normal event.

: do-ctrl/err-loop  ( xt -- )
   5 to attempt-cnt                              ( xt )
   begin
      dup execute				( xt {hw-err? | stat 0} )
      0<> if              \ hw-err		( xt )
          drop true throw
      then
      h# a = if           \ nak			( xt )
         attempt-cnt 1- dup to attempt-cnt        ( xt attempt-cnt )
         0> if
            false                                 ( xt noexit-loop-flag )
         else             \ made 5 attempts to get it ...
            drop true throw
         then
      else		  \ got the ack
         true                                     ( xt exit-loop-flag )
      then                                        ( xt loop-flag )
   until                                         ( xt )
   drop
;

\ Run an execute-control command to get the HID class descriptor.

: get-hid-class-descr  ( -- hw-err? | stat 0 )

   h# 81 get-descr-buff^v >ctrl-pkt-breqtype c!	  \ 0x81= ReqType-HID-Cl-Descr
   6 get-descr-buff^v >ctrl-pkt-brequest     c!	  \ 6=GET-DESCRIPTOR
   h# 2100 get-descr-buff^v >ctrl-pkt-wvalue le-w! \ 0x21=descr-type=hi byte of
						  \ wValue; low byte is always
						  \ 0 if other than the
						  \ standard descr is used
   my-interface get-descr-buff^v >ctrl-pkt-windex le-w!
   /hid-descriptor
      get-descr-buff^v >ctrl-pkt-wlength     le-w! \ len of hid class descr
						   \ that will be returned

   my-speed
   0			\ dir=yes xfer data
   0max-packet		\ max-pkt
   hid-descr-buff^v  	\ buf-adr
   /hid-descriptor	\ buf-len
   get-descr-buff^v	\ request-adr
   /ctrl-pkt		\ request-len
   my-endpt  my-addr	\ endpt; usb-adr
   ( speed dir max-pkt buf-adr buf-len rqst-adr rqst-len end-pt usb-adr )

   execute-control	( hw-err? | stat 0 )
;


: get-kbd-cntry-id  ( -- cntry-code )
   ['] get-hid-class-descr do-ctrl/err-loop	( )
   hid-descr-buff^v >hid-country c@
;
