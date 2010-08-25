\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: phy.fth
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
id: @(#)phy.fth 1.1 06/02/16
purpose: Intel Ophir/82571 transceiver routines
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0 value  an-debug?

\ Put PHY in loopback mode temporarily to bring the link down
: force-link-down ( -- )
   phy-cr@  phycr.loopback or  phy-cr!
   d# 1000 ms
   phy-cr@  phycr.loopback invert and phy-cr!
;

: phy-reset-complete? ( -- flag )   phy-cr@ phycr.reset and 0= ;

: wait-phy-reset ( -- flag )   
   d# 700 ['] phy-reset-complete?  wait-status 
;

: (reset-transceiver) ( -- ok? )
   phy-cr@ phycr.reset or phy-cr!   
   wait-phy-reset
;

: reset-transceiver ( -- ok? )
   d# 15000 get-msecs +  false
   begin
      over timed-out? 0=  over 0=  and
   while
      (reset-transceiver)  if  drop true  then
   repeat  nip
   dup 0=  if  ." Failed to reset transceiver!" cr  exit  then
   phy-cr@ phycr.speed-100 invert and  phycr.duplex invert and phy-cr!
;

: disable-auto-nego ( -- )
   an-debug?  if ." Disabling Autonegotiation" cr then 
   phy-cr@  phycr.an-enable invert and phy-cr!
;

: enable-auto-nego ( -- )
   an-debug?  if  ." Enabling Autonegotiation" cr  then 
   phy-cr@ phycr.an-enable phycr.an-restart or  or phy-cr!
;

: an-link-speed&mode ( -- speed duplex-mode )

   phy-sr@  physr.ext-status and  if
      phy-1000-sr@  h# c00 and d# 10 rshift
      phy-1000-cr@  h# 300 and d#  8 rshift and     ( 1000bt-common-cap )
      d# 10 lshift
      dup gsr.lp-1000fdx  and  if  drop 1000Mbps full-duplex  exit  then
          gsr.lp-1000hdx  and  if       1000Mbps half-duplex  exit  then
   then

   phy-anlpar@ phy-anar@ and           ( an-common )
   dup anlpar.100fdx and  if  drop 100Mbps full-duplex  exit  then
   dup anlpar.100hdx and  if  drop 100Mbps half-duplex  exit  then
   dup anlpar.10fdx  and  if  drop 10Mbps  full-duplex  exit  then
   dup anlpar.10hdx  and  if  drop 10Mbps  half-duplex  exit  then
;

: phy-abilities ( -- abilities )
    phy-sr@ d# 11 rshift h# f and
    gmii-phy? if  phy-esr@ d# 12 rshift h# 3 and  else  0  then d# 4 lshift or
;

\ Construct bit-mask abilities based on speed, duplex mode settings
\       0000.0001     10Mbps, Half Duplex
\       0000.0010     10Mbps, Full Duplex
\       0000.0100    100Mbps, Half Duplex
\       0000.1000    100Mbps, Full Duplex
\       0001.0000   1000Mbps, Half Duplex
\       0010.0000   1000Mbps, Full Duplex
: construct-abilities ( speed duplex-mode -- abilities )
   phy-abilities
   swap case
      half-duplex of   h# 15  endof     \ Mask FDX abilities
      full-duplex of   h# 2a  endof     \ Mask HDX abilities
      auto-duplex of   h# 3f  endof
   endcase and
   swap case
      10Mbps      of   h# 3   endof
      100Mbps     of   h# c   endof
      1000Mbps    of   h# 30  endof
      auto-speed  of   h# 3f  endof
   endcase and
;

: publish-capabilities ( -- )
   user-speed user-duplex construct-abilities                   ( abilities )
   dup  h# f and  d# 5 lshift anar.selector-field or phy-anar!  ( abilities )
   gmii-phy?  if                                                ( abilities )
      h# 30 and  d# 4 lshift                                    ( 1000-cap )
      user-link-clock auto-link-clock <>  if
         gcr.ms-cfg-enable or
         user-link-clock master-link-clock =  if
            gcr.ms-cfg-value or
         then
      then
      phy-1000-cr!
   else                                                         ( abilities )
      drop                                                      ( )
   then                                                         ( )
;

: match-capabilities ( -- ok? )
   phy-sr@  physr.ext-status and  if
      phy-1000-sr@ h# c00 and  d# 10 rshift
      phy-1000-cr@ h# 300 and  d#  8 rshift
      and 0<>
   else
      0
   then
   phy-anlpar@ phy-anar@ and 0<> or
;

\ Autonegotiation may take as much as 5 seconds with 10/100 BaseT PHYs 
: wait-autoneg-complete ( -- complete? )
   d# 5000 get-msecs +  false
   begin
      over timed-out? 0=
      over 0= and
   while
      d# 20 ms
      phy-sr@  physr.an-complete and  if
         drop true
      then
   repeat nip
;

: phy-link-up? ( -- up? )  
   phy-sr@  drop
   phy-sr@  physr.link-up and 
;

: link-up? ( -- flag )  phy-link-up? ;

: wait-link-up? ( -- up? )
   wait-phy-reset drop
   d# 2000 ['] phy-link-up? wait-status
;

: (autonegotiate) ( -- link-up? )

   \ Advertise my capabilities & start auto negotiation
   publish-capabilities
   enable-auto-nego

   \ Wait for auto negotiation to complete
   wait-autoneg-complete
   0=  if
      ." Timed out waiting for Autonegotation to complete" cr
      false exit
   then

   \ Check if autonegotation completed by parallel detection,
   \ and if so, whether there are any parallel detect (multiple
   \ link fault) errors
   phy-aner@  dup aner.lp-an-able and 0=  swap aner.mlf and  and if
      ." Multiple link faults seen during Autonegotiation" cr
      false exit
   then

   \ Check for common capabilities
   match-capabilities 0=  if
      ." System and network incompatible for communicating" cr
      false exit
   then

   \ Valid Link established?
   phy-link-up?  
;

: do-autonegotiation ( -- link-up? )
   (autonegotiate)  if
      an-link-speed&mode  set-chosen-speed&duplex
      true
   else
      ." Check cable and try again" cr
      false
   then
;

: check-phy-capability ( -- )
   user-speed user-duplex 2dup construct-abilities 0=  if 
      ." Not capable of " .link-speed,duplex 
      -1 throw
   else
      2drop
   then
;

\ Set/Force link speed and mode, and check link status
\ For 1Gbps, we manually configure local PHY as SLAVE
: speed&mode-possible? ( speed duplex-mode -- link-up? )
   over 1000Mbps =  if
      gcr.ms-cfg-enable
      user-link-clock master-link-clock =  if
         gcr.ms-cfg-value or
      then
      phy-1000-cr!
   then
   phy-cr@  b# 0010.0001.0100.0000 invert and  \ Mask speed & duplex bits
   swap  full-duplex =  if  phycr.duplex or then
   swap  case
      10Mbps    of   phycr.speed-10    endof
      100Mbps   of   phycr.speed-100   endof
      1000Mbps  of   phycr.speed-1000  endof
   endcase  or
   phy-cr!
   wait-link-up?
;

: set-speed&mode ( -- link-up? )
   disable-auto-nego
   force-link-down
   user-speed user-duplex
   2dup speed&mode-possible?  if  set-chosen-speed&duplex true exit  then
   over 1000Mbps =  if
      ." Cannot bringup link using non-autonegotation." cr
      ." Force link partner to " .link-speed,duplex ." as link-clock "
      user-link-clock master-link-clock =  if
         ." slave"
      else
         ." master"
      then  
      cr -1 throw
   then
   2drop false
;

: use-autonegotiation? ( -- flag )
   user-speed auto-speed =  user-duplex auto-duplex =  or  if
      true exit
   then
   user-speed 1000Mbps =  if
      user-link-clock auto-link-clock =
   else
      false
   then
;

: show-link-status ( -- )
   phy-link-up?  if
      chosen-speed chosen-duplex  .link-speed,duplex  ."  Link up"
   else
      ." Link Down"
   then cr
;

: setup-transceiver ( -- ok? )
   reset-transceiver drop
   \   disable-link-events		\ Should be turned off by reset but...
   check-phy-capability
   use-autonegotiation? if  do-autonegotiation  else  set-speed&mode  then
   show-link-status
;
