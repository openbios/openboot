\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dev-required.fth
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
id: @(#)dev-required.fth 1.7 01/09/20
purpose: 
copyright: Copyright 1998-2001 Sun Microsystems, Inc.  All Rights Reserved

create bad-number			\ "Bad number syntax"
   d# 17 c,
   ascii B c,  ascii a c,  ascii d c,  bl c,  ascii n c,
   ascii u c,  ascii m c,  ascii b c,  ascii e c,  ascii r c,
   bl c,  ascii s c,  ascii y c,  ascii n c,  ascii t c,
   ascii a c,  ascii x c,  0 c,

: $>number  ( adr len -- n )
   $number  if  bad-number throw  then
;

: $>numbers  ( adr len -- n1 n2 )
   ascii , left-parse-string
   $>number >r
   ?dup  if  $>number  else  drop 1  then		\ default to config1
   r>
;

external

: decode-unit  ( adr len -- config# interface# )
   base @ >r  hex
   dup if  $>numbers
   else  2drop 1 0			\ default to config1 int0
   then
   r> base !
;

10 buffer: unit-address		\ can be used when no instance is active

: encode-unit  ( config# interface# -- adr len )
   unit-address 10 erase
   base @ >r  hex
   swap
   <#  dup 1 =  if
         drop
      else  u#s  ascii , hold
      then
      u#s
   u#>
   dup >r
   unit-address swap move
   unit-address r>
   r> base !
;


: current-frame  ( -- n )  " current-frame" $call-parent  ;

: disable-int-transactions  ( token -- toggle )
   " disable-int-transactions" $call-parent
;

: enable-int-transactions
	( ms tgl lo-spd? dir max-pkt buf-len endp usb-adr -- token )
   " enable-int-transactions" $call-parent
;

: execute-bulk  ( toggle1 dir max-pkt buf-addr buf-len endpoint usb-adr
					-- toggle2 hw-err? | toggle2 stat 0 )
   " execute-bulk" $call-parent
;

: execute-control
	( lo-spd? dir max-pkt buf-adr buf-len req-adr req-len endp usb-adr
							-- hw-err? | stat 0 )
   " execute-control" $call-parent
;

: execute-isochronous  ( buf-adrn cntn ... buf-adr1 cnt1 n absolute?
			     frame# dir max-pkt endpoint usb-adr -- hw-err? )
   " execute-isochronous" $call-parent
;

: execute-1-interrupt
	( tgl1 lo-spd? dir max-pkt buf-adr buf-len endp usb-adr
					-- tgl2 hw-err? | tgl2 stat 0 )
   " execute-1-interrupt" $call-parent
;

: int-transaction-status  ( buf-adr token -- hw-err? | stat 0 )
   " int-transaction-status" $call-parent
;

: next-usb-address  ( -- n )  " next-usb-address" $call-parent  ;


: open  ( -- ok )  true  ;
: close  ( -- )  ;
: reset  ( -- )  ;

headers
