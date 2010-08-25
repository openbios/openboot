\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nodes.fth
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
id: @(#)nodes.fth 1.15 03/05/12
purpose: 
copyright: Copyright 1998-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

: find-fcode  ( adr1 len1 -- adr2 len2 true | false )
   " sunw,find-fcode" get-inherited-property drop
   decode-int nip nip
   execute
;

: find-interface-fcode  ( -- addr len )  " interface"  find-fcode drop  ;

: disabled-prop  ( -- )  " disabled" encode-string " status" property  ;

: create-reg  ( -- )  my-space  encode-int  " reg" property  ;

: ?create-speed  ( lo-speed? -- )  if  0 0  " low-speed" property  then  ;

: create-config  ( config -- )  encode-int  " configuration#" property  ;

: create-interface#  ( i# -- )  encode-int  " interface#" property  ;

: my-speed  ( -- lo-speed? )
   " low-speed" get-my-property  if
      false
   else  2drop true
   then
;

: my-usb-adr  ( -- usb-address )		\ must be there
   " assigned-address" get-my-property drop
   decode-int nip nip
;

: my-0max-packet  ( -- )			\ must be there
   " 0max-packet" get-my-property drop
   decode-int nip nip
   to 0max-packet
;

\ i# is from the interface descriptor.  This is to be more tolerant of
\ (non-USB compliant) devices that don't start the descriptors at 0.
: create-interface  ( speed i# -- )
   " device interface " diag-crtype
   diagnostic-mode?  if  dup .  then	\ XXX debug
   100 dma-alloc >r			\ to hold unit address string
   tuck
   1 swap encode-unit			\ always config 1
   r@ swap dup >r  move			( i# speed ) ( R: uadr ucnt )
   >r >r find-interface-fcode over r> r>
   new-device
   ?create-speed	\ publish low-speed for child interface node
   create-interface#
   " "  r> r@ swap  set-args	\ XXX can we use the u#s area?
   1 byte-load
   finish-device
   dma-free			\ dump fcode
   r> 100 dma-free		\ dump unit address
   " device interface done" diag-crtype		\ XXX debug
;


\ publish low-speed in child interface nodes.  otherwise get-inherited-property
\ could pick up some low-speed ancestor.  not a problem for usb-adr.
: make-interfaces  ( -- )
   " device get-ints" diag-crtype	\ XXX debug
   my-speed my-usb-adr
   get-int-descriptors
   ?dup  if			\ XXX data-over benign here?
      drop
      dma-free
      disabled-prop		\ XXX not quite.  For the device; no interfaces
      exit
   else  stall-or-nak?  if
         dma-free
         disabled-prop		\ XXX not quite.  For the device; no interfaces
         exit
      then
   then				( int-adr icnt )
   2dup >r >r
   begin			( iadr' icnt' )
      over i-descript-interface-id c@
      my-speed swap create-interface
      no-more-interfaces?
   until
   2drop
   r> r> dma-free
;

: finish-node  ( config-desc dev-desc -- )
   create-reg
   over c-descript-config-id c@
   create-config		\ use bconfigvalue
   dup create-device-name
   create-device-compat
   make-interfaces
;

: create-usb-device  ( -- )
   my-0max-packet
   my-speed my-usb-adr get-dev-descrip	( d-adr dcnt hw-err? | stat 0 )
   ?dup  if
      data-overrun-error <>  if		\ data-over benign here
         dma-free
         device-name
         disabled-prop			\ XXX not really
         exit
      then
   else  stall-or-nak?  if
         dma-free
         device-name
         disabled-prop			\ XXX not really
         exit
      then
   then
   over d-descript-maxpkt c@  to 0max-packet
   dma-free
\ 0max-packet needed for interfaces to inherit:
   0max-packet encode-int  " 0max-packet" property
   my-speed my-usb-adr
   2dup get-config1-descrip
			( spd uadr cnfg1-adr ccnt hw-err? | stat 0 )
   ?dup  if					\ hw-err; already printed
      drop
      dma-free
      device-name
      disabled-prop			\ XXX not quite; hub still enables
      2drop
      exit
   else  stall-or-nak?  if
         dma-free
         device-name
         disabled-prop			\ XXX not quite; hub still enables
         2drop
         exit
      then
   then
   2swap get-dev-descrip
			( cnfg-adr ccnt dev-adr dcnt hw-err? | stat 0 )
   ?dup  if					\ hw-err; already printed
      drop
      dma-free dma-free
      device-name
      disabled-prop			\ XXX not quite; hub still enables
      exit
   else  stall-or-nak?  if
         dma-free dma-free
         device-name
         disabled-prop			\ XXX not quite; hub still enables
         exit
      then
   then				( cnfg-adr ccnt dev-adr dcnt )
   2dup >r >r  2over >r >r
   drop nip
   finish-node
   r> r> r> r> dma-free dma-free
;

create-usb-device
