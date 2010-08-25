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
id: @(#)probe.fth 1.18 02/12/11
purpose: 
copyright: Copyright 1998-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: assign-address  ( speed usb-addr -- hw-err? | stat 0 )
\   next-usb-address ?dup  if
      set-address-form >r		 ( R: pkt-addr )
      ( speed ) 1 max-packet 0 0 r@ /request 0 0 execute-control
      r> /request give-chunk
\   else  no-more-addresses
\   then
   d# 10 ms			\ allow assignment to take effect
				\ should need only 2 ms
;

: set-configuration  ( speed usb-addr config -- hw-err? | stat 0 )
   1 max-packet 2swap  0 0 2swap
		  ( speed dir max-pkt dat-adr dat-len usb-addr config )
   0 -rot		\ endpoint
   request-blank dup >r
   set-config-req over request-type w!
   swap over req-value le-w!
   /request  2swap   ( speed dir max-pkt dat-adr dat-len req-adr req-len )
   execute-control
   r> /request give-chunk
;

: proto-get-configuration  ( -- addr )
   1 0 max-packet 
   h# 100 get-chunk  dup h# 100 5a fill		\ data in buffer
   dup >r
   1
   request-blank
   get-config-req over request-type w!
   1 over req-len le-w!
   dup >r					( R: b-adr p-adr )
   /request
   0 2 execute-control
   ?dup 2drop
   r> /request give-chunk
   r>
;

\ XXX ugly stack, very ugly.  ditto for the other descrip getters
: get-dev-descrip  ( speed usb-adr -- dev-descrip-addr dcnt hw-err? | stat 0 )
   0 swap max-packet swap
   /dev-descriptor get-chunk
   dup >r swap
   /dev-descriptor swap
   /dev-descriptor get-dev-descript-form
   dup >r swap
   /request swap
   0 swap execute-control
   r> /request give-chunk
   ?dup
   r> /dev-descriptor
   2swap
   0=  if  0  then
;

: get-config-descrip  ( speed usb-adr n cnt
				-- config-n-descrip-addr cnt hw-err? | stat 0 )
   swap rot >r >r >r				( R: usb-addr n cnt )
   0 max-packet
   r@ get-chunk					( speed in max c-d-addr )
   r> r> r>				( speed in max c-d-addr cnt n u-addr )
   2over >r >r >r >r			( R: cnt c-addr u-addr n )
   dup get-config-descript-form
   r> over req-value c!		( speed in max c-addr cnt pak-adr )
   r> over >r >r		( R: cnt config-desc packet-addr usb-addr )
   /request 0 r>  execute-control
   r> /request give-chunk
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
   max-packet
   new-device
   ( max-packet ) encode-int " 0max-packet" property
   create-address ?create-speed
   " "  2swap set-args
   1 byte-load
   finish-device
;

: .usb  ( stat -- )
   usb-debug? 0=  if  drop  exit  then
   case  2 of  noop              endof		\ patchable
         6 of  cr ." usb-nak"    endof
         e of  cr ." usb-stall"  endof
      cr ." usb-unknown: " dup .
   endcase
;

: stall-or-nak?  ( stat -- stall-or-nak? )
   dup .usb
   dup 6 =  swap e =  or
;

: set-default-max-packet  ( speed -- )
   if  8 to max-packet		\ lo speed device
   else  d# 64 to max-packet	\ reg speed
   then
;

defer complete-probe  ( port speed -- )
' 2drop is complete-probe		\ for a good node already created

\ Start with a new device at usb 0, port, and known speed (low or normal).
\ no-retry? (non-zero) if really fatal or succeeded.  retry (zero) if want to
\ go back to reset-port
: probe-once  ( port speed -- no-retry? )
   ['] 2drop is complete-probe		\ default to good device node on each pass
   dup set-default-max-packet
\ XXX can this delay be removed?  200 ms already in reset-port
   d# 150 ms			\ wait for Microsoft devices to settle; may
				\ only be needed for hot-plugging devices
\ book says to get device descrip here for max packet, then reset device.
   " dev-descrip" diag-crtype
   dup 0 get-dev-descrip	( port speed dev-d-addr dcnt hw-err? | stat 0 )
   dup no-response-error =  if		\ wait for slow device; try again
      drop give-chunk
      over clean-port
      d# 2000 ms
      dup 0 get-dev-descrip	( port speed dev-d-addr dcnt hw-err? | stat 0 )
   then
   ?dup  if
      data-overrun-error <>  if		\ data-over is benign here
         give-chunk 2drop
         ['] won't-send-descriptor is complete-probe
         false exit			( retry )
      then
   else  stall-or-nak?  if
         give-chunk 2drop
         ['] won't-send-descriptor is complete-probe
         false exit			( retry )
      then
   then					( port speed dev-d-addr dcnt )
   over d-descript-maxpkt c@		\ get max-packet
   to max-packet
   give-chunk
   over clean-port
   " next-add" diag-crtype
   next-usb-address 2dup assign-address	( port speed usb-adr hw-err? | stat 0 )
   ?dup  if
      drop				\ XXX some hw-err; already printed
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
\ XXX book says some errors can occur here that can only be detected by
\ attempting to talk to the device.

   " get-config1" diag-crtype
   2dup get-config1-descrip
			( port spd usb-addr cnfg-addr cnt hw-err? | stat 0 )
   ?dup  if
      drop			\ XXX some hw-error; already printed
      give-chunk
      drop			\ XXX will use up usb-adrs
      2drop
      ['] won't-send-config is complete-probe
      false exit			( retry )
   else  stall-or-nak?  if
         give-chunk
         drop			\ XXX will use up usb-adrs
         2drop 
         ['] won't-send-config is complete-probe
         false exit			( retry )
      then
   then				( port spd usb-addr cnfg-addr cnt )
   over c-descript-config-id c@ >r		\ get config value
   give-chunk				( port spd usb-addr ) ( R: cnfg-id )
   " set-config" diag-crtype
   2dup r> set-configuration	\ config index 1, using bConfigurationValue
				( port spd usb-addr hw-err? | stat 0 )
   ?dup  if
      drop			\ XXX some hw-error; already printed
      drop 2drop
      ['] won't-take-config is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         drop 2drop
         ['] won't-take-config is complete-probe
         true exit			( no-retry )
      then
   then				( port spd usb-addr )
   " get-config1-descript" diag-crtype
   2dup get-config1-descrip	( port spd usb-adr cadr ccnt hw-err? | stat 0 )
   ?dup  if
      drop			\ XXX some hw-error; already printed
      give-chunk
      drop 2drop
      ['] won't-send-descriptor is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         give-chunk
         drop 2drop
         ['] won't-send-descriptor is complete-probe
         true exit			( no-retry )
      then
   then				( port spd usb-adr cadr ccnt )
   " get-dev-descrip" diag-crtype
   2over get-dev-descrip
		( port spd usb-adr cadr ccnt dadr dcnt hw-err? | stat 0 )
   ?dup  if
      drop			\ XXX some hw-error; already printed
      give-chunk give-chunk
      drop 2drop
      ['] won't-send-descriptor is complete-probe
      true exit				( no-retry )
   else  stall-or-nak?  if
         give-chunk give-chunk
         drop 2drop
         ['] won't-send-descriptor is complete-probe
         true exit			( no-retry )
      then
   then
   " descripts" diag-crtype
   ( port speed usb-adr config-desc ccnt dev-desc dcnt )
   3 pick 2 pick  combined-node?  if
      find-combined-fcode
   else
      find-device-fcode
   then
   >r >r
   give-chunk give-chunk
   r@	( port speed usb-adr fcode-adr ) ( R: f-len f-adr )
   -rot >r >r swap
   encode-unit  r> r>
   make-child
   r> r> dma-free		\ toss fcode
   " node made" diag-crtype
   true					( no-retry )
;

\ probe-self?  $find execute?  evaluate?  byte-load?  recurse?

\ interface hub call-parents could rely on the parent to add in the
\ speed, as they don't really have a speed.
