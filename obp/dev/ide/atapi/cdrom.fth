\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cdrom.fth
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
id: @(#)cdrom.fth 1.9 01/05/29
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless

" cdrom"	name
" block"	device-type

fload ${BP}/dev/ide/atapi/misc.fth

hex
0 instance value offset-low
0 instance value offset-high
0 instance value label-package
0 instance value blocksize

: init-label-package  ( -- okay? )
   0 is offset-high  0 is offset-low
   my-args  " disk-label"  $open-package is label-package
   label-package  if
      0 0  " offset" label-package $call-method  is offset-high is offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;

0 instance value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  is deblocker
   deblocker  if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

: .bail? ( flag -- ) 0= if r> drop false then ;

: set-block-size ( n -- )
   dup is blocksize
   " disk-block-size" $call-parent
;

external

: dma-alloc ( #bytes -- vaddr ) " dma-alloc" $call-parent ;
: dma-free  ( vaddr #bytes -- ) " dma-free" $call-parent ;

: block-size ( -- n ) blocksize ;
: max-transfer ( -- n ) blocksize h# 20 * ;

\
\ this routine expects to never be called with #blocks > 256
\ (ie zero into the sector count reg)
\
headers
: atapi-r/w-blocks ( adr block# #blocks read? -- #blocks )
   if   h# a8  else  h# aa then		( adr block# #blocks cmd )
   atapi-cmd >r				( adr block# #blocks )
   r@ erase-cdb				( adr block# #blocks )
   r@ c!				( adr block# #blocks )
   r@ 6 + long>cdb			( adr block# )
   r@ 2 + long>cdb			( adr )
   r> d# 30.000				( adr cdb timeout )
   atapi-pkt set-pkt-data		( pkt )
   run-atapi if				( -- )
      0					( 0 )
   else					( -- )
      atapi-pkt >transfer-bytes l@	( bytes )
      blocksize /			( #blocks )
   then					( #blocks )
;

external

: read-blocks  ( adr block# #blocks -- #rd )  true  atapi-r/w-blocks ;
: write-blocks  ( adr block# #blocks -- #wr ) false atapi-r/w-blocks ;

: open  ( -- flag )
  my-unit dup rot 				( target target lun )
  " set-address" $call-parent .bail?		( target )
  h# 800 set-block-size				( target )
  " device-present?" $call-parent .bail?	( -- )
  init-deblocker .bail?				( -- )
  init-label-package  .bail?			( -- )	
  true						( true )
;

: seek  ( offset.low offset.high -- okay? )
  offset-low offset-high  d+  " seek"   deblocker $call-method
;
: read  ( adr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( adr len -- actual-len )  " write" deblocker $call-method  ;

: load  ( adr -- size )            " load"  label-package $call-method  ;

: close  ( -- )   
   label-package close-package  0 is label-package
   deblocker close-package  0 is deblocker
;

