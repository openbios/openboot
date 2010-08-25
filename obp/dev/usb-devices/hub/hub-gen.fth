\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hub-gen.fth
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
id: @(#)hub-gen.fth 1.4 00/07/27
purpose: 
copyright: Copyright 1998, 2000 Sun Microsystems, Inc.  All Rights Reserved

fload ${BP}/dev/usb/gen.fth

external

: current-frame  ( -- n )  " current-frame" $call-parent  ;

: disable-int-transactions  ( token -- toggle )
   " disable-int-transactions" $call-parent
;

: enable-int-transactions
	( ms tgl lo-spd? dir max-pkt buf-len endp usb-adr -- token )
   " enable-int-transactions" $call-parent
;

\ : execute-bulk  ( toggle1 dir max-pkt buf-addr buf-len endpoint usb-adr
\					-- toggle2 hw-err? | toggle2 stat 0 )
\   " execute-bulk" $call-parent
\ ;

: execute-control
	( lo-spd? dir max-pkt buf-adr buf-len req-adr req-len endp usb-adr
							-- hw-err? | stat 0 )
   " execute-control" $call-parent
;

\ : execute-isochronous  ( buf-adrn cntn ... buf-adr1 cnt1 n absolute?
\			     frame# dir max-pkt endpoint usb-adr -- hw-err? )
\   " execute-isochronous" $call-parent
\ ;

: execute-1-interrupt
	( tgl1 lo-spd? dir max-pkt buf-adr buf-len endp usb-adr
					-- tgl2 hw-err? | tgl2 stat 0 )
   " execute-1-interrupt" $call-parent
;

: int-transaction-status  ( buf-adr token -- hw-err? | stat 0 )
   " int-transaction-status" $call-parent
;

: next-usb-address  ( -- n )  " next-usb-address" $call-parent  ;
