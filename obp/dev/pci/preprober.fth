\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: preprober.fth
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
id: @(#)preprober.fth 1.1 06/04/13 16:43:08
purpose: Hotplug Preprober Code
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ This file implements hotplug preprober code. Please refer 
\ fwarc case 2006/198 for details.
\
\ Preprober High level Design :-

\ - Preprober will be executed in the host bridge fcode.
\ 
\ - The objective of the preprober is to scan the pci hierarchy
\   with as little side effect as possible and gather count of 
\   1st level pci slots (platform onboard slots) and 2nd level 
\   hotplug capable pci slots (expansion box slots). Once it gets 
\   this data, it will publish the following properties under 
\   the root complex,
\
\      "level1-hotplug-slot-count"
\      "level2-hotplug-slot-count"
\
\ - Preprober will be executed right before the regular "pci-prober"
\   within the "master-probe". This is to make sure the root complex 
\   driver has taken care of setting up the hardware like checking 
\   link training status and other pertinent status bits before 
\   preprobing the pci fabric.
\   
\ - As for platforms adopting the new hotplug allocation code, 
\   most of the older platform will continue with their current 
\   root complex driver without any change for preprobing or the new 
\   hotplug preallocation scheme. This is because , except for starcat 
\   which has it's own specific bus number preallocation scheme, all 
\   the older platform don't support pci hotplug at hardware level or 
\   software level. Also I want to add Netra boards like Jade has it's 
\   own specific hotplug cpci bridge ( dec21554 ) support.  
\ 
\ - Some of the new pci express platforms have decided at the product 
\   team level not to support hotplug at software, so we will have a 
\   compile flag "PCIHOTPLUG?" in the root complex driver to enable 
\   hotplug preallocations for those platfoms that want it. This flag
\   will come handy during debug of pci code. Note that 
\   there won't be any such flag defined for the generic pci-pci 
\   bridge driver. For the bridge fcode, it will be determined at 
\   the  run time based upon the above properties published by 
\   host bridge node whether to enable hotplug preallocation feature or 
\   not. In addition, the above properties will be made use by the
\   the pci-pci bridge driver to calculate hotplug allocation
\   value for 1st level and 2nd level slots. 
\  
headerless

h# 0c constant shpc-capability			\ Standard hotplug capability
h# 10 constant pcie-capability			\ PCIE capability		
0 value my-phys.hi

\ Let us give this primitives unique name so
\ that they are specifically used in this file only.
: hp-b@ ( off -- value ) my-phys.hi + " config-b@" $call-self ;
: hp-w@ ( off -- value ) my-phys.hi + " config-w@" $call-self ;
: hp-l@ ( off -- value ) my-phys.hi + " config-l@" $call-self ;

: find-std-capability  ( id -- pointer | 0 )
   h# 34 hp-b@                                  ( id pointer )
   begin  dup  while                            ( id pointer )
      2dup hp-w@ wbsplit -rot =  if             ( id pointer next )
         drop nip exit                          ( pointer )
      else
         nip                                    ( id next )
      then
   repeat
   nip
;

: shpc-capability-regs ( -- ptr | 0 ) shpc-capability find-std-capability ;
: pcie-capability-regs ( -- ptr | 0 ) pcie-capability find-std-capability ;

\ Called only if pcie capability is present. Called with the 
\ offset of pcie capability register. Check pcie capability 
\ for downstream port type, slot implemented and slot capability 
\ for hotplug capability of the slot. 
: pcie-hotplug-capable? ( offs -- flag )
   >r r@ 2+ hp-w@				( pcie-cap ) ( R: offs )
   dup 4 >>  h# f and 6 = swap	    		( downstream? pcie-cap ) 
   h# 100 and and if				(  ) ( R: offs )                
      \ downstream port and slot implemented.
      \ check for hotplug capable bit in
      \ slot capability register
      r> d# 20 + hp-l@ h# 40 and 0<>		( flag )
   else 
      \ upstream port or slot not implemented
      r> drop false				( false )
   then
;

\ Called only if pcie capability is present. Called with 
\ the  offset  of pcie capability register. Check  pcie 
\ capability for downstream port type and slot implemented.
: pcie-slot-implemented? ( offs -- flag )
   2+ hp-w@					( pcie-cap )
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
: hotplug-capability? ( phys.hi -- flag )
   to my-phys.hi
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
: slot-implemented? ( phys.hi -- flag )
   to my-phys.hi
   \ SHPC Capability?
   shpc-capability-regs if true exit then
   pcie-capability-regs ?dup if			( offs )
      pcie-slot-implemented?			( flag )
   else						(  )
      false					( false )
   then
;
\ Preprober variables and constants
0 value active-bus#		\ Current pci bus
0 value 1st-level-cnt		\ 1st level slot count
0 value 2nd-level-cnt		\ 2nd level slot count
				\ under a given 1st level slot.
0 value max-2nd-level-cnt	\ Maximum 2nd level slot
				\ count in the hierarchy.
d# 20 constant hi-dev#		\ Max device# probed

\ Programs primary,secondary and subordinate bus# register. 
\ phys.hi is the config address of the bridge.
\ active-bus# points to the secondary bus of the bridge.
: program-bus# ( phys.hi -- phys.hi )
   \ Program primary bus#
   dup d# 16 rshift h# ff and			( phys.hi bus# )
   over h# 18 + self-b!				( phys.hi )

   \ Program Secondary bus#
   active-bus# over h# 19 + self-b!		( phys.hi )

   \ Program Subordinate bus#
   h# ff over h# 1a +  self-b!			( phys.hi )
;

\ Clear bus# registers of the nexus bridge.
: clear-bus#-registers ( phys.hi -- phys.hi )
   \ Clear Secondary bus#
   h# ff over h# 19 + self-b!			( phys.hi )
   \ Clear Subordinate bus#
   h# ff over h# 1a +  self-b!			( phys.hi )
   \ Clear Primary bus#
   h# ff over h# 18 +  self-b!			( phys.hi )
;

\ Detects if this is a valid pci function.
: function-present?  ( phys.hi -- flag )  self-w@ h# ffff <> ;

: bus#>cfg ( bus -- phys.hi )     h# ff and d# 16 lshift  ;
: dev#>cfg ( dev -- phys.hi )     h# 1f and d# 11 lshift  ;
: cfg>bus# ( phys.hi -- bus# )    d# 16 rshift  h# ff and ;
: cfg>dev# ( phys.hi -- device# ) d# 11 rshift  h# 1f and ;
: fcn#>cfg ( fn  -- phys.hi )     h#  7 and d#  8 lshift  ;


\ Detects if this is a pci nexus bridge. 
: pci-bridge? ( phys.hi --  phys.hi flag )
   dup function-present? if			( phys.hi )
      dup h# a + self-w@ h# 604 =		( phys.hi flag )
   else						( phys.hi )
      false					( phys.hi flag )
   then						( phys.hi flag )
;

\ Returns 0 if the card isn't present, 8 for a multifunction 
\ card, 1 otherwise
: max#functions  ( phys.hi -- phys.hi n )
   dup function-present?  if			( phys.hi )
      dup h# e +  self-b@			( phys.hi field )
      h# 80  and  if  8  else  1  then		( phys.hi n )
   else						( phys.hi )
      0						( phys.hi n )
   then
;

\ First config address on the secondary bus
: child-config-space ( -- phys.hi )
   active-bus# bus#>cfg				( phys.hi )
;

\ This function:
\     - increments active-bus# by one.
\     - sets primary,secondary,subordinate bus# registers. 
: setup-bridge ( phys.hi -- phys.hi )
   active-bus# 1+ to active-bus# program-bus# 	( phys.hi )
;

[ifdef] PREP_DEBUG   
\ Debug methods
: .1st-level-slot ( phys.hi -- phys.hi )
   cr ." 1st level slot found @ " dup u. 
;

: .2nd-level-slot ( phys.hi -- phys.hi )
   cr ." 2nd level slot found @ " dup u. 
;

: .total-slot-count ( -- )
    cr ." Total 1st level slots : " 1st-level-cnt u.
    cr ." Total 2nd level slots : " max-2nd-level-cnt u.
;
[then]

\ This routine recursively scans for 2nd level hotplug capable
\ slots under any given pci nexus node in the hierarchy. 
\ This function expects,
\     - active-bus# to point to it's secondary bus.
\     - primary,secondary,subordinate bus# registers to be set. 
\
: 2nd-level-probe ( -- )
   recursive                            (  )
   child-config-space                           ( phys.hi )
   hi-dev# dev#>cfg bounds                      ( phys.hi-top phys.hi )
   \ Probe this nexus downward for 2nd 
   \ level slots.
   begin                                        ( phys.hi-top phys.hi )
   2dup > while					( phys.hi-top phys.hi )
      dup function-present? if                  ( phys.hi-top phys.hi )
         max#functions ?dup if                  ( phys.hi-top phys.hi n )
	    \ check out each function of 
	    \ this pci device
            0 do                                ( phys.hi-top phys.hi )
               i fcn#>cfg over + pci-bridge? if ( phys.hi-top phys.hi phys.hi.fcn# )
		  dup hotplug-capability? if	( phys.hi-top phys.hi phys.hi.fcn# )
		     \ Found 2nd level hotplug 
		     \ slot. Increment 2nd level 
		     \ count and continue onto 
		     \ next func#.
[ifdef] PREP_DEBUG   
                     .2nd-level-slot		( phys.hi-top phys.hi phys.hi.fcn# )
[then]
		     2nd-level-cnt 1+ to 2nd-level-cnt
						( phys.hi-top phys.hi phys.hi.fcn# )
                  else                   	( phys.hi-top phys.hi phys.hi.fcn# )
		     \ No 2nd level hotplug slots
		     \ here, hence go down the 
		     \ link looking for them.
                     setup-bridge		( phys.hi-top phys.hi phys.hi.fcn# )
                     2nd-level-probe		( phys.hi-top phys.hi phys.hi.fcn# )
		     \ Done with the 2nd level
		     \ probe on this link. Let 
		     \ us reset the bus# regs 
		     \ on the current pci bridge 
		     \ and continue onto next 
		     \ func#.
                     clear-bus#-registers	( phys.hi-top phys.hi phys.hi.fcn# )
                  then 				( phys.hi-top phys.hi phys.hi.fcn# )
               then                             ( phys.hi-top phys.hi phys.hi.fcn# )
               drop                             ( phys.hi-top phys.hi )
	       \ go to the next func#
            loop                                ( phys.hi-top phys.hi )
         then                                   ( phys.hi-top phys.hi )
      then                                      ( phys.hi-top phys.hi )
      \ go to the next dev#
      1 dev#>cfg +                              ( phys.hi-top phys.hi' )
   repeat                                       ( phys.hi-top phys.hi' )
   2drop
;

\ The preprober code has detected a pci-pci bridge and hence
\ it goes down under the bridge and probes it recursively to
\ look for 1st level slots on the platform.
\ This function expects,
\     - active-bus# to point to it's secondary bus.
\     - primary,secondary,subordinate bus# registers to be set. 
\
: 1st-level-probe ( -- )
   recursive					(  )
   child-config-space				( phys.hi ) 
   hi-dev# dev#>cfg bounds			( phys.hi-top phys.hi )
   \ Probe this nexus downward for 1st 
   \ level slots.
   begin					( phys.hi-top phys.hi )
   2dup > while					( phys.hi-top phys.hi ) 
      dup function-present? if			( phys.hi-top phys.hi )
         max#functions ?dup if			( phys.hi-top phys.hi n )
	    \ check out each function of 
	    \ this pci device
            0 do				( phys.hi-top phys.hi ) 
               i fcn#>cfg over + pci-bridge? if	( phys.hi-top phys.hi phys.hi.fcn# )
		  dup slot-implemented? if	( phys.hi-top phys.hi phys.hi.fcn# )
		     \ Found 1st level pci 
		     \ slot. Increment 1st level 
		     \ count and go down the link
		     \ looking for 2nd level slot.
[ifdef] PREP_DEBUG   
                     .1st-level-slot			( phys.hi-top phys.hi phys.hi.fcn# )
[then]
		     1st-level-cnt 1+ to 1st-level-cnt  ( phys.hi-top phys.hi phys.hi.fcn# )
		     0 to 2nd-level-cnt			( phys.hi-top phys.hi phys.hi.fcn# )
                     setup-bridge                       ( phys.hi-top phys.hi phys.hi.fcn# )
                     2nd-level-probe			( phys.hi-top phys.hi phys.hi.fcn# ) 	
		     \ Done with the 2nd level probe
		     \ on this link. Let us reset the
		     \ bus# regs, update max 2nd level
		     \ count and continue onto next 
		     \ func#.
		     clear-bus#-registers		( phys.hi-top phys.hi phys.hi.fcn# )
		     2nd-level-cnt max-2nd-level-cnt	( phys.hi-top phys.hi phys.hi.fcn# cnt max-cnt )
		     max to max-2nd-level-cnt
		  else
		     \ No 1st level pci slots here, 
		     \ hence go down the link looking 
		     \ for them.
                     setup-bridge                       ( phys.hi-top phys.hi phys.hi.fcn# )
                     1st-level-probe			( phys.hi-top phys.hi phys.hi.fcn# )
		     \ Done with the 1st level probe 
		     \ on this link. Let us reset the 
		     \ bus# regs on the current pci 
		     \ bridge and continue onto next 
		     \ func#.
                     clear-bus#-registers		( phys.hi-top phys.hi phys.hi.fcn# )
		  then					( phys.hi-top phys.hi phys.hi.fcn# )	
               then					( phys.hi-top phys.hi phys.hi.fcn# )
               drop					( phys.hi-top phys.hi )
	       \ go to the next func#.
            loop					( phys.hi-top phys.hi )
         then						( phys.hi-top phys.hi )
      then						( phys.hi-top phys.hi )
      \ go to the next dev#
      1 dev#>cfg +					( phys.hi-top phys.hi' )
   repeat						( phys.hi-top phys.hi' )
   2drop
;

\ preprober takes a copy of the probe-list which is passed
\ to the regular prober. For each dev# in probe-list it determines
\ whether it is a bridge device and if so, it goes down it's 
\ secondary side and scouts it's fabric to locate pci slots.
: preprober ( $adr,len --  )
[ifdef] PREP_DEBUG   
    cr ." Preprobing " " pwd" eval
[then]
   0 to 1st-level-cnt				( $adr,len )
   0 to 2nd-level-cnt				( $adr,len )
   0 to max-2nd-level-cnt			( $adr,len )
   begin  dup  while				( $adr,len )
      ascii , left-parse-string			( rem$ dev#$ )
   (decode-unit) nip nip                   	( rem$ phys.hi.dev )
   dup function-present? if                     ( rem$ phys.hi.dev )
      max#functions ?dup if			( rem$ phys.hi.dev n )
	 0 do					( rem$ phys.hi.dev )
            i fcn#>cfg over + pci-bridge? if	( rem$ phys.hi.dev phys.hi.fcn# )
	       dup cfg>bus# is active-bus#	( rem$ phys.hi.dev phys.hi.fcn# )
               setup-bridge			( rem$ phys.hi.dev phys.hi.fcn# )
	       1st-level-probe			( rem$ phys.hi.dev phys.hi.fcn# )
               \ Done with the 1st level probe 
               \ on this function. Let us reset the 
               \ bus# regs on the current pci 
               \ bridge and continue onto next 
               \ func#.
               clear-bus#-registers		( rem$ phys.hi.dev phys.hi.fcn# )
	    then				( rem$ phys.hi.dev phys.hi.fcn# )
	    drop				( rem$ phys.hi.dev )
	 loop					( rem$ phys.hi.dev )
      then					( rem$ phys.hi.dev )
   then						( rem$ phys.hi.dev )
   drop						( rem$ )
   repeat					( null$ )
   2drop 					(  )
[ifdef] PREP_DEBUG   
   .total-slot-count				(  )
[then]
   \ Now we got the slot counts, let us publish the properties
   1st-level-cnt     encode-int " level1-hotplug-slot-count" property
   max-2nd-level-cnt encode-int " level2-hotplug-slot-count" property
;
