id: @(#)pcinode.fth 1.7 05/10/12
purpose: PCI bridge probe code
copyright: Copyright 1994 Firmworks  All Rights Reserved
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


hex
headerless

" pci"						device-name
pci-express?  if  " pciex"  else  " pci"  then	device-type

2 encode-int " #size-cells" property
3 encode-int " #address-cells" property

0 value my-bus#

defer parent-decode-unit

external
: allocate-bus#  ( n -- bus# mem-lo io-low mem-hi io-high )
   " allocate-bus#" $call-parent
;
: decode-unit  ( adr len -- phys.lo..hi )
   parent-decode-unit lwsplit drop  my-bus# wljoin
;
defer encode-unit  ( phys.lo..hi -- adr len )

\
\ This routine allows allocation of resources from the current IO/MEM lists.
\
: resource-alloc ( physhi align size -- addr|0 )
   " resource-alloc" $call-parent
;

\ This routine returns a range to the relevant list.
\ Be CAREFUL no checking is done to verify that an allocation from one
\ pool is not returned to the other, nor that you are freeing more than
\ you alloc'd.
: resource-free ( physhi addr len -- )
   " resource-free" $call-parent
;

\ decode-unit and encode-unit must be static methods, so they can't use
\ $call-parent at run-time

" decode-unit" my-parent ihandle>phandle find-method drop  ( xt )
to parent-decode-unit

" encode-unit" my-parent ihandle>phandle find-method drop  ( xt )
to encode-unit

: prober-xt    ( -- xt )                         " prober-xt"   $call-parent  ;

: assign-int-line  ( phys.hi.func int-pin -- false | irq true )
   nip my-space swap " assign-int-line"   $call-parent
;

: dma-alloc    ( size -- vaddr )                 " dma-alloc"   $call-parent  ;
: dma-free     ( vaddr size -- )                 " dma-free"    $call-parent  ;
: dma-map-in   ( vaddr size cache? -- devaddr )  " dma-map-in"  $call-parent  ;
: dma-map-out  ( vaddr devaddr size -- )         " dma-map-out" $call-parent  ;
: dma-sync     ( virt-addr dev-addr size -- )    " dma-sync" 	$call-parent  ;

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

headerless
