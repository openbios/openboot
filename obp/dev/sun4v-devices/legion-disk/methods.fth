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
id: @(#)methods.fth 1.1 06/02/16 
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
" block"     device-type

headerless
0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package
0 instance value deblocker

: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  to deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;
: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;

defer claim
defer release

: init-clientserv ( -- okay? )
   " /openprom/client-services" find-package if
      >r " claim" r@ find-method if
         to claim
         " release" r> find-method if
            to release true
         else
            r> drop false
         then
      else
         false
      then
   else
      false       
   then
;

: disk-read ( size raddr offset -- #bytes|errno error? ) -rot swap 3 2 h# f0 h# 80 htrap ;  
: disk-write ( size raddr offset -- #bytes|errno error? ) -rot swap 3 2 h# f1 h# 80 htrap ;

-1 h# 1fff - constant page#mask
h# 2000 constant mmu-pagesize

external

: block-size  ( -- n )  d# 512  ;

: dma-alloc   ( size -- vaddr )			mmu-pagesize swap 0 claim  ;
: dma-free    ( vaddr size -- )			swap  release  ;
: dma-sync    ( virt-addr dev-addr size -- )	3drop  ;
: dma-map-out ( vaddr devaddr n -- )            3drop  ;
: dma-map-in  ( vaddr size cache? -- devaddr )
   2drop			( vaddr )
   dup >physical drop   	( vaddr papage )
   swap page#mask invert and or	( pa )
;

headerless
: r/w-blocks ( addr block# #blocks read? -- #read/#written )
   over >r >r		( addr block# #blocks )    ( r: #blocks read? )
   block-size *    -rot	( size addr block# )       ( r: #blocks read? )
   block-size * >r	( size addr )              ( r: #blocks read? offset )
   2dup over true	( size addr size addr size cache? ) ( r: #blocks read? offset )
   dma-map-in		( size addr size devaddr )          ( r: #blocks read? offset )
   tuck r> r>  if	( size addr devaddr size devaddr offset ) ( r: #blocks )
      disk-read		( size addr devaddr #bytes|errno error? ) ( r: #blocks )
   else			( size addr devaddr size devaddr offset ) ( r: #blocks )
      disk-write	( size addr devaddr #bytes|errno error? ) ( r: #blocks )
   then  if		( size addr devaddr errno )		  ( r: #blocks )
      r> 2drop		( size addr devaddr 0 )
   else			( size addr devaddr #bytes )		  ( r: #blocks )
      r> drop		( size addr devaddr #read|#written )
   then			( size addr devaddr #read|#written )
   block-size / >r rot	( addr devaddr size ) ( r: #read|#written )
   3dup dma-sync	( addr devaddr size ) ( r: #read|#written )
   dma-map-out r>	( #read|#written )
;

external
\ These three methods are called by the deblocker.

: max-transfer  ( -- #bytes )  h# 8000 ;
: read-blocks   ( addr block# #blocks -- #read )     true  r/w-blocks  ;
: write-blocks  ( addr block# #blocks -- #written )  false r/w-blocks  ;

: #blocks  ( -- true | n false )  true  ;

: open  ( -- flag )
   init-clientserv 0=  if  false exit  then
   init-deblocker  0=  if  false exit  then

   init-label-package  0=  if
      deblocker close-package false exit
   then
   true
;

: close  ( -- )
   label-package close-package
   deblocker close-package
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: size  ( -- d.size )  " size" label-package $call-method  ;

headerless
