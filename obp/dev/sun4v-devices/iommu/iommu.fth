\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: iommu.fth
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
id: @(#)iommu.fth 1.2 06/03/17
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

my-space h# fff.ffff and constant devhandle
0 constant tsbnum

1 constant pci-map-attr-read
2 constant pci-map-attr-write
pci-map-attr-read pci-map-attr-write or 
constant io-attributes

h# b0 constant iommu-map-fun
h# b1 constant iommu-demap-fun
h# b2 constant iommu-getmap-fun
h# b3 constant iommu-getbypass-fun
h# b4 constant config-get-fun
h# b5 constant config-put-fun
h# b8 constant dma-sync-fun

h# 80 constant fast-trap#

1 constant pci-map-attr-read
2 constant pci-map-attr-write
pci-map-attr-read pci-map-attr-write or constant pci-map-attr

1 constant pci-sync-device
2 constant pci-sync-cpu
pci-sync-device pci-sync-cpu or constant pci-sync

variable dma-list	dma-list off
virtual-dma-addr virtual-dma-size dma-list free-memrange

    1 constant ENOCUP
    2 constant ENORADDR
    3 constant EOINTR
    4 constant EBADPGSZ
    5 constant EBADTSB
    6 constant EINVAL
    7 constant EBADTRAP
    8 constant EBADALIGN
    9 constant EWOULDBLOCK
d# 10 constant ENOACCESS
d# 11 constant EIO
d# 12 constant ECPUERROR
d# 13 constant ENOTSUPPORTED
d# 14 constant ENOMAP
d# 15 constant ETOOMANY

: fast-trap ( ??? #in #out fun# -- ??? )
   dup >r fast-trap# htrap		( ??? status )( R: fun# )
   r> swap				( ??? fun# status )
   ?dup if				( ??? fun# status| )
      cmn-error[
      case
         ENOCUP		of " ENOCUP" endof
         ENORADDR	of " Invalid real address" endof
         EOINTR		of " EOINTR" endof
         EBADPGSZ	of " EBADPGSZ" endof
         EBADTSB	of " EBADTSB" endof
         EINVAL 	of " Invalid hypervisor argument(s)" endof
         EBADTRAP	of " EBADTRAP" endof
         EBADALIGN 	of " Improperly aligned address" endof
         EWOULDBLOCK	of " EWOULDBLOCK" endof
         ENOACCESS	of " Access to real address offset not permitted" endof
         EIO		of " EIO" endof
         ECPUERROR	of " ECPUERROR" endof
         ENOTSUPPORTED	of " Hypervisor function not supported" endof
         ENOMAP		of " ENOMAP" endof
         ETOOMANY	of " ETOOMANY" endof
         " Invalid Hypervisor error code" rot
      endcase
      rot " %s. function: %x" ]cmn-end
   else					( ??? fun# )
      drop				( ??? )
   then					( ??? )
;

headers

: pci-config-get ( pci-device pci-config-offset size -- data error-flag )
   >r >r >r devhandle r> r> r> 			( devhandle pci-device pci-config-offset size )
   4 3 config-get-fun fast-trap			( data error-flag )
;

: pci-config-put ( pci-device pci-config-offset size data -- error-flag )
   >r >r >r >r devhandle r> r> r> r>		( devhandle pci-device pci-config-offset size data )
   5 2 config-put-fun fast-trap			( error-flag )
;

: pci-iommu-getmap ( tsbindex -- raddr io-attributes )
   devhandle swap 2 3 iommu-getmap-fun fast-trap
;

: (pci-iommu-map) ( tsbid #ttes io-page-list-p -- #ttes-actual ) 
   >r >r >r devhandle r> r> pci-map-attr r>	( dev tsbid #ttes io-attributes io-page-list-p )
   5 2 iommu-map-fun fast-trap			( #ttes-actual )	
;

: pci-iommu-map ( tsbindex #ttes io-page-list-p -- )
   begin				( tsbindex #ttes io-page-list-p )
      over >r 3dup (pci-iommu-map) r>	( tsbindex #ttes io-page-list-p #ttes-actual #ttes )
      over <>				( tsbindex #ttes io-page-list-p #ttes-actual more? )
   while      				( tsbindex #ttes io-page-list-p #ttes-actual )
      tuck /x * + >r	( tsbindex #ttes #ttes-actual )( R: io-page-list-p' )
      tuck - >r				( tsbindex #ttes-actual )( R: io-page-list-p' #ttes' )
      + r> r>				( tsbindex' #ttes' io-page-list-p' )( R: )
   repeat				( tsbindex' #ttes' io-page-list-p' )
   2drop 2drop				(  )
;

: (pci-iommu-demap) ( tsbindex #ttes -- #ttes-actual ) 
   >r >r devhandle r> r>			( dev tsbindex #ttes )
   3 2 iommu-demap-fun fast-trap	( #ttes-actual )
;

: pci-iommu-demap ( tsbindex #ttes -- )
   begin				( tsbindex #ttes )
      2dup (pci-iommu-demap) 2dup <>	( tsbindex #ttes #ttes-actual more? )
   while				( tsbindex #ttes #ttes-actual )
      tuck - -rot + swap		( tsbindex' #ttes' )
   repeat				( tsbindex' #ttes' )
   3drop
;

: (pci-dma-sync) ( raddr size io-sync-direction  -- #synced ) 
   >r devhandle -rot r>			( dev raddr size io-sync-direction )
   4 2 dma-sync-fun fast-trap		( #synced )
;

: pci-dma-sync ( raddr size -- )
   2dup >r >r					( raddr size ) ( R: raddr size )
   begin					( raddr size )
      2dup pci-sync-cpu (pci-dma-sync) 2dup <>	( raddr size #synced more? )
   while					( raddr size #synced )
      tuck - -rot + swap			( raddr' size' )
   repeat					( raddr' size' )
   3drop					( )

   r> r>					( raddr size )
   begin					( raddr size )
      2dup pci-sync-device (pci-dma-sync) 2dup <> ( raddr size #synced more? )
   while					( raddr size #synced )
      tuck - -rot + swap			( raddr' size' )
   repeat					( raddr' size' )
   3drop					( )
;

: setup-io-page-list ( raddr io-page-list #ttes -- )   
   0 ?do			        ( raddr io-page-list )
      2dup x! /x + swap			( io-page-list' raddr )
      mmu-pagesize + swap		( raddr' io-page-list' )
   loop					( raddr' io-page-list' )
   2drop 				( )
;

external

: dma-alloc ( size -- vaddr ) mmu-pagesize swap 0 claim  ;
: dma-free  ( vaddr size -- ) swap  release  ;

: dma-sync  ( virt-addr dev-addr size -- )
   rot >physical drop swap			( dev-addr raddr size)
   pci-dma-sync					( dev-addr )
   drop
;

: dma-map-in ( virt size cache? -- dma-virt )
   drop mmu-pagesize round-up		( virt size' )
   mmu-pagesize over dma-list		( virt size align size list )
   allocate-memrange throw dup >r 	( virt size dma-virt )( R: dma-virt )
   virtual-dma-base dup and32 - 	( virt size offset )
   mmu-pagesize / -rot			( tsbindex virt size )
   mmu-pagesize / tuck tuck /x *	( tsbindex #ttes #ttes virt /io-page-list )
   >r r@ /x swap 0 claim		( tsbindex #ttes #ttes virt io-page-list )( R: dma-virt /io-page-list )
   dup >r swap				( tsbindex #ttes #ttes io-page-list virt )( R: dma-virt /io-page-list io-page-list )
   >physical drop			( tsbindex #ttes #ttes io-page-list raddr )
   swap rot setup-io-page-list		( tsbindex #ttes )
   r@ >physical drop			( tsbindex #ttes io-page-list-p )( R: dma-virt /io-page-list io-page-list )
   pci-iommu-map r> r> 			( io-page-list /io-page-list )( R: dma-virt )
   swap release r>			( dma-virt )( R: )
;

: dma-map-out ( virt dma-virt size -- )
   mmu-pagesize round-up		( virt devadr size' )
   2dup dma-list free-memrange		( virt devadr size' )
   mmu-pagesize / swap			( virt #ttes devadr )
   virtual-dma-base dup and32 -		( virt #ttes offset )
   mmu-pagesize / swap			( virt tsbindex #ttes )
   pci-iommu-demap drop			(  )
;

headers

: dma-mapped? ( dma-virt -- raddr )
   virtual-dma-base dup and32 -		( offset )
   mmu-pagesize /			( tsbindex )
   pci-iommu-getmap			( raddr attributes )
   ." attributes: 0x" .h cr		( raddr )
   ." raddr: 0x" .h 			(  )
;

headerless
