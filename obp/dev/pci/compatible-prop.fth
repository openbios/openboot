\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: compatible-prop.fth
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
id: @(#)compatible-prop.fth 1.3 05/10/12
purpose: Shared code for constructing the compatible property 
copyright: Copyright 2005 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ The following is forming a list of names in most-specific to
\ least-specific order for the compatible property.
\
\      (1) pciVVVV,DDDD.SSSS.ssss.RR
\      (2) pciVVVV,DDDD.SSSS.ssss
\      (3) pciSSSS,ssss
\      (4) pciVVVV,DDDD.RR
\      (5) pciVVVV,DDDD
\      (6) pciclass,CCSSPP
\      (7) pciclass,CCSS
\
\ For PCI-Express, the strings will have the following format:
\ 
\      (1) pciexVVVV,DDDD.SSSS.ssss.RR
\      (2) pciexVVVV,DDDD.SSSS.ssss
\      (4) pciexVVVV,DDDD.RR
\      (5) pciexVVVV,DDDD
\      (6) pciexclass,CCSSPP
\      (7) pciexclass,CCSS
\
\ where:  VVVV is the Vendor ID             DDDD is the Device ID
\         SSSS is the Subsystem Vendor ID   ssss is the Subsystem ID
\         RR   is the Revision ID           CC   is the Base Class Code
\         SS   is the Sub-class Code        PP   is the Programming Interface

: $pci ( -- adr len )
   pci-express? if  " pciex"  else  " pci"  then
;

: $pciclass ( -- adr len )
   pci-express? if  " pciexclass,"  else  " pciclass,"  then
;

\ Create VVVV,DDDD.SSSS.ssss.RR entry string
: ascii-vdssr-id  ( ven-id dev-id subven-id sub-id rev-id -- adr len )
   <# u#s drop  ascii . hold u#s drop
   ascii . hold u#s drop ascii . hold
   u#s drop ascii , hold u#s
   $pci $hold u#>
;

\ Create VVVV,DDDD.SSSS.ssss entry string
: ascii-vdss-id  ( ven-id dev-id subven-id sub-id -- adr len )
   <# u#s drop ascii . hold
   u#s drop ascii . hold
   u#s drop ascii , hold
   u#s $pci $hold u#>
;

\ Create SSSS,ssss entry string
: ascii-subven-id   ( subven-id sub-id -- adr len )
   <# u#s drop ascii , hold
   u#s $pci $hold  u#>
;

\ Create VVVV,DDDD.RR entry string
: ascii-vendevrev-id  ( ven-id dev-id rev-id -- adr len )
   <# u#s drop ascii . hold
   u#s drop ascii , hold
   u#s $pci $hold u#>
;

\ Create VVVV,DDDD entry string
: ascii-vendev-id  ( ven-id dev-id -- adr len )
   <# u#s drop ascii , hold u#s $pci $hold u#>
;

\ Return CCSSPP entry string
: class-code-string1  ( -- adr len )
   class-code <# u# u# u# u# u# u# $pciclass $hold u#>
;

\ Return CCSS entry string
: class-code-string2  ( -- adr len )
   class-code 8 rshift <# u# u# u# u# $pciclass $hold u#>
;

\ Return VVVV,DDDD.SSSS.ssss entry string
: vdss-id-value  ( -- adr len )
   vid,did		\ vendor ID device ID
   svid,ssid		\ Subsystem vendor ID device ID
   ascii-vdss-id	( adr len )
;

\ Return VVVV,DDDD.SSSS.ssss.RR entry string
: vdssr-id-value  ( -- adr len )
   vid,did		\ vendor ID device ID
   svid,ssid		\ Subsystem vendor ID device ID
   rev-id 		\ revision ID 
   ascii-vdssr-id	( adr len )
;

\ Return SSSS,ssss entry string
\ If there is no subsystem device/vendor ID, return null ( 0 0 ) string.
: sub-vendev-id-value  ( -- adr len )
   svid,ssid		\ Subsystem vendor ID device ID
   2dup or if		\ any Subsystem Device/Vendor info?
      ascii-subven-id	( adr len )
   then			( adr len | 0 0 )
;

\ Return VVVV,DDDD.RR entry string
: vendevrev-id-value  ( -- adr len )
   vid,did		\ vendor ID device ID
   rev-id		\ revision ID
   ascii-vendevrev-id   ( adr len )
;

\ Return VVVV,DDDD entry string
: vendev-id-value  ( -- adr len )
   vid,did		\ vendor ID device ID
   ascii-vendev-id	( adr len )
;

\ Create the value of the compatible property.
\ The subsystem (SSSS) forms are included only if the subsystem ID is
\ non-zero. Also, for PCI Express, the SSSS,ssss entry is not included.

: encode-str+ ( prop1$ str@ -- )  encode-string encode+  ;

: compatible-property-value  ( -- adr len )
   0 0  encode-bytes
   svid,ssid or  if				\ Subsystem ID is non-zero
      vdssr-id-value      encode-str+   	\ VVVV,DDDD.SSSS.ssss.RR
      vdss-id-value       encode-str+		\ VVVV,DDDD.SSSS.ssss
      pci-express? 0=  if
         sub-vendev-id-value encode-str+	\ SSSS,ssss
      then
   then
   vendevrev-id-value  encode-str+		\ VVVV,DDDD.RR
   vendev-id-value     encode-str+		\ VVVV,DDDD
   class-code-string1  encode-str+		\ CCSSPP
   class-code-string2  encode-str+		\ CCSS
;

: make-compatible-property  ( -- )
   compatible-property-value  " compatible" property
;
