\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probe.fth
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
id: @(#)probe.fth 1.25 05/09/30
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ must do dma-free on adr2 len2 after fcode is used:
: find-fcode  ( adr1 len1 -- adr2 len2 true | false )
   " sunw,find-fcode" get-inherited-property drop
   decode-int nip nip
   execute
;

: find-device-fcode  ( -- addr len )  " device"  find-fcode drop  ;

: find-combined-fcode  ( -- addr len )  " combined"  find-fcode drop  ;

: assign-address  ( speed usb-addr -- hw-err? | stat 0 )
\   next-usb-address ?dup  if
      set-address-form >r			\ uses request-blank
      ( speed ) 1 max-packet 0 0 r> /request 0 0 execute-control
\   else  no-more-addresses
\   then
   d# 10 ms			\ allow assignment to take effect
				\ should need only 2 ms
;

: set-configuration  ( speed usb-addr config -- hw-err? | stat 0 )
   1 max-packet 2swap  0 0 2swap
			( speed dir max-pkt dat-adr dat-len usb-addr config )
   0 -rot		\ endpoint
   clean-request-blank 			\ dma-free at end of probe or close
   set-config-req over request-type w!
   swap over req-value le-w!
   /request  2swap   ( speed dir max-pkt dat-adr dat-len req-adr req-len )
   execute-control
;

\ dma-alloc because of get-descriptors
: get-dev-descrip  ( speed usb-adr -- dev-descrip-addr dcnt hw-err? | stat 0 )
   0 swap max-packet swap
   /dev-descriptor dma-alloc		\ only needed at probe time
   dup >r swap
   /dev-descriptor swap
   /dev-descriptor get-dev-descript-form
   swap
   /request swap
   0 swap execute-control
   ?dup
   r> /dev-descriptor
   2swap
   0=  if  0  then
;

\ dma-alloc data area because of get-descriptors
: get-config-descrip  ( speed usb-adr n cnt
				-- config-n-descrip-addr cnt hw-err? | stat 0 )
   swap rot >r >r >r				( R: usb-addr n cnt )
   0 max-packet
   r@ dma-alloc		( speed in max c-d-addr )  \ only used at probe time
   r> r> r>				( speed in max c-d-addr cnt n u-addr )
   2over >r >r >r >r			( R: cnt c-d-addr u-addr n )
   dup get-config-descript-form
   r> over req-value c!		( speed in max c-d-addr cnt pak-adr )
					( R: cnt c-d-addr usb-addr )
   /request 0 r>  execute-control
   ?dup
   r> r>
   2swap
   0=  if  0  then
;

: get-config1-descrip  ( speed usb-adr
				-- config1-descrip-addr ccnt hw-err? | stat 0 )
   0 /config-descriptor get-config-descrip
;

: ?create-speed  ( lo-speed? -- )
   if  0 0  " low-speed" property  then
;

: create-address  ( usb-addr -- )
   encode-int  " assigned-address" property
;

: combined-node?  ( config-desc dev-desc -- combined? )
   dup d-descript-class c@
   dup 9 = swap 0= or		( c-desc d-desc dev-ok? )
   swap d-descript-#configs c@ 1 =  and
   swap c-descript-#interfaces c@ 1 =  and
;

: make-child  ( fcode-adr unit-str unit-len speed usb-adr -- )
   child-max
   new-device
   ( child-max ) encode-int " 0max-packet" property
   create-address ?create-speed
   " "  2swap set-args
   1 byte-load
   finish-device
;

: .usb  ( stat -- )
   case  2 of  noop              endof		\ patchable
         6 of  cr ." usb-nak"    endof
         e of  cr ." usb-stall"  endof
      cr ." usb-unknown"
   endcase
;

: stall-or-nak?  ( stat -- stall-or-nak? )
   dup .usb
   dup e =  swap 6 =  or
;

: idump  ( adr len -- )			\ XXX debug
   " dump" $find drop execute
;

: clean-port  ( port -- )		\ acts on the hub
   dup reset-port			\ includes enable-port
   dup clear-connect-change
   dup clear-port-reset
   dup clear-port-enable
   clear-port-suspend
;

: set-default-max-packet  ( speed -- )
   if				\ low speed
      8 to child-max
      8 to max-packet
   else				\ reg. speed
      d# 64 to child-max
      d# 64 to max-packet
   then
;

defer complete-probe  ( port speed )
' 2drop is complete-probe		\ for a good node already created

\ Start with a new device at usb 0, port, and known speed (low or normal).
\ no-retry? (non-zero) if really fatal or succeeded.  retry (zero) if want to
\ go back to reset-port
: probe-once  ( port speed -- no-retry? )
   ['] 2drop is complete-probe		\ default to good device node on each pass
   dup set-default-max-packet
\   d# 150 ms			\ for Microsoft device settling; only hot-plug?
   " dev-descrip" diag-crtype
   dup 0 get-dev-descrip	( port speed dev-d-adr dcnt hw-err? | stat 0 )
   dup no-response-error =  if		\ wait for device that powers up slowly
      drop dma-free
      over clean-port
      d# 2000 ms		\ maybe only 500 needed?
      dup 0 get-dev-descrip	( port speed dev-d-adr dcnt hw-err? | stat 0 )
   then
   ?dup  if
      data-overrun-error <>  if		\ data-over benign here
         dma-free
         2drop
         ['] won't-send-descriptor is complete-probe
         false exit			( retry )
      then
   else  stall-or-nak?  if
         dma-free 2drop
         ['] won't-send-descriptor is complete-probe
         false exit			( retry )
      then
   then					( port speed dev-d-adr dcnt )
   over d-descript-maxpkt c@  to child-max
   dma-free
   over clean-port
   " next-add" diag-crtype
   child-max to max-packet
   next-usb-address 2dup assign-address ( port speed usb-adr hw-err? | stat 0 )
   ?dup  if
      drop				\ XXX the error code; already printed
      drop				\ XXX will use up usb-adrs
      2drop
      ['] won't-take-address is complete-probe
      false exit			( retry )
   else  stall-or-nak?  if
         drop				\ XXX will use up usb-adrs
         2drop
         ['] won't-take-address is complete-probe
         false exit			( retry )
      then
   then					( port speed usb-adr )
   " get-config1" diag-crtype
   2dup get-config1-descrip
			( port spd usb-addr cnfg-adr cnt hw-err? | stat 0 )
   ?dup  if
      drop				\ XXX some hw-err; already printed
      dma-free
      drop				\ XXX will use up usb-adrs
      2drop
      ['] won't-send-config is complete-probe
      false exit			( retry )
   else  stall-or-nak?  if
         dma-free
         drop				\ XXX will use up usb-adrs
         2drop
         ['] won't-send-config is complete-probe
         false exit			( retry )
      then
   then					( port spd usb-addr cnfg-adr cnt )
   over c-descript-config-id c@ >r		\ get bconfigvalue
   dma-free
   " set-config" diag-crtype
   2dup r> set-configuration	\ config index 1, using bconfigvalue
   ?dup  if				( port spd usb-addr hw-err? )
      drop				\ XXX hw-err; already printed
      drop 2drop
      ['] won't-take-config is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         drop 2drop
         ['] won't-take-config is complete-probe
         true exit			( no-retry )
      then
   then					( port spd usb-adr )
   " get-config1-descript" diag-crtype
   2dup get-config1-descrip
		( port speed usb-adr config-desc ccnt hw-err? | stat 0 )
   ?dup  if
      drop				\ XXX some hw-err; already printed
      dma-free
      drop 2drop
      ['] won't-send-descriptor is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         dma-free
         drop 2drop
         ['] won't-send-descriptor is complete-probe
         true exit			( no-retry )
      then
   then				( port spd usb-adr cadr ccnt )
   " get-dev-descrip" diag-crtype
   2over get-dev-descrip
		( port spd usb-adr cadr ccnt dadr dcnt hw-err? | stat 0 )
   ?dup  if
      drop				\ XXX hw-err; already printed
      dma-free dma-free
      drop 2drop
      ['] won't-send-descriptor is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         dma-free dma-free
         drop 2drop
         ['] won't-send-descriptor is complete-probe
         true exit			( no-retry )
      then
   then
   " descripts" diag-crtype
   ( port spd usb-adr config-desc ccnt dev-desc dcnt )
\   2dup cr ." dev descrip" cr idump	\ XXX debug
\   2over cr ." con descrip" cr idump	\ XXX debug
   3 pick 2 pick  combined-node?  if
      " finding combined" diag-crtype
      find-combined-fcode
   else
      " finding device" diag-crtype
      find-device-fcode
   then
   >r >r
   dma-free dma-free
   r@	( port speed usb-adr fcode-adr ) ( R: f-len f-adr )
   -rot >r >r swap
   encode-unit  r> r>
   make-child
   r> r> dma-free		\ toss fcode; only at probe time
   " node made" diag-crtype
   true					( no-retry )
;

\ give a device two chances.  if not enumerated ok after two tries, make a
\ bad device node.  leave open the option for other actions, depending on the
\ precise failure.
: probe-port  ( port -- )
   2 0 do
      dup clean-port
      dup dup port-low-speed?		\ bug 6261224, for Cypress hub chip
      probe-once
      if  leave  then
   loop
   dup port-low-speed?
   complete-probe
;

: probe-ports  ( -- )
   #ports 1+  1  do
      i power-port			\ leave port on -- possible hot-plug
      i port-connected?  if		\ unpowered is not connected
         i probe-port
      then
   loop
;

\ looks like not needed
: read-power-bits  ( hub-descript -- )  drop  ;

: read-my-data  ( -- went-ok? )	\ read descriptors and figure out what's what
   0max-packet to max-packet
   speed my-usb-addr get-dev-descrip	( dadr dcnt hw-err? | stat 0 )
   ?dup  if
      drop
      dma-free
      " disabled" encode-string  " status" property
      false  exit
   else  stall-or-nak?  if
         dma-free
         " disabled" encode-string  " status" property
         false  exit
      then
   then
   over d-descript-maxpkt c@  to 0max-packet
\ would need endpt descriptor for max packet for endpt. <> 0
   dma-free
   0max-packet to max-packet
   7 get-hub-descript				\ get the real descript size
   ?dup  if
      drop
      drop				\ common-buffer; no dma-free here
      " disabled" encode-string  " status" property
      false  exit
   else  stall-or-nak?  if
         drop				\ common-buffer; no dma-free here
         " disabled" encode-string  " status" property
         false  exit
      then
   then
   h-descript-len c@ get-hub-descript
   ?dup  if
      drop
      drop				\ common-buffer; no dma-free here
      " disabled" encode-string  " status" property
      false  exit
   else  stall-or-nak?  if
         drop				\ common-buffer; no dma-free here
         " disabled" encode-string  " status" property
         false  exit
      then
   then
   dup h-descript-#ports c@  to #ports
   dup read-power-bits
   h-descript-power-on c@ 2*  to power-on-time
   true
;

\ XXX hub status data -- 32 bits or so
\ port status data -- 32 bits or so

\ probe deeper if recurse? is not 0.  involves a dependency on main OBP.
\ this word works with max-recursion in the host adapter fcode, and with
\ onboard-usb-max-depth and onboard-usb-recurse? in SUNW,builtin-drivers.
: go-deeper?  ( -- recurse? )
   " onboard-usb-recurse?" 
   " SUNW,builtin-drivers" find-package  drop	\ must be present
   find-method  if
      execute 0<>
   else  true					\ default to go deeper
   then
;

: power-on  ( -- )
   /request dma-alloc  to request-blank		\ get memory
   /common-buffer dma-alloc  to common-buffer
   read-my-data go-deeper? and  if
      unpower-ports				\ magic
      probe-ports
   then
   common-buffer /common-buffer dma-free	\ free memory
   -1 to common-buffer
   request-blank /request dma-free
   -1 to request-blank
;

power-on
