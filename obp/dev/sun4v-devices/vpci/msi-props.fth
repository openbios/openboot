\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: msi-props.fth
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
id: @(#)msi-props.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ The following method takes a property name and returns the property 
\ value (which could be an integer, integer array, or something else) 
\ and a flag which is true if the property was found and false otherwise. 
\ Before 4.x integration, this can be dropped in favor of the method 
\ 'required-prop', but for now we'll use this so we don't break anybody. 
: get-msi-prop ( name$ -- ... found? )
   -1 my-node pdget-prop dup if
      pddecode-prop true
   then
;

: msi-integer-property ( name$ -- )
   2dup get-msi-prop if
      -rot integer-property
   else
      2drop
   then
;

: decode64 ( prop,len -- prop,len' x )
   decode-int drop decode-int
;

\ Decoded MSI address ranges
" msi-address-ranges" get-msi-prop if
   decode64 >r		\ pci-mem32-addr.hi
   decode64 >r		\ pci-mem32-addr.lo
   decode64 >r		\ pci-mem32-size
   decode64 >r		\ pci-mem64-addr.hi
   decode64 >r		\ pci-mem64-addr.lo
   decode64 >r		\ pci-mem64-size
   2drop r> r> r> r> r> r>
   encode-int rot en+ rot en+ rot en+ rot en+ rot en+
   " msi-address-ranges" property   
then

\ Number of MSI's allocated to this guest
" #msi" msi-integer-property

\ Mask showing which MSI data bits are used to select the msi#
" msi-data-mask" msi-integer-property

\ List of available MSIs (base and number)
" msi-ranges" get-msi-prop if
   decode64 >r decode64 >r
   2drop r> r> encode-int rot en+ " msi-ranges" property
then

\ Maximum number of EQ records allowed in each MSI EQ
" msi-eq-size" msi-integer-property

\ Number of significant bits in the MSI-X data
" msix-data-width" msi-integer-property

\ Number of MSI EQs
" #msi-eqs" msi-integer-property

\ List of MSI EQ to DEVINO numbers
" msi-eq-to-devino" get-msi-prop if
   decode64 >r
   decode64 >r
   decode64 >r
   2drop r> r> r>
   encode-int rot en+ rot en+
   " msi-eq-to-devino" property
then
