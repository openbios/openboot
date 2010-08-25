\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hotplugdetect.fth
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
id: @(#)hotplugdetect.fth 1.1 06/04/05 15:50:27
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Hot plug capability detection code to be used 
\ in pci bridge code.

\ Called only if pcie capability is present. Called with the 
\ offset of pcie capability register. Check pcie capability 
\ for downstream port type, slot implemented and slot capability 
\ for hotplug capability of the slot. 
: pcie-hotplug-capable? ( offs -- flag )
   >r r@ 2+ my-w@				( pcie-cap ) ( R: offs )
   dup 4 >>  h# f and 6 = swap	    		( downstream? pcie-cap ) 
   h# 100 and and if				(  ) ( R: offs )                
      \ downstream port and slot implemented.
      \ check for hotplug capable bit in
      \ slot capability register
      r> d# 20 + my-l@ h# 40 and 0<>		( flag )
   else 
      \ upstream port or slot not implemented
      r> drop false				( false )
   then
;

\ Called only if pcie capability is present. Called with 
\ the  offset  of pcie capability register. Check  pcie 
\ capability for downstream port type and slot implemented.
: pcie-slot-implemented? ( offs -- flag )
   2+ my-w@					( pcie-cap )
   dup 4 >>  h# f and 6 = swap			( downstream? pcie-cap ) 
   h# 100 and and                 		( flag )
;

\ Identifying a "hotplug-capable" bridge.  If capability 
\ ptr is implemented then we search for the existence of
\ SHPC capability. If SHPC capability is present then we 
\ say that the bridge supports hotplug. If no SHPC, then 
\ if PCIE capability is present then we check the slot
\ capability for the presence of hotplug capability. If 
\ present then it is hotplug capable.
: hotplug-capability? ( -- flag )
   shpc-capability-regs if true exit then
   pcie-capability-regs ?dup if			( offs )
      pcie-hotplug-capable?			( flag )
   else
      false					( false )
   then
;

\ Since there is no way to tell if a pcie-pcix bridge has 
\ physical  slot underneath it, we resort to finding if 
\ the bridge  is  hotplug  capable and hence has slot 
\ underneath. For a pcie port,it is possible to find if 
\ there is physical slot implemented by looking at pci 
\ express capability.
: slot-implemented? ( -- flag )
   \ SHPC Capability?
   shpc-capability-regs if true exit then
   pcie-capability-regs ?dup if			( offs )
      pcie-slot-implemented?			( flag )
   else						(  )
      false					( false )
   then
;
