\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: methods.fth
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
id: @(#)methods.fth 1.2 06/04/13
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

h# ff.ff00 constant pci-device-mask	\ pci device is   00000000.bbbbbbbb.dddddfff.00000000
h# fff     constant pci-reg-mask	\ pci register is 00000000.00000000.0000rrrr.rrrrrrrr

: config-@ ( phys.hi size -- data )
   dup rot dup pci-device-mask and swap		( size size pci-device phys.hi )
   phys.hi>cfg-offset pci-reg-mask and rot	( size pci-device offset size )
   pci-config-get 0<> if			( size data )
      drop					( size )
      \ 1 -> 0xff, 2 -> 0xffff, 4 -> 0xffff.ffff
      0 swap 8 * 0 do h# ff i << or 8 +loop	( data )
   else						( size data )
      nip					( data )
   then						( data )
;

: config-! ( data phys.hi size  -- ) 
   rot >r >r dup pci-device-mask and swap	( pci-device phys.hi )( R: data size )
   phys.hi>cfg-offset pci-reg-mask and r> r>	( pci-device offset size data )
   pci-config-put drop				(  )
;

fload ${BP}/dev/pci/preprober.fth

external

: config-b@ ( phys.hi -- b ) 1 config-@ ;
: config-b! ( b phys.hi -- ) 1 config-! ;
: config-w@ ( phys.hi -- w ) 2 config-@ ;
: config-w! ( w phys.hi -- ) 2 config-! ;
: config-l@ ( phys.hi -- l ) 4 config-@ ;
: config-l! ( l phys.hi -- ) 4 config-! ;

: decode-unit ( adr len -- phys.lo phys.mid phys.hi )
   pci-decode-unit lwsplit drop  my-pci-bus  wljoin
;

: encode-unit  ( phys.lo phys.mid phys.hi -- adr len ) pci-encode-unit ;

: map-in ( p.low p.mid p.hi len -- vaddr ) pci-map-in ;
: map-out ( va len -- ) " map-out" $call-parent ;

variable my-memlist  my-memlist off
variable my-io-list  my-io-list off

: allocate-bus# ( n mem-aln mem-sz io-aln io-sz -- . . . . . . . )
                      ( . . . . . -- mem-l io-l dma-l mem-h io-h dma-h bus# )
   pci-allocate-bus#
; 
: assign-int-line ( int phys.hi -- false )		2drop false  ;
: prober ( adr len -- )					pci-prober  ;
: prober-xt ( -- adr )					['] pci-prober  ;

: master-probe  ( -- )
   bar-struct-addr my-memlist @ my-io-list @		( reg mem io )
   set-pointers						( -- )
   setup-swapped-fcodes
[ifdef] PCIHOTPLUG?
      2dup preprober					( probe-list,adr )
[then]
   pci-master-probe
   make-available-property				( -- )
   get-pointers						( reg mem io )
   my-io-list ! my-memlist ! drop			( -- )
   restore-fcodes
;

: open true ;
: close ;

headerless
