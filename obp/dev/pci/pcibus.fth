\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pcibus.fth
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
id: @(#)pcibus.fth 1.19 06/05/03 14:16:52 
purpose:  
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

hex

h# 40 buffer: function-reg-string
0 value pci-depth

headerless
    0 value current-bus#
false value probe-state?

: $config-b@ ( -- str$ ) " config-b@" ;
: $config-b! ( -- str$ ) " config-b!" ;
: $config-w@ ( -- str$ ) " config-w@" ;
: $config-w! ( -- str$ ) " config-w!" ;
: $config-l@ ( -- str$ ) " config-l@" ;
: $config-l! ( -- str$ ) " config-l!" ;

fload ${BP}/dev/pci/make-device.fth
fload ${BP}/dev/pci/make-path.fth

[ifdef] OBERON?
fload ${BP}/dev/oberon/opl/hwd.fth
fload ${BP}/dev/oberon/opl/slot-names.fth
[then]

\
\ bridges need to be able to create some properties after the device
\ has completed probing (available for example) this allows well-known
\ devices to hook code into the point after any fcode will have completed.
\
defer extra-device-function-hook

: make-function-node  ( arg$ reg$ -- )
   new-device  set-args				( )
   populate-device-node				( )
   extra-device-function-hook			( )
   ['] noop to extra-device-function-hook	( )
[ifdef] OBERON?
   " okay" create-status-prop			( )
[then]
   finish-device				( )
;

\
\ ---------------------------------------------------------------------
\ From here down all accesses are in the 'parents' instance, so we
\ need to use self-X type words. Ie these routines are executing in
\ a host adapter context (pci/pci bridge or host/pci device).

: self-b@  ( phys.hi -- b )  $config-b@  $call-self  ;
: self-b!  ( b phys.hi -- )  $config-b!  $call-self  ;
: self-w@  ( phys.hi -- b )  $config-w@  $call-self  ;
: self-w!  ( w phys.hi -- )  $config-w!  $call-self  ;
: self-l@  ( phys.hi -- l )  $config-l@  $call-self  ;
: self-l!  ( l phys.hi -- )  $config-l!  $call-self  ;

: amend-reg$  ( reg$ func# -- reg$' )
   push-hex
   >r  ascii , left-parse-string          ( rem$ head$ )
   2swap 2drop $hnumber  if  0  then  r>  ( dev# func# )
   <# u# drop  ascii , hold  u#s u#> function-reg-string $save
   pop-base
;

\ Returns true if the card implements a function at the indicated
\ configuration address.
\
: function-present?  ( phys.hi -- flag )  self-w@ h# ffff <> ;

headers
\ Create a string of the form  "D,F" where D is the device number portion
\ of the string "reg$" and F is the hexadecimal representation of "func#"
\ Probe the card function func#
: probe-function  ( arg$ reg$ phys.hi fn# -- arg$ reg$ phys.hi )
   2dup fcn#>cfg + function-present?  if	( arg$ reg$ phys.hi fn# )
      2>r  2over 2over				( arg$ reg$ arg$ reg$ )
      r@ amend-reg$				( arg$ reg$ arg$ reg$ )
      make-function-node			( arg$ reg$ )
      2r>					( arg$ reg$ phys.hi fn# )
   then  drop					( arg$ reg$ phys.hi )
;

\ Returns 0 if the card isn't present, 8 for a multifunction card, 1 otherwise
: max#functions  ( phys.hi -- phys.hi n )
   dup function-present?  if			( phys.hi )
      dup h# e +  self-b@			( phys.hi field )
      h# 80  and  if  8  else  1  then		( phys.hi n )
   else						( phys.hi )
      0						( phys.hi n )
   then
;
headerless

\ Probe the card at the address given by fcode$, setting my-address,
\ my-space in the resulting device node to the address given by reg$.
\
\ probe-self is meant to handle one PCI device (= 1 physical slot)
\ at a time.  Up to 8 functions are checked per device.  Each can have
\ a separate piece of FCode controlling it.

: clear-pci-errs ( phys.hi -- )
   6 + dup self-w@			( stat-reg-addr data  )
   h# f900 and                          ( stat-reg-addr clr-err-bits )
   swap self-w!				( -- )
;

: .nothing-there diagnostic-mode?  if  " Nothing there" cmn-append  then ;

\ This is the entry point into the ASR framework.
\ Leave the dev#$ alone and return a flag of true
\ if the device is disabled, otherwise false.
\ If necessary, in the  disabled?  case, the dev#$
\ may be modified for printability.
defer device-disabled? ( dev#$ -- dev#$' disabled? )
' false is device-disabled?

: .probing-path ( dev#$' flag -- dev#$' flag )
   diagnostic-mode?  if
      " Device " cmn-append  3dup drop cmn-append "  " cmn-append  
   then
;

\ Defer word to be redefined differently at platform level
defer pci-function-present?
' function-present? is pci-function-present? 

\
\ The pci-pci bridge probing code.
\
: pci-probe-self ( args$ dev#$ -- )
   ['] noop
   debug-bar-assignment? if  drop ['] .dump-assigned-addr  then
   to extra-device-function-hook
   true to probe-state?

   device-disabled?				( arg$ dev#$' flag )
   .probing-path
   if  2drop  2drop				(  )
      diagnostic-mode?  if  " <Device/Slot Disabled>" cmn-append  then
      exit
   then						( args$ dev#$ )

   2dup (decode-unit) nip nip			( args$ dev#$ phys.hi.dev )
   dup pci-function-present? if			( args$ dev#$ phys.hi.dev )
      max#functions ?dup if
         0   do  i probe-function  loop 	( args$ dev#$ phys.hi.dev )
      else
         .nothing-there
      then
   else						( args$ dev#$ phys.hi.dev )
      .nothing-there
   then						( args$ dev#$ phys.hi.dev )

   3drop 2drop					(  )
   false to probe-state?
;

\ This is the top level prober.
\ The maximum depth of 9 is to ensure that we don't overflow the
\ return stack as we recurse. Better to not probe devices than
\ to crash in some spectacular way.
\

[ifdef] OBERON?

: pci-prober-pass ( args$ dev#$ -- )
   diagnostic-mode?  if  cmn-msg[  then 
   pci-probe-self 
   diagnostic-mode?  if  " " ]cmn-end  then 
;

: pci-prober ( probe-list$adr,len -- )
   \ Increase pci-depth to support iobox.
   pci-depth 9 > if
      ." Maximum PCI probe depth " pci-depth . ." exceeded; "
      ." No further PCI bridge devices can be probed" cr
      2drop exit
   then
   oberon-debug? if cr ." pci-prober: pci-depth=" pci-depth .d cr then

   make-path$ if
      oberon-debug? if ."   devpath=" .path$ then
   else
      cmn-warn[ " make-path$ failed" ]cmn-end
      2drop exit
   then						( $adr,len )

   pci-path count make-pcipath-id if 
      cmn-warn[ " make-pcipath-id failed" ]cmn-end
      2drop exit
   else
       oberon-debug? if ."  (id=" dup 64.x ." ): " cr then
       -rot 					( id $adr,len )
   then
   oberon-debug? if ."   probe-list$=" 2dup type cr then
   2 pick create-pci-slot-names-prop	( id $adr,len )
   select-hwdtab&get-hwdstat
   pci-depth dup >r 1+ to pci-depth	( id $adr,len ) ( R: old-pci-dpth )
   begin  dup  while			( id $adr,len )	( R: old-depth )
      ascii , left-parse-string		( id rem$ dev#$ )	( R: old-depth )
      " "  2swap			( id rem$ arg$ dev#$ ) ( R: old-d )

      push-hex 2dup $number drop pop-base 	( id rem$ arg$ dev#$ dev# )
      7 pick					( id rem$ arg$ dev#$ dev# id )
      get-hwd-status if HWDESC-STAT-UNKNOWN then ( id rem$ arg$ dev#$ hwd-stat )
      case
      HWDESC-STAT-PASS     of pci-prober-pass endof
      dup                  of 2drop 2drop endof
      endcase					( id rem$ )
    repeat					( id null$ )	( R: old-depth )
   3drop
   r> to pci-depth
   oberon-debug? if cr then
;

[else]

: pci-prober ( probe-list$adr,len -- )
   pci-depth 9 > if
      ." Maximum PCI probe depth " pci-depth . ." exceeded;"
      ." No further PCI bridge devices can be probed" cr
      2drop exit
   then
   pci-depth dup >r 1+ to pci-depth		( $adr,len ) ( R: old-pci-dpth )

   begin  dup  while				( $adr,len )	( R: old-depth )
      ascii , left-parse-string			( rem$ dev#$ )	( R: old-depth )
      " "  2swap				( rem$ arg$ dev#$ ) ( R: old-d )

   diagnostic-mode?  if  cmn-msg[  then 

   pci-probe-self 

   diagnostic-mode?  if  " " ]cmn-end  then 
 
   repeat					( null$ )	( R: old-depth )

   2drop
   r> to pci-depth
;

[then]

: get-my-pci-bus# ( -- n )  " my-pci-bus" $call-self  ;

: pci-master-probe  ( adr,len -- )
   0 to pci-depth

   \ If previously probed, we need to update current-bus#
   " bus-range"  get-my-property  0= if
      decode-int nip nip to current-bus#
   else
      get-my-pci-bus#  to current-bus#
   then

   " prober"  $call-self 
   get-my-pci-bus# bus#>cfg clear-pci-errs

   get-my-pci-bus#  encode-int
   current-bus# encode-int encode+ " bus-range" property
;

\ This is called twice for each PCI-PCI bridge,
\ It is called with n=1 at the beginning of the bridge probing sequence,
\ in order to allocate a new bus number and establish base address values.
\ It is called with n=0 at the end of the bridge probing sequence,
\ in order to determine the "high water marks" of the bus numbers and
\ address ranges that were assigned during the (possibly recursive)
\ bridge probing process.

: trim-node ( node memlist align -- )
   >r						( node memlist )
   2dup remove-selected-node drop		( node memlist )
   2dup r@ swap round-node-up			( node memlist )
   r> swap round-node-down			( -- )
;

: .no-resource ( -- )
   cmn-error[ " No resource available for bridge" ]cmn-end 
;

: allocate-biggest-resources ( list align -- node )
   over get-biggest-node			( list align node )
   dup 0= if 					( list align node )
      3drop .no-resource abort
   then
   dup >r -rot trim-node r>		        ( node )
;  

: allocate-actual-resources ( list align size -- node ) 
   dup >r rot allocate-memrange  if  			
      r> drop .no-resource abort
   else 
      r> swap set-node				( node )
   then						( node) 
;

: get-ranges ( mem-n io-n -- mem-l io-l mem-h io-h ) 
   2dup alloc-bar-struct -rot push-stack swap   ( io-n mem-n )
   node-range over +                            ( io-n mem-l mem-h )
   rot                                          ( mem-l mem-h io-n )
   node-range over +                            ( mem-l mem-h io-l io-h )
   rot  swap                                    ( mem-l io-l mem-h io-h )
;

\  If size is zero, acquire the largest available piece of the resource.
: acquire-bridge-resources ( list align size -- node )
   ?dup if 
      allocate-actual-resources
   else 
      allocate-biggest-resources		
   then
;

external

\
\ This routine allows allocation of resources from the current IO/MEM lists.
\
: resource-alloc ( physhi align size -- addr|0 )
   rot cfg>ss# 7 and case
      0  of  2drop false  exit endof		\ cannot claim cfg space
      1  of  pci-io-list       endof
      2  of  pci-memlist       endof
      3  of  pci-memlist       endof
   endcase					( list )
   allocate-memrange if  false  then		( addr|0 )
;

\ This routine returns a range to the relevant list.
\ Be CAREFUL no checking is done to verify that an allocation from one
\ pool is not returned to the other, nor that you are freeing more than
\ you alloc'd.
: resource-free ( physhi addr len -- )
   rot cfg>ss# 7 and case
      0  of  2drop exit    endof		\ cannot claim cfg space
      1  of  pci-io-list   endof
      2  of  pci-memlist   endof
      3  of  pci-memlist   endof
   endcase					( list )
   free-memrange				( )
;

headerless

/n 2* buffer: pci-alloc-lists

: make-bridge-extra-properties ( -- )
   \ Called after the bridge has been probed completely.
   \ The purpose of this routine is to create the 'available' property and
   \ then free the nodes.
   get-pointers >r >r >r 			( )
   r@ pci-alloc-lists 2@ set-pointers		( )
   make-available-property			( )
   pci-alloc-lists 2@ debug-keep-mem-lists? if	( mem io )
      \ Some useful bridge debug properties.
      " io-list" integer-property		( mem )
      " mem-list" integer-property		( )
   else						( mem io )
      free-list free-list			( )
   then						( )
   r> r> r> set-pointers			( )
;

: align-resource-list ( align list -- node )
   dup get-last-node nip			( align list node )
   dup if 					( align list node )
      tuck over remove-selected-node drop       ( align node list )
      swap dup >r -rot round-node-up r>		( node ) 
   then
;

\  If either of the node parameters is zero, this function will
\  bypass the clause that "hands the resource back to the parent";
\  this behavior may be required for hotplug-capable bridges.
: free-resources ( mem-n io-n -- mem-l io-l mem-h io-h )
   pop-stack                                    ( mem-n io-n reg mem io )
   pci-alloc-lists 2!                           ( mem-n io-n reg )
   free-bar-struct                              ( mem-n io-n )
   ['] make-bridge-extra-properties             ( mem-n io-n acf )
   to extra-device-function-hook                ( mem-n io-n )
   \ When we get here we have removed the trailing resources
   \ from the bridge. Now we need to hand the resources back
   \ to the parent bridge.
   >r dup if                                    ( mem-n )
      dup node-range                            ( mem-n adr len )
      2dup pci-memlist free-memrange            ( mem-n adr len )
      drop swap free-node                       ( mem-h )
   then                                         ( mem-h )
   r> dup if                                    ( io-n )
      dup node-range                            ( mem-n adr len )
      2dup pci-io-list free-memrange            ( mem-n adr len )
      drop swap free-node                       ( mem-h )
   then                                         ( mem-h io-h )
   0 0 2swap                                    ( mem-l io-l mem-h io-h )
;

[ifndef] PCIHOTPLUG?
\  If the "size" element of the I/O- or Memory- parameter-pair is zero,
\  the I/O or Memory resource will be aligned as given and the unused
\  resource will be "handed back to the parent".
\     
\  If "size" is non-zero, then drop the alignment and bypass the call
\  to the  align-resource-list  routine; instead, pass a node-pointer
\  of zero to the  free-resources  routine, so that it will bypass
\  the clause that "hands the resource back to the parent", which is
\  a behavior that may be required for hotplug-capable bridges.
\
\  The "io-n" and "mem-n" notations in the stack-diagrams refer to
\  nodes from the  pci-io-list  or  pci-memlist , respectively. 
\
: release-bridge-resources ( mem-aln mem-sz io-aln io-sz -- mem-l io-l mem-h io-h )
   if  						( mem-aln mem-sz io-aln )
      drop  0  					( mem-aln mem-sz 0 )
   else 					( mem-aln mem-sz )
      pci-io-list align-resource-list		( mem-aln mem-sz io-n )
   then						( mem-aln mem-sz io-n )
   -rot			 			( io-n mem-aln mem-sz )
   if 						( io-n mem-aln )
      drop 0 					( io-n 0 )
   else 					( io-n mem-aln )
      pci-memlist align-resource-list		( io-n mem-n )
   then						( io-n mem-n )
   swap free-resources				( io-l mem-l io-h io-h )
;

[else]
\ Extend bridge upper range.
\ upper-limit : bridge upper range
\ node        : last node in the bridge resource list
\ list        : bridge resource list
: extend-bridge-range ( upper-limit node list -- node )
  >r split-node					( prev next )
  2dup <> if  					( prev next )
     swap node-range r> free-memrange 		( next )
  else
     r> 2drop 					( prev )
  then
;
\  This is a hotplug enabled release resource routine. Here
\  if the "size" element of the I/O- or Memory- parameter-pair is zero,
\  the I/O or Memory resource will be aligned as given and the unused
\  resource will be "handed back to the parent".
\     
\  If "size" is non-zero, then that gives the upper limit
\  to which the bridge range needs to be extended to handle
\  hotplug resource requirement. For hotplug-capable bridges
\  "size" passed is non-zero. In this case, the upper address
\  range is extended to what is specified in "size" and the
\  rest of what is left is returned to the parent.
\
\  The "io-n" and "mem-n" notations in the stack-diagrams refer to
\  nodes from the  pci-io-list  or  pci-memlist , respectively. 
\
: release-bridge-resources ( mem-aln mem-sz io-aln io-sz -- mem-l io-l mem-h io-h )
   ?dup if					( mem-aln mem-sz io-aln io-sz )
      swap pci-io-list align-resource-list	( mem-aln mem-sz io-sz io-n )
      pci-io-list extend-bridge-range		( mem-aln mem-sz io-n' )
   else 					( mem-aln mem-sz io-aln )
      pci-io-list align-resource-list		( mem-aln mem-sz io-n )
   then						( mem-aln mem-sz io-n )
   -rot			 			( io-n mem-aln mem-sz )
   ?dup if					( io-n mem-aln mem-sz )
      swap pci-memlist align-resource-list	( io-n mem-sz mem-n )
      pci-memlist extend-bridge-range		( io-n mem-n' )
   else 					( io-n mem-aln )
      pci-memlist align-resource-list		( io-n mem-n )
   then						( io-n mem-n )
   swap free-resources				( io-l mem-l io-h io-h )
;
[then]

: get-dma-range ( -- dma-l dma-h )
   " virtual-dma" get-inherited-property 0=  if
      decode-int -rot decode-int nip nip        ( dma-l dma-size )
      over + 					( dma-l dma-h ) 
   else					 	( )  
      h# 8000.0000 dup h# 7fff.ffff +		( dma-l dma-h )
   then						( dma-l dma-h )
;

[ifndef] PCIHOTPLUG?
\  The behavior of this routine changes significantly with variations
\  in its parameters:
\
\  A non-zero  n  specifies the  acquire-bridge-resources  path.
\  This means:
\  (A)
\  A non-zero "size" element of the I/O- or Memory- parameter-pair
\  specifies the size of the I/O or Memory resource to acquire;
\  a zero "size" specifies acquiring the largest available piece
\  of the I/O or Memory resource.
\  (B)
\  The  bus#  returned should be one more than  current-bus#  at
\  the time this routine was entered, and  current-bus#  should
\  be incremented by  n  for the next time 'round.
\
\  An  n  of zero specifies the  release-bridge-resources  path.
\  This means:
\  (A)
\  The I/O- and Memory- parameter-pairs are passed directly to
\  the  release-bridge-resources  routine (which see).
\  (B)
\  The  bus#  returned should be  current-bus# , and  current-bus#
\  should remain unchanged.
\
: pci-allocate-bus# ( n m-aln m-sz io-aln io-sz -- ...... )
		      ( ..... -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   current-bus# >r		      ( n m-aln m-sz io-aln io-sz ) ( R: cbus )
   2>r 2>r 			      ( n ) ( R: cbus io-aln io-sz m-aln m-sz )
   ?dup if			      ( n ) ( R: cbus io-aln io-sz m-aln m-sz )
      current-bus# + to current-bus#  (  )  ( R: cbus io-aln io-sz m-aln m-sz )
      pci-memlist 2r> acquire-bridge-resources ( mem-n ) ( R: cb io-aln io-sz )
      pci-io-list 2r> acquire-bridge-resources ( mem-node io-node ) ( R: cbus )
      get-ranges		      ( mem-lo io-lo mem-hi io-hi ) ( R: cbus )
      r> 1+ >r			      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
   else				      (  )  ( R: bus# io-aln io-sz m-aln m-sz )
      2r> 2r>			      ( m-aln m-sz io-aln io-sz )   ( R: bus# )
      release-bridge-resources	      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
   then				      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
   get-dma-range	( mem-lo io-lo mem-hi io-hi dma-lo dma-hi ) ( R: bus# )
   2swap rot 		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi ) ( R: bus# )
   r>			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# ) ( R: )
;
[else]
\ This is a hotplug enabled allocation routine.
\ Here a non-zero  n  specifies the release-bridge-resource path.
\ if n = -1, it implies non hotplug bridge and hence all the resources
\            are returned to the parent node.
\ if n <> -1, then it implies the request is coming from a hotplug capable
\             bridge and "n" represents the minimum upper limit of the bus-range
\             for this bridge. Note that in this case mem-hi and io-hi 
\             represent the upper watermark for memory window and io space
\             window for this bridge.
\ 
\ A zero value of n specifies the allocate-bridge-resource path here.
\ And there is no change as compared to legacy code here. It still allocates
\ a large resource window for the bridge which is needed when pci code 
\ starts probing the children of the bridge.
\
: pci-allocate-bus# ( n m-aln m-sz io-aln io-sz -- ...... )
		      ( ..... -- mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# )
   current-bus# >r		      ( n m-aln m-sz io-aln io-sz ) ( R: cbus )
   2>r 2>r 			      ( n ) ( R: cbus io-aln io-sz m-aln m-sz )
   ?dup 0= if			      (  )  ( R: cbus io-aln io-sz m-aln m-sz )
      current-bus# 1+ to current-bus# (  )  ( R: cbus io-aln io-sz m-aln m-sz )
      pci-memlist 2r> acquire-bridge-resources ( mem-n ) ( R: cb io-aln io-sz )
      pci-io-list 2r> acquire-bridge-resources ( mem-node io-node ) ( R: cbus )
      get-ranges		      ( mem-lo io-lo mem-hi io-hi ) ( R: cbus )
      r> 1+ >r			      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
   else				      ( n ) ( R: bus# io-aln io-sz m-aln m-sz )
      2r> 2r>			      ( n m-aln m-sz io-aln io-sz ) ( R: bus# )
      release-bridge-resources	      ( n mem-lo io-lo mem-hi io-hi ) ( R: bus# )
      4 roll		              ( mem-lo io-lo mem-hi io-hi n ) ( R: bus# )	
      dup -1 = if		      ( mem-lo io-lo mem-hi io-hi n ) ( R: bus# )
	 drop			      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
      else			      ( mem-lo io-lo mem-hi io-hi n ) ( R: bus# )
	 \ if <> -1, then n is upper bus number for the hotplug capable bridge 
	 r> max dup >r is current-bus# ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
      then
   then				      ( mem-lo io-lo mem-hi io-hi ) ( R: bus# )
   get-dma-range	( mem-lo io-lo mem-hi io-hi dma-lo dma-hi ) ( R: bus# )
   2swap rot 		( mem-lo io-lo dma-lo mem-hi io-hi dma-hi ) ( R: bus# )
   r>			( mem-lo io-lo dma-lo mem-hi io-hi dma-hi bus# ) ( R: )
;
[then]

fload ${BP}/dev/pci/map.fth
fload ${BP}/dev/pci/unit.fth

