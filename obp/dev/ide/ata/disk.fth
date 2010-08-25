\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: disk.fth
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
id: @(#)disk.fth 1.11 98/05/05
purpose: 
copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

headerless

" disk"		name
" block"	device-type

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

/xfer-pkt	instance buffer: ata-pkt
d# 12		instance buffer: ata-cmd

: do-ata ( buffer cdb timeout -- fail? )
   ata-pkt set-pkt-data			( pkt )
   0 over >xfer-type l!			( pkt )
   " run-command" $call-parent		( fail? )
;

: dataless-cmd ( cmd -- )   0 swap ata-cmd tuck c! d# 10000 do-ata  ;

: set-block-size ( n -- )
   dup is blocksize
   " disk-block-size" $call-parent
;

external

: spin-up ( -- )	h# E1 dataless-cmd drop ;
: spin-down ( -- )	h# E0 dataless-cmd drop ;
: dma-alloc ( #bytes -- vaddr ) " dma-alloc" $call-parent ;
: dma-free  ( vaddr #bytes -- ) " dma-free" $call-parent ;

: block-size ( -- n ) blocksize ;
: max-transfer ( -- n ) blocksize h# 40 * ;

headerless
\
\ this routine expects to never be called with #blocks > 256
\ (ie zero into the sector count reg)
\

: disk-r/w-blocks ( adr block# #blocks read? -- #blocks )
  if  h# 21  else  h# 31   then		( adr block# #blocks cmd )
  ata-cmd >cmd-byte c!			( adr block# #blocks )
  ata-cmd >#blocks c!			( adr block# )
  ata-cmd >block#  l!			( adr )
  ata-cmd d# 2000			( adr cdb timeout )
  do-ata if false exit then		( -- )
  ata-pkt >transfer-bytes l@		( #bytes )
  blocksize /				( #blocks )
;

: .bail? ( flag -- ) 0= if r> drop false then ;

external

: read-blocks  ( adr block# #blocks -- #rd )  true  disk-r/w-blocks ;
: write-blocks  ( adr block# #blocks -- #wr ) false disk-r/w-blocks ;

: open  ( -- flag )
  my-unit dup rot				( target target lun )
  " set-address" $call-parent .bail?		( target )
  h# 200 set-block-size				( target )
  " device-present?" $call-parent .bail?	( -- )
  spin-up					( -- )
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


