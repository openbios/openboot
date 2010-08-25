\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: southroot.fth
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
id: @(#)southroot.fth 1.3 03/10/01
purpose: 
copyright: Copyright 1998-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ These two actually must be set via set-root-hub
2 value #root-ports		\ read from hc-roota; global
ff value power-on-time		\ in ms -- NOT 2 ms chunks; from hc-roota; global

\ enchilada:
\ ndp = 2  nps = 1 psm = 0 dt = 0 ocpm = 0 nocp = 0 potpgt = 2
\ dr = 0 ppcm = 0
\ ports are always powered.  over-current reported for all ports.
\ must wait 4 ms after port is powered to access it.
\ all devices are removable.
\ no port power control.
\ must run set-root-hub before running get-root-info for southbridge
: get-root-info  ( -- )
   chip-base hc-roota rl@
   dup h# ff and to #root-ports
   dup d# 24 rshift  2*  h# ff and  to power-on-time
   drop					\ XXX more later
;

\ some registers must be written for southbridge on enchilada
: set-root-hub  ( -- )			\ root hub descriptor regs
   h# 200.0202 chip-base hc-roota rl!
   0 chip-base hc-rootb rl!		\ 2 removable device ports, no per-port power
;

\ root-status and port-status writeable during operational state

\ OS hc-root-status = 0

\ Nothing to do for cmd root hub, RIO root hub, or southbridge root hub
: set-root-status  ( -- )		\ root hub status reg
;

: unpower-ports  ( -- )			\ magic for power on
   1 chip-base hc-root-status rl!
;

: power-ports  ( -- )			\ magic for power on
   h# 1.0000 chip-base hc-root-status rl!
;

\ port addressing is nominally 1 based.
: port-status  ( port# -- addr )
   chip-base hc-port-status  swap 1- 4 *  +
;

: bits>port  ( port# bits -- )  swap port-status rl!  ;

: disable-port  ( port# -- )  1 bits>port  ;

: enable-port  ( port# -- )  2 bits>port  ;

: 1reset-port  ( port# -- )
   h# 10 bits>port
;

: unpower-port  ( port# -- )  h# 200 bits>port  ;

: clear-connect-change  ( port# -- )  h# 1.0000 bits>port  ;

: clear-port-enable  ( port# -- )  h# 2.0000 bits>port  ;

: clear-port-suspend  ( port# -- )  h# 4.0000 bits>port  ;

: clear-port-reset  ( port# -- )  h# 10.0000 bits>port  ;


: port>bits  ( port# mask -- bits )  swap port-status rl@  and  ;

: port-connected?  ( port# -- connected? )  1 port>bits  ;

: port-powered?  ( port# -- power-on? )  h# 100 port>bits  ;

: port-low-speed?  ( port# -- low-speed? )
   h# 200 port>bits  if  1  else  0  then
;

: port-reset-done?  ( port# -- reset-done? )  h# 10.0000 port>bits  ;


0 value power-time			\ can be global; only used at probe time.

: power-timed-out?  ( -- timed-out? )
   get-msecs power-time u>
;

\ southbridge: all ports on all the time
: power-port  ( port# -- )
   get-msecs power-on-time +  is power-time
   begin			\ loop until port-powered
      1 ms
      dup port-powered?
      power-timed-out? or	\ better not happen -- bad chip if it does.
   until
   drop
   d# 200 ms			\ delay for balky devices -- could delay
				\ once for all since southbridge gang powers
;


0 value reset-time			\ can be global; doesn't normally change.

: reset-timed-out?  ( -- timed-out? )
   get-msecs reset-time u>
;

\ should take only 10 ms; book says it could take 50 ms or more
: wait-for-reset  ( port -- )
   get-msecs  d# 100 +  is reset-time
   begin
      1 ms
      dup port-reset-done?
      reset-timed-out? or
   until
   drop
;

\ XXX do multiple times to get 50 ms reset from host.  May not be needed from a port on
\ the host, but I couldn't find a reference to how long the reset lasts on southbridge;
\ this assumes 10 ms.  Nominally 10 ms is enough, but usb1.1 7.1.7.3 and
\ usb2.0 7.1.7.5 says 50 ms from host.
: reset-port  ( port# -- )
   5 0 do
      dup 1reset-port
      dup wait-for-reset
      dup clear-port-reset
   loop
   drop
   d# 200 ms				\ balky device reset delay;
					\ should not have to wait this long
;
