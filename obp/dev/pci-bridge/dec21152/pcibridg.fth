\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pcibridg.fth
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
id: @(#)pcibridg.fth 1.36 06/05/16 12:51:44
purpose: PCI bridge probe code
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headerless

fload ${BP}/dev/pci-bridge/dec21152/config.fth
fload ${BP}/dev/pci/compatible.fth
fload ${BP}/dev/pci-bridge/pcinode.fth

: make-physical-slot#-prop ( -- )
   \ Check if the device is a PCI Express device.
   pcie-capability-regs ?dup if		( pointer| )
      \ Check if the device is a Root Port or Downstream Port
      dup 2 + my-w@ dup 4 >> h# f and	( pointer capabilities type )
      dup 6 = swap 4 = or if		( pointer capabilities )
         \ Check if the device implements a slot
         1 8 << and if			( pointer )
            \ If so, extract the physical slot number
            h# 14 + my-l@ d# 19 >>	( slot-num )
            encode-int 			( propaddr,len )
            " physical-slot#" property	(  )
         else				( pointer )
            drop			(  )
         then				(  )
      else				( pointer capabilities )
         2drop				(  )
      then				(  )
   then					(  )
;

make-physical-slot#-prop

0 0 my-space  encode-phys  0 encode-int encode+  0 encode-int encode+
" reg" property

make-compatible-property

headers

: prefetch-ranges-off  ( -- )
   \ Turn off prefetchable memory forwarding range
   h# 0000ffff  h# 24 my-l!	\ Prefetchable Limit,Base
   h# ffffffff  h# 28 my-l!	\ Prefetchable Base upper 32 bits
   h#        0  h# 2c my-l!	\ Prefetchable Limit upper 32 bits
;

: set-bases  ( mem-base io-base -- )
   \ Set I/O forwarding base
   lwsplit  h# 30 my-w!  wbsplit  h# 1c my-b!  drop  ( mem-base )

   \ Set non-prefetchable memory forwarding base
   lwsplit  h# 20 my-w!  drop  ( )
;

: set-limits  ( mem-limit+1 io-limit+1 -- )
   \ Set I/O forwarding limit
   ?dup if
      1- lwsplit  h# 32 my-w!  wbsplit  h# 1d my-b!	\  Write I/O Limit
      drop
   then							( mem-limit+1 )

   \ Set non-prefetchable memory forwarding range
   ?dup if  1- lwsplit  h# 22 my-w!  drop  then		( )
;

: restore-limits  ( mem-limit+1 io-limit+1 -- )
   \ Set I/O forwarding limit
   ?dup if
      1- lwsplit  h# 32 my-w!  wbsplit  h# 1d my-b!	\  Write I/O Limit
      drop
   else
      \ If the I/O limit is zero, set base and limit registers to
      \ disable I/O forwarding
      0 h# 1d my-b! 10 h# 1c my-b!
   then						( mem-limit+1 )

   \ Set non-prefetchable memory forwarding range
   \ To disable forwarding we hardcode a negative range... same as Windows
   \ NOTE: this is a change from the legacy algorithm (setting limit = base-1)
   \ due to problems seen on the PLX 8532 switch.
   \ See CR 6397497 for more details.

   h# 20 my-w@ d# 16 <<		( limit+1 base )
   over	>= if
      drop			\ base >= limit --> disable memory forwarding
      h# fff0 h# 20 my-w!	\ set base  = large (both bytes > limit)
            0 h# 22 my-w!	\ set limit = 0
   else
      1- d# 16 >> h# 22 my-w!	\ base < limit --> enable memory forwarding
   then
;


fload ${BP}/dev/pci-bridge/range.fth

\ Create the ranges property needed by hot-plug. Derive information
\ directly from config-space, to ensure property reflects what the
\ chip actually responds to.

: io.lo,hi-join ( iox.lo iox.hi -- iox )
   d# 16 lshift swap			( hi' lo )
   h# f0 and d# 8 lshift 		( hi' lo' )
   +					( hi+lo )
;

: encode-io-range ( propaddr,len -- propaddr,len' )
   1			      ( propaddr,len type )
   \ Fetch io-base and limits (split across two BARs)
   h# 30 my-l@ lwsplit	      ( propaddr,len type iob.hi iol.hi )
   h# 1c my-w@ wbsplit	      ( propaddr,len type iob.hi iol.hi iob.lo iol.lo )
   rot io.lo,hi-join	      ( propaddr,len type iob.hi iob.lo iolimit' )
   h# 1000 + 		      ( propaddr,len type iob.hi iob.lo iolimit )
   -rot swap io.lo,hi-join     ( propaddr,len type iolimit iobase )
   tuck -		      ( propaddr,len type iobase iosize )
   encode-range		      ( propaddr,len' )
;

: encode-mem-range ( propaddr,len -- propaddr,len' )
   2			      ( propaddr,len type )
   \ Fetch memory base and limit. Single BAR.
   h# 20 my-l@ lwsplit	      ( propaddr,len type memb.hi meml.hi )
   d# 16 lshift h# 10.0000 +   ( propaddr,len type memb.hi memlimit )
   swap d# 16 lshift	      ( propaddr,len type memlimit membase )
   tuck -		      ( propaddr,len type membase memsize )
   encode-range		      ( propaddr,len )
;

: create-ranges ( -- )
   0 0 encode-bytes			( propaddr,len )
   encode-io-range			( propaddr,len' )
   encode-mem-range			( propaddr,len'' )
   ?dup if  " ranges" property  else  drop  then
;

: "hotplug-capable" ( -- $adr,len )  " hotplug-capable" ;

false value hotplug-capable?

: hotplug-capable-prop ( -- )
   0 0     "hotplug-capable"        property
   true to hotplug-capable?
;

\  Generate the common parameters for,
\  and make the call to,  allocate-bus#  
: allocate-bridge-resources ( acquire? -- . . . . . . . )
			( .. -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   h# 10.0000 0 h# 1000 0 allocate-bus#
;

fload ${BP}/dev/pci-bridge/hotplugalloc.fth

\  This is renamed from claim-pci-resource to (claim-pci-resource.
\  Acquire the maximum amount of memory and IO address space for
\  this bridge, in advance of probing it.  For a "normal" bridge,
\  i.e., one that is not hotplug-capable, we need only claim one
\  bus number (our own).
\
\  For a hotplug-capable bridge, we need to claim a large number
\  of subordinate busses:  a generous enough allotment to cover
\  all conceivable hotplug needs, but not so many as to interfere
\  with expansion by devices already attached; let's say, half
\  the possible range, less one for our own.
\
\  Secondary Bus# is returned as a side-effect.
\
: (claim-pci-resource ( -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   hotplug-capable? if

      h# 7f allocate-bridge-resources		( . . . . . . bus# )
   else
      1 allocate-bridge-resources		( . . . . . . bus# )
   then
;

\ This routine calls the legacy allocation routine  
\ "(claim-pci-resource" or the newer hotplug enabled allocation 
\ routine "hp-claim-pci-resource" based on the presence or absence of
\ the two slot count properties,
\
\        "level1-hotplug-slot-count"
\        "level2-hotplug-slot-count"
\
\ in the host bridge node.
\
: claim-pci-resource ( -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   slot-count-inherited-property? dup is preallocation-scheme?
   if
      hp-claim-pci-resource	( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   else
      \ This platform implements legacy allocation scheme.
      (claim-pci-resource	( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   then
;

\  Initialize the  Primary Bus# reg
: init-primary-bus# ( -- )
   my-space  d# 16 rshift h# ff and
   h# 18 my-b!					\ Primary bus#
;

\  Assign the Secondary Bus# that was returned by
\  the  claim-pci-resource  function;
\  Clean up the stack before returning.
: init-secondary-bus# ( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# -- .... )
				( . . . . . . . -- mem-lo io-lo mem-hi io-hi )
   dup to my-bus#
   h# 19 my-b!					\  Write to Secondary Bus# reg
				( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   drop rot drop		( mem-lo io-lo mem-hi io-hi )
;

\ Set the subordinate bus number to ff in order to pass through any
\ type 1 cycle with a bus number higher than the secondary bus#
: init-subordinate-bus# (  -- )
   h# ff h# 1a my-b!
;


\  Clean up the resources of the bridge, but leave the full allocation.
\  Reduce the subordinate bus# to the maximum bus number of any of our
\  children, but keep memory and IO forwarding limits as pre-configured.
\
: retain-pci-resource ( -- )
   \  Params for  allocate-bus#  are   ( n m-aln m-sz io-aln io-sz )
   0		\  Release (rather than acquire) resources.
   0  -1	\  Mem-alignment irrelevant, non-zero mem-size
   0  -1	\  I/O-alignment irrelevant, non-zero i/o-size

   allocate-bus# 		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )

   \  Subordinate Bus Number register: 
   h# 1a my-b!			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   2drop 2drop 2drop
;

\ Reduce the subordinate bus# to the maximum bus number of any
\ of our children, and the memory and IO forwarding limits to
\ the limits of the address space actually allocated.  ...
: (free-unused-pci-resource) ( -- )
   0 allocate-bridge-resources
   h# 1a my-b!			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   drop				( mem-lo io-lo dma-lo mem-hi io-hi ) 
   restore-limits 3drop		( )
;

\ ...
\  Unless this bridge supports hotplug, in which case we want
\  to leave it with a full allocation.
: free-unused-pci-resource ( -- )
   preallocation-scheme? if
      hotplug-capable? if
	 hp-retain-pci-resource
      else
	 (hp-free-unused-pci-resource) 
      then
   else
      hotplug-capable? if
         retain-pci-resource
      else
         (free-unused-pci-resource)
      then
   then
;

: clear-status-bits ( -- )
   h# ffff  h# 1e my-w!
;

: clear-pcie-errors  ( -- )
   pci-express? 0=  if  exit  then
   aer-capability-regs ?dup if	
      get-port-type dup >r 7 = r@ 8 = or if	\ bridges have secondary errors
         -1 over h# 2c + my-l!			\ secondary UEs
         -1 over h# 34 + my-l!			\ secondary CEs
      then
      r> h# c and if			\ Switches and bridges have primary errors
         -1 over    04 + my-l!		\ UEs
         -1 swap h# 10 + my-l!		\ CEs
      else
         drop
      then
   then 
   pcie-capability-regs h# a + dup	\ Clear all errors in
   my-w@ h# f or swap my-w!		\ pci-express device status  
;

\  Disable memory, IO, and bus mastership;
\  leave everything else as is.
: disable-mem,io&bus-mastr ( -- )
   4 my-w@ h# fff8 and  4 my-w!     ( )
;


\ Enable memory, IO, and bus mastership
: enable-mem,io&bus-mastr ( -- )
   \ XXX should we enable parity, SERR#, fast back-to-back, and addr. stepping?
   \ In case of pci-express bridge, disable INTx ( bit 10 ) before solaris boot
   \ to get rid of storm of INTx assertions from the numberous virtual pci-pci bridges.
   4 my-w@ 				( value )
[ifdef] DISABLE-INTx
   pci-express? if h# 407 else 7 then 	( value enable-mask )
[else]
   7					( value enable-mask )
[then]
   or  4 my-w!     			( )
;

\ The IBM bridge is somewhat funny
: ?ibm-bridge-hack ( -- )
   0 my-l@ h# 221014 =  if  h# 22 h# 3e my-b!  then
;

\ This intel bridge requires certain performance bits be set
: ?intel-restream-enable  ( -- )
   0 my-l@ dup h# 3408086 = swap h# 3418086 = or if  
      h# 174 my-l@ h# 40 invert and h# 174 my-l!
   then
;

: probe-children ( -- )
   " 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18,19,1a,1b,1c,1d,1e,1f"	( $ )
   pci-express? if
      pcie-capability-regs 2+ my-w@ 4 rshift h# f and h# 6 =  if
         2drop " 0"
      then
   then							( probelist$ )
   " my-probe-list" get-my-property 0= if		( probelist$ prop$ )
      2swap 2drop decode-string 2swap 2drop		( probelist$ )
   then  prober-xt execute				(  )
;

: create-bus-range ( -- )
   my-bus#  encode-int  h# 1a my-b@  encode-int encode+
   " bus-range"  property
;

[ifndef] starcat-xmits

\ Paranoia, perhaps justified
: disable-children  ( -- )
   my-bus# d# 16 lshift  4 +			( space+reg-template )
   h# 1.0000 bounds  do                         \ For all the children 0-1f
      h# 800 0 do                               \ For each function
         0 j i + config-w!                      \ Clear command register
      h# 100 +loop                              \ Next function
   h# 800 +loop                                 \ Next device
;

[else]	\  It IS StarCat-XMITS

\  Special section for XMITS builtin subordinate bridge

: get-parent-int-prop? ( $adr,len -- n true | false )
   my-self >r
   my-parent is my-self	\  And I'm my own grandpa...
      get-my-property		( xdr,len false | true )
   r> is my-self
   if  false
   else  decode-int true 2swap 2drop 
   then
;

\  The earlier self-styled "Paranoia, perhaps justified" has become
\  an issue for certain devices (in particular, the "Golden I/O-SRam"
\  on the subsidiary bridge of XMITS) that need to remain enabled.
\
\  To get around that, we are unilaterally inventing a private
\  interface:  an integer-valued property, named  don't-disable ,
\  whose value is a bit-mask with the semantics that, if bit N is
\  set, that is an indication not to disable the descendant device
\  corresponding to N.
\
\  If the property is absent, then all descendant devices get disabled,
\  rendering the interface completely backwards compatible.

: "don't-disable" ( -- $addr,len )  " don't-disable" ;

\  Return the mask of descendant devices *TO* disable.
\  This will be the inverse of the  don't-disable  integer
\  mask value, or -1 if the property was not found.
: get-disable-mask ( -- mask)
   "don't-disable" get-parent-int-prop?  if
      invert
    else
      -1
   then
;

\  Paranoia, perhaps justified, rev 2
: disable-children  ( -- )
   get-disable-mask				( mask )
   my-bus# d# 16 lshift  4 +			( mask space+reg-template )
   h# 1.0000 bounds  do                         ( mask )
      dup 1 and if
	 h# 800 0 do				\ For each function
            0 j i + config-w!                   \ Clear command register
	 h# 100 +loop				\ Next function
      then  u2/					( mask' )
   h# 800 +loop
   drop
;

\  END Special section for StarCat-XMITS builtin subordinate bridge
[then]	\  starcat-xmits


\  Initialize a bridge from scratch...

: setup-generic-bridge  ( -- )

   \ Turn off memory and I/O response and bus mastership while setting up
   disable-mem,io&bus-mastr

   init-primary-bus#				(  )	\ Primary bus#
							\ Secondary bus#
   claim-pci-resource		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )

   init-secondary-bus#				( mem-lo io-lo mem-hi io-hi )

   init-subordinate-bus#			( mem-lo io-lo mem-hi io-hi )

   disable-children				( mem-lo io-lo mem-hi io-hi )

      \ Initially set the limits to encompassing the rest of the address space
   set-limits					( mem-lo io-lo )

   set-bases					(  )

   clear-status-bits				(  )

   prefetch-ranges-off				(  )

   enable-mem,io&bus-mastr			(  )

   ?ibm-bridge-hack				(  )

   ?intel-restream-enable			(  )

   \ XXX set cache line size in the register at 0c
   \ XXX latency timer in the register at 0d
   \ XXX set secondary latency timer in the register at 1b

   probe-children				(  )

   clear-status-bits				(  )

   clear-pcie-errors				(  )

   free-unused-pci-resource			(  )

   create-bus-range

   create-ranges				(  )
;

[ifdef] starcat-xmits

\  The following code is specific to the StarCat XMITS I/O board,
\  which has a PCI-Bridge on one of its leaves, with several
\  built-in devices and a slot below it.
\
\  The code to support those devices and the slot has to be invoked
\  from the PCI-Bridge creation because this is where those devices
\  reside.

\  Create the slot-names property for the builtin
\  subsidiary pci-bridge on StarCat XMITS
: create-xmits-bridge-slot-names ( -- )
   \  +---> dev-sel 3 RIO
   \  |+---> dev-sel 2 SBBC
   \  ||+---> dev-sel 1 plugin slot <--------
   \  |||+---> dev-sel 0 onboard PBM
   \  ||||
   \  vvVv
   b# 0010					\ Mask of implemented slots
   encode-int
   " C5V0"					\ Leaf B Port-ID 0
   encode-string encode+			\ Slot 1 Label
   " slot-names"  property
;


\  Probe the SBBC first; claim its pre-configured addresses.
: create-my-probe-list-prop ( -- )
   " 2,1,3"			( probelist$ )
   encode-string
   " my-probe-list" property
;

\  An elaborate  interrupt-map  property applies to the XMITS builtin
\  subordinate bridge, where the built-in devices are attached.

: en+ ( xdr,len n -- xdr,len' )  encode-int encode+  ;

\  Similar to  <schizo>  except instead of a  unit$  of " N,0"
\  where N is 1, 2, or 3, use an integer  space  equal to
\  the decoding of N as a pci subsidiary-device number.
\
\  That number is a combination of N and the bridge's bus number, thus:
: unit#>pa.hi ( unit# -- pa.hi )
   d# 11 <<  my-bus#  d# 16 << or
;

\  Don't call this until after  my-bus#  is established by the
\  call to  init-xmits-secondary-bus#
: <xmits>  ( xdr,len unit# intr -- xdr,len' )
   >r			( xdr,len unit# ) ( R: intr )
	 \  Convert unit# to pa.hi
   unit#>pa.hi		( xdr,len pa.hi ) ( R: intr )
   en+			( xdr,len""' )    ( R: intr ) \  Encode pa.hi
	 \  Both pa.mid and pa.lo are zero
   0 en+ 0 en+		( xdr,len"' )	( R: intr )   \  Encode pa.mid,lo
   r> en+			( xdr,len" )    ( R: )	      \  Encode intr
   my-self ihandle>phandle	( xdr,len" phandle )
   en+			( xdr,len' )	  	      \  Encode phandle
;

\  When the interrupt-map encoding is complete, create the property.
\  The  interrupt-map-mask  and  #interrupt-cells  properties go
\  with it as well... 
: int-map-prop ( xdr-addr,len -- )
   " interrupt-map" property
   0 0 fff800    encode-phys
   7 	    en+     " interrupt-map-mask" property
   1		 encode-int " #interrupt-cells" property
;

:  create-xmits-int-map-prop
   \ NOTE: Interrupt slots for RIO and SBBC don't co-relate to their  device#
   \       PCI BUS B dev # 1 (plug in slot)	= 	Int. slot 1
   \       PCI BUS B dev # 2 (SBBC)		= 	Int. slot 4
   \       PCI BUS B dev # 3 (RIO)		= 	Int. slot 2
   \       HUB				= 	Int. slot 3
   \       HUB is not a PCI device and
   \		        interrupt generated from here will be spurious??

   0 0 encode-bytes
      4 0 do  1  i 1+ <xmits>  4 i +  en+  loop 	\ Slot 1
      4 0 do  2  i 1+ <xmits> 10 i +  en+  loop 	\ SBBC
      4 0 do  3  i 1+ <xmits>  8 i +  en+  loop 	\ RIO
   int-map-prop
;


\  We will count on the  bus#  that was returned by
\  the  claim-full-pci-resource  function to match the
\  pre-configured (POST-configured?) Secondary Bus#
\  register.
\
\  Clean up the stack before returning.
: init-xmits-secondary-bus#
			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# -- )
   to my-bus#			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   2drop 2drop 2drop		(  )
;

\  Create the static properties that can be created early, and,
\  in the case of the  hotplug-capable  property, have to.
: create-xmits-bridge-props ( -- )

   create-xmits-bridge-slot-names
   hotplug-capable-prop

   create-my-probe-list-prop
;


: setup-xmits-bridge  ( -- )

   create-xmits-bridge-props

   \  For the special XMITS bridge, do not turn off
   \  memory, I/O response and bus mastership

   \ Primary bus# is pre-configured.  Do not touch.

   \ Secondary bus#
   claim-pci-resource		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )

   init-xmits-secondary-bus#			(  )

   \  The  interrupt-map  property can only be created after
   \   my-bus#  has been set.  See note near def'n of  <xmits>
   create-xmits-int-map-prop

   \ Subordinate bus# is pre-configured.  Do not touch.

   disable-children

    \  Limit and base registers are pre-configured.

   clear-status-bits

   \  For the special XMITS bridge, do not turn off
   \  prefetchable memory forwarding range.


   enable-mem,io&bus-mastr

   \  We know the XMITS bridge is not the IBM bridge

   \ XXX set cache line size in the register at 0c
   \ XXX latency timer in the register at 0d
   \ XXX set secondary latency timer in the register at 1b

   probe-children

   free-unused-pci-resource

   create-bus-range

   create-ranges
;

: get-xmits-bridge? ( -- flag )
   " xmits-builtin-pci-bridge"
   get-parent-int-prop?  dup  if  drop my-space =  then
;


get-xmits-bridge?

dup constant xmits-bridge?	\  Leave a residue we can check later...
 if    setup-xmits-bridge
else   setup-generic-bridge
then

[else]	\  It's NOT StarCat-XMITS

setup-generic-bridge

[then]	\  starcat-xmits
