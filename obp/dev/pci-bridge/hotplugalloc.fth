\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hotplugalloc.fth
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
id: @(#)hotplugalloc.fth 1.1 06/04/13 15:57:43
purpose: PCI bridge probe code
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex
headerless

\ This file implements hotplug enabled resource allocation 
\ routines. Please refer fwarc case 2006/198 for details.

fload ${BP}/dev/pci/hotplugdetect.fth

\ Aggregrate Resource set aside for hotplug
h# 800.0000    value hotplug-iosize        \ 128  MB of io space
h# 4000.0000   value hotplug-memsize       \ 1 GB of Mem32 space
d# 224         value hotplug-busrange      \ 224 extra busses

false          value preallocation-scheme?
0              value hotplug-memlimit
0              value hotplug-iolimit
0              value hotplug-buslimit
false          value my-slot?
0              value 1st-level-cnt
0              value 2nd-level-cnt

: make-power-of-2 ( n -- n' )
   d# 32 0 do                                   ( n )
      1 i lshift                                ( n p2 )
      2dup u<= if                               ( n p2 )
        nip leave                               ( p2 )
      else                                      ( n p2 )
        drop                                    ( n )
      then                                      ( n )
   loop                                         ( p2 )
;

\ Those platforms which implement the latest hotplug
\ allocation scheme, will run a pci bus preprober in
\ the host bridge driver to gather information about
\ 1st level slots (host platform slots) and 2nd level
\ slots (expansion box slots) and publish the following
\ properties,
\        "level1-hotplug-slot-count"
\        "level2-hotplug-slot-count"
\
\ These properties are later consumed by the pci-pci
\ bridge driver to calculate hotplug resource. 
: slot-count-inherited-property? ( -- true | false )
   \ Get 1st level slot count property
   " level1-hotplug-slot-count" get-inherited-property 0= if  	( prop-addr len )
      decode-int to 1st-level-cnt 2drop				(  )
      \ Since the first level slot count property is there,
      \ we assume the 2nd level slot count property will be there.
      " level2-hotplug-slot-count" get-inherited-property drop 	( prop-addr len )
      decode-int to 2nd-level-cnt 2drop				(  )
      true							( true )
   else
      false							( false )
   then
;

\ Let us determine if this nexus node has 1st level slots
\ (platform onboard slots) or 2nd level slots (expansion box slots).
\ That will give us the divisor to be used when scaling down the
\ hotplug allocation values for my slots. Note that the 1st level
\ slots get higher hotplug resource as compared to the 2nd level
\ slots. The divisor is found on this policy,
\
\    if I have 1st-level slots then,
\         divisor = 1st-slot-cnt
\    if I have 2nd-level slots then,
\         divisor = 1st-slot-cnt * 2nd-slot-cnt
\
: init-hotplug-params ( -- )
   \ Does any of my parent have slot-implemented?
   " slot-implemented?" get-inherited-property 0= if	( addr len )
      \ If so, then my slots are 2nd level slots.
      \ So divisor = 1st-slot-cnt * 2nd-slot-cnt.
      2drop 1st-level-cnt 2nd-level-cnt *		( divisor )
   else
      \ My slots are 1st level slots.
      \ So divisor = 1st-slot-cnt.
      1st-level-cnt					( divisor )
   then
   ?dup if						( divisor )
      hotplug-busrange over / to hotplug-busrange	( divisor )
      make-power-of-2					( divisor' )
      hotplug-iosize over / to hotplug-iosize    	( divisor' )
      hotplug-memsize swap / to hotplug-memsize  	(  )
[ifdef] HOTPLUG-DEBUG?
      cr ." Hotplug range for this bridge : " " pwd" eval
      ." hotplug-memsize               : " hotplug-memsize u.
      cr ." hotplug-iosize                : " hotplug-iosize u.
      cr ." hotplug-busrange              : " hotplug-busrange u.
[then]
   then							(  )
;

\ Hotplug enabled claim-pci-resource .
: hp-claim-pci-resource ( -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   \ Does this bridge implement hotplug slots ?
   hotplug-capability? if			(  )
      true is my-slot?				(  )
      init-hotplug-params			(  )
      hotplug-capable-prop			(  )
      \ Now let us allocate resource for the bridge
      0 allocate-bridge-resources		( . . . . . . bus# )
      \ Since this is hotplug capable, set the upper range for this 
      \ bridge's hotplug resource window.
      dup hotplug-busrange + is hotplug-buslimit	
			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# ) 
      6 pick hotplug-memsize + 4 pick min is hotplug-memlimit
			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# ) 
      5 pick hotplug-iosize + 3 pick min is hotplug-iolimit
			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# ) 
   else		
      \ The bridge does not have hotplug slots.
      \ let us see if it just implements standard pci slots without
      \ hotplug capability. This information is needed to determine
      \ if the slots downstream to me in the hierarchy are 1st level 
      \ or 2nd level.
      slot-implemented? is my-slot?		( )	
      \ Now let us allocate resource for the bridge
      0 allocate-bridge-resources		( . . . . . . bus# )
   then
   \ Publish my "slot-implemented?" property
   my-slot? if 0 0 " slot-implemented?" property then
;

\ This routine while releasing the unused bridge resources back to 
\ the parent node, will retain some portion of it for later hotplug
\ operation. This is what we term as "hotplug preallocation". So as
\ a outcome of this routine, the upper ranges of the bridge resources
\ will be left at the following minimum water mark,
\
\   hotplug-buslimit = Total bus numbers left to the bridge.
\   hotplug-memlimit = Upper range of mem32 space
\   hotplug-iolimit  = Upper range of IO space
\
: hp-retain-pci-resource ( -- )
   \  Params for  allocate-bus#  are   ( n m-aln m-sz io-aln io-sz )
   hotplug-buslimit 		\ Total minimum bus range 
   h# 10.0000  hotplug-memlimit \ mem32 alignment and size 
   h# 1000     hotplug-iolimit	\ io alignment and size 
   allocate-bus# 		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   
   \  Subordinate Bus Number register: 
   h# 1a my-b!			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   drop set-limits 		( mem-lo io-lo dma-lo )
   3drop
;

\ Reduce the subordinate bus# to the maximum bus number of any
\ of our children, and the memory and IO forwarding limits to
\ the limits of the address space actually allocated.  ...
: (hp-free-unused-pci-resource) ( -- )
   -1 allocate-bridge-resources    ( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )	
   h# 1a my-b!			   ( mem-lo io-lo dma-lo mem-hi io-hi dma-hi )
   drop set-limits		   ( mem-lo io-lo dma-lo )
   3drop
;
