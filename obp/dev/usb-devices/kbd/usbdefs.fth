\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usbdefs.fth
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
\ id: @(#)usbdefs.fth 1.9 00/06/01
\ purpose: 
\ copyright: Copyright 1997-2000 Sun Microsystems, Inc.  All Rights Reserved


\ This file holds usb-specific definitions.


\ headers			\ XXX for debugging
external
hex

\ debug stuff from here - take out later
\ ************************************

: dobigoffset
  case
     30 of  0 endof
     31 of  10 endof
     32 of  20 endof
     33 of  30 endof
     34 of  40 endof
     35 of  50 endof
     36 of  70 endof
     37 of  90 endof
     38 of  b0 endof
     39 of  d0 endof
  endcase
;
: dolitloffset
  case
     30 of  0 endof
     31 of  1 endof
     32 of  2 endof
     33 of  3 endof
     34 of  4 endof
     35 of  5 endof
     36 of  6 endof
     37 of  7 endof
     38 of  8 endof
     39 of  9 endof
  endcase
;
\ ************************************
\ debug stuff to here - take out later


\ 1 constant GET-REPORT
\ 2 constant GET-IDLE
\ 3 constant GET-PROTOCOL
\ 4 - 8 are reserved, according to the USB HID doc
\ 9 constant SET-REPORT
\ a constant SET-IDLE
\ b constant SET-PROTOCOL

\ 0 constant BootProtocol
\ 1 constant ReportProtocol

\ Class Descriptor Types
\ 21 constant HID-Descriptor-Type
\ 22 constant REPORT-Descriptor-Type
\ 23 constant PHYSICAL-Descriptor-Type

\ 81 constant ReqType-HID-Cl-Descr


\ 6 constant GET-DESCRIPTOR

\ 1 constant GET-CLASS-DESCR


\ These are global.
defer turn-me-off  ' noop is turn-me-off
defer toggle-mon   ' noop is toggle-mon


0     constant reglkey
h# ff constant spclkey

0 instance value unstall-cnt

instance variable our-ha-token

0 instance value set-prtcl-buff^v
0 instance value get-descr-buff^v
0 instance value hid-descr-buff^v
0 instance value std-pkt-buff^v

\ The following struct is designed to keep track of the down keys - up to
\ 6 per report, plus related information.  The code is not currently
\ doing anything with the modifier byte or the reserved byte, but
\ including those makes it very convenient because the key# information
\ coming back from the USB report fits directly into the struct format.
\ The #keys-down and #regl-keys-dn bytes are not filled in by the USB
\ boot report but instead are calculated sometime after receiving the
\ USB report.
\ Note: fields >kbd-in-byte7, >kbd-in-byte8, and >kbd-in-byte9 are used
\       to potentially hold the shift, cntrl and altgraph, which are
\       actually reported as status bits in the >kbd-in-modkeys byte.
struct
   1  field >kbd-in-modkeys   \ bmRequestType
   1  field >kbd-in-reserved  \ bmRequestType
   1  field >kbd-in-byte1     \ bmRequestType
   1  field >kbd-in-byte2     \ bmRequestType
   1  field >kbd-in-byte3     \ bmRequestType
   1  field >kbd-in-byte4     \ bmRequestType
   1  field >kbd-in-byte5     \ bmRequestType
   1  field >kbd-in-byte6     \ bmRequestType
   1  field >kbd-in-byte7     \ bmRequestType
   1  field >kbd-in-byte8     \ bmRequestType
   1  field >kbd-in-byte9     \ bmRequestType
   1  field >#keys-down
   1  field >#regl-keys-dn    \ Can determine #spcl keys dn by subtracting
                              \ #regl-keys-dn from #keys-down.
constant /key-info-buff

0 instance value keybuff-curr^v

/key-info-buff buffer: keybuff-prev

0 value curr-byte1-bfaddr
0 value curr-#ksdn-bfaddr
0 value prev-byte1-bfaddr
  \ These offsets are used frequently enough to have global variables
  \ that hold the offset to the indicated locations in the key buffers.


\ Various keyboard flags;
-1      instance value  shiftflag       \ True if the shift key is down
-1      instance value  ctrlflag        \ True if the ctrl key is down
-1      instance value  altgflag        \ True if the alt graph key is down
-1      instance value  powerflag       \ True if the power key is down
-1      instance value  monflag         \ True if the monitor key is down
-1      instance value  stopflag        \ True if the stop (L1) key is down
\ Following indicate special flags for "previous" report;
-1      instance value  pr-shiftflag    \ True if the shift key is down
-1      instance value  pr-ctrlflag     \ True if the ctrl key is down
-1      instance value  pr-altgflag     \ True if the alt graph key is down
-1      instance value  pr-powerflag    \ True if the power key is down
-1      instance value  pr-monflag      \ True if the monitor key is down
-1      instance value  pr-stopflag     \ True if the stop (L1) key is down
 
0       instance value  key-repeat-time \ Time of next repeat
\ 0       instance value  key-click
nokey   instance value  curr-repeat-key
        \ curr-repeat-key will hold the converted keyvalue which represents
        \ the currently repeating key.
 

\ Following will be set if several special keys have been entered
\ but the control key was given the highest priority.  Without this
\ flag we end up applying the control offset if the control key is
\ down - even if shift (a higher priority key) is down.
0 instance value ctrl-in-effect
