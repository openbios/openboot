\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: intrmap.fth
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
id: @(#)intrmap.fth 1.1 06/02/22
purpose: Erie interrupt mapping
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ devaliases we need to add in guest-pd to virtualize this:
\ pcie2x " /pci@7c0/pci@0/pci@8"
\ pci-b  " /pci@7c0"
\ ebus   " /ebus@800"
\ pci-a  " /pci@780"

\ data that need to come from the MD data to virtualize this:
\ #interrupt-cells: one entry
\ interrupt-map: one or more entires
\ interrupt-parent: one entry
\ interrrupt-map-mask: open or form from map entries?

\ Return true if system is P0. 
\ HACK: Only way to tell its a P0 is Fire msix-data-width property = 0x10
: is-p0? ( -- flag )
   false						( flag )
   " /pci@7c0" locate-device 0=  if			( phandle )
      " msix-data-width" rot get-package-property 0= if ( flag $val )
         decode-int h# 10 = nip nip or	        	( flag' )
      then
   then							( flag' )
;

: en+ ( xdr,len int -- xdr',len' )  encode-int encode+  ;

: apply-pci-interrupt-mapping  (  -- )
   " /pci@7c0/pci@0/pci@8" locate-device 0=  if
      push-device					( )
      " /pci@7c0" locate-device 0=  if			( phandle ) 
         >r						( ) ( r: phandle )
         1 encode-int " #interrupt-cells"   property

         \ HACK: break mask for P0 hardware
         is-p0? if
            h# fff000 encode-int 0 en+ 0 en+ 7 en+
         else
            h# fff900 encode-int 0 en+ 0 en+ 7 en+
         then
         " interrupt-map-mask" property

         \ my-space             m--address  int   iparent ino
         h# 41000 encode-int 0 en+ 0 en+ 1 en+ r@ en+ d# 0 en+ \ sas@2
         h# 40900 en+        0 en+ 0 en+ 2 en+ r@ en+ d# 1 en+ \ network@1,1
         h# 40800 en+        0 en+ 0 en+ 1 en+ r> en+ d# 2 en+ \ network@1,0
         " interrupt-map" property
      then						( ) ( r: )
      pop-device					( )
   then							( )
;

stand-init: Apply Erie pci interrupt mapping
   current-device >r
      apply-pci-interrupt-mapping
   r> push-device
;

headers
