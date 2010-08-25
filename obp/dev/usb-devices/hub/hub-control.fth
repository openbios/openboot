\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hub-control.fth
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
id: @(#)hub-control.fth 1.11 03/06/10
purpose: 
copyright: Copyright 1997-2001, 2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ XXX Code presumes these are needed only at power-on, probe time, and that
\ they can do dma-alloc, free, etc.

-1 value #ports				\ read from descriptor; global

-1 value power-on-time			\ in ms -- NOT 2 ms chunks;
					\ from descriptor; global

\ XXX power-switch indicator -- gang, individual port, or no power switch

\ XXX port power switch not affected by gang indicators.  need setportfeature
\ if not ganged.  from descriptor

\ XXX N.B. standard hub:  the status change endpoint is interrupt in, poll
\ interval ff.

\ XXX need to fiddle c-port-enable?
: disable-port  ( port# -- )
   port-enable swap clear-port-feature	( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;

\ XXX need to fiddle c-port-enable?
\ Illegal command. don't use this -- just reset the port.  reset includes enable.
\ : enable-port  ( port# -- )
\    port-enable swap set-port-feature
\ XXX error recovery instead of this:
\    ?dup 2drop
\ ;

\ Nominally 10 ms for non-root ports. usb1.1 7.1.7.3?
: 1reset-port  ( port# -- )		\ Also enables port atomically
   port-reset swap set-port-feature
\ XXX error recovery instead of this:
   ?dup 2drop
;

: port-reset-done?  ( port# -- done? )
   get-port-status			( addr hw-err? | addr stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop				( addr )
   2 + le-w@ h# 10 and
;

: clear-port-reset  ( port# -- )
   c-port-reset swap clear-port-feature  ( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;

0 value reset-time			\ XXX per instance?

\ XXX problem around 0
: reset-timed-out?  ( -- timed-out? )
   get-msecs reset-time u>
;

\ should take only 10 ms; book says it could take 50 ms or more
: wait-for-reset  ( port -- )
   get-msecs d# 100 +  is reset-time
   begin
      1 ms
      dup port-reset-done?
      reset-timed-out? or
   until
   drop
;

\ do multiple times to get 50 ms reset.  May not be needed.
: reset-port  ( port# -- )
   5 0 do
      dup clear-port-reset
      dup 1reset-port
      dup wait-for-reset
   loop
   drop
   d# 200 ms			\ XXX balky device reset;
				\ shouldn't have to wait this long
				\ nominally 10 ms, usb1.1 7.1.7.3
;

\ If ganged, the port goes off when all ports have been unpowered
\ (AND function).
\ If already off, unpowering again should be ok.
: unpower-port  ( port# -- )
   port-power swap clear-port-feature  ( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;

\ in case the ports are gang-powered but individually controlled
: unpower-ports  ( -- )
   #ports 1+  1 do
      i unpower-port
   loop
;

: port-connected?  ( port# -- connected? )
   get-port-status			( addr hw-err? | addr stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop				( addr )
   le-l@ 1 and
;

: port-powered?  ( port# -- power-on? )
   get-port-status			( addr hw-err? | addr stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop				( addr )
   le-l@ h# 100 and
;

\ Turn on any port to turn all on with ganged power (OR function).
\ Multiple turn-on commands should work.  So the ganged power aspect is
\ really relevant for unpower-port.
\ Device could take 200 ms beyond the hub port power time before it is
\ ready to reset

0 value power-time			\ can be global; used only at probe time.

: power-timed-out?  ( -- timed-out? )
   get-msecs power-time u>
;

: power-port  ( port# -- )
   port-power over set-port-feature
\ XXX error recovery instead of this:
   ?dup 2drop
   get-msecs power-on-time +  is power-time
   begin
      1 ms
      dup port-powered?
      power-timed-out? or
   until
   drop
   d# 200 ms			\ more delay for balky devices
;

: suspend-port  ( port# -- )
   port-suspend swap set-port-feature
\ XXX error recovery instead of this:
   ?dup 2drop
;

: resume-port  ( port# -- )
   port-suspend swap clear-port-feature
\ XXX error recovery instead of this:
   ?dup 2drop
;

: port-low-speed?  ( port# -- low-speed? )
   get-port-status			( addr hw-err? | addr stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop				( addr )
   le-l@ h# 200 and  if  1  else  0  then
;

: clear-connect-change  ( port# -- )
   c-port-connection swap clear-port-feature  ( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;

: clear-port-enable  ( port# -- )
   c-port-enable swap clear-port-feature  ( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;

: clear-port-suspend  ( port# -- )
   c-port-suspend swap clear-port-feature  ( hw-err? | stat 0 )
\ XXX error recovery instead of this:
   ?dup 2drop
;
