\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pci.fth
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
id: @(#)pci.fth 1.14 05/10/12
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

fload ${BP}/dev/pci/config-access.fth

fload ${BP}/dev/pci/compatible.fth
make-compatible-property

external

: map-in	" map-in" $call-parent ;
: map-out	" map-out" $call-parent ;

headerless

\ Southbridge IDE controller's BARs are read only 
\ until the device is put into native mode
[ifdef] M1575-workarounds
         00 h# 43 my-b! 	\ unlock class code 
      h# ff    09 my-b! 	\ switch to native mode
[then]


\ These two are just in case some PCI IDE card actually uses
\ memory mapped regs rather than I/O
2		instance value reg-enable	\ mem or I/O enable bit
h# 0200.0000	instance value reg-type

: bar>offset ( n -- offset ) h# 4 * h# 10 +  ;

: get-bar-n ( bar -- present? )
  bar>offset					( offset )
  my-l@						( phys )
  ?dup if					( phys )
    1 and if  h# 1  else  h# 2  then		( type )
    is reg-enable true				( flag )
  else						( -- )
    false					( false )
  then						( -- flag )
;

: bar>physhi ( bar -- phys-hi )
  bar>offset					( offset )
  reg-enable d# 24 <<				( offset type )
  my-space or or				( physhi )
;

: en+ ( xdr,len int -- xdr',len' )	encode-int encode+  ;
: 0+  ( xdr,len 0 -- xdr',len' )	0 en+  ;

\ We need the PCI-prober to re-write the bars for ide so we
\ make the reg property larger than the legacy BARs advertise.
\ This causes reallocation.
: reg+  ( xdr,len bar len -- xdr,len ) 
[ifdef] M1575-workarounds
   h# 20 + 	
[then]
   >r bar>physhi en+ 0+ 0+ 0+ r> en+
;

: create-reg-property ( -- )
  my-space encode-int 0+ 0+ 0+ 0+		( xdr,len )
  -1 is secondary?				( xdr,len )
  4 0 do					( xdr,len )
    i get-bar-n if				( xdr,len )
      i h# 8 reg+				( xdr,len )
      i 1+ dup get-bar-n drop h# 4 reg+		( xdr,len )
      secondary? 1+ is secondary?		( xdr,len )
    then					( xdr,len )
  2 +loop					( xdr,len )
  9 my-b@ h# 80 and if
    secondary? if 4 else 2 then			( xdr,len DMA )
    dup get-bar-n if				( xdr,len DMA )
      h# 10 reg+				( xdr,len )
    else					( xdr,len )
      drop					( xdr,len )
    then					( xdr,len )
  then						( xdr,len )
  " reg" property				( -- )
;

create-reg-property

: map-bar-n ( bar -- )
  dup get-bar-n	if				( bar )
    dup bar>physhi my-address rot h# 8  map-in	( bar va )
  else						( bar va )
    0						( bar va )
  then						( bar va )
  reg-array rot na+ !				( -- )
;

: enable-ide ( on|off -- )
  4 my-w@ reg-enable rot			( on? data bit )
  if or else not and then			( data' )
  4 my-w!					( -- )
;

: map-regs ( -- )
  reg-array @ if  exit  then
  4 0 do  i map-bar-n  loop  1 enable-ide
;

: ?unmap ( base index size -- )
  -rot na+ dup >r @ 0 r> !	( size va )
  ?dup if			( size va )
    swap map-out		( -- )
  else				( size )
    drop			( -- )
  then				( -- )
;

: unmap-regs ( -- )
  4 0  do
    reg-array i 2dup		( base index base index )
    h# 8 ?unmap			( base index )
    1+ h# 4 ?unmap		( -- )
  2 +loop
  reg-array @ if  exit  then
  0 enable-ide
;

: .cmd-irq ( -- flag? )
  interface if h# 10 h# 57 else h# 4 h# 50 then
  my-b@ and
;

: setup-device ( vendor device -- )
  over h# 1095 = over h# 646  = and if
    \ Broken CMD controller requires devices on the secondary
    \ channel or it generates interrupts because the IRQ floats
    \ This interface is disabled via a jumper but the BARs aren't
    \ so we need to initialise them BUT not use them because they
    \ cause BUS errors.
    h# 51 my-b@ h# 8 and is secondary?
    h# 30 h# 71 my-b!		\ Disable interrupts
    ['] .cmd-irq is ide-irq?
  then
  2drop
;

0 my-l@ lwsplit setup-device
