\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: memprobe.fth
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
id: @(#)memprobe.fth 1.1 06/02/22
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

" /memory" find-device

: (free-range) ( xdr,len adr size  -- xdr,len' )
   over bytes>pages hi-memory-base @
   h# 3ff invert and <>  if			( xdr,len adr,size )
      2dup obmem swap				( xdr,len adr,size lo hi size )
      phys-adr,len>pages			( xdr,len adr,size pg# #pgs )
      physavail  free-memrange			( xdr,len adr,size )
   then						( xdr,len adr,size )
   >r xlsplit swap >r encode-int encode+  r> encode-int encode+
   r> xlsplit swap >r encode-int encode+  r> encode-int encode+
;

headers
\ Track the upper memory address available; we do this so the
\ memory? is efficient - the address shifting trick does not work.
\
: probe-memory ( -- )
   0 0 encode-bytes					( xdr,len )
   0							( xdr,len node )
   begin
      >r " mblock" r> pdfind-node ?dup while		( xdr,len ptr )
         >r " base" PROP_VAL r@ pdget-prop ?dup if	( xdr,len propt )
            pdentry-data@				( xdr,len adr )
            " size" PROP_VAL r@ pdget-prop ?dup if	( xdr,len adr propt )
               pdentry-data@				( xdr,len adr len )
	       2dup + physmax  2dup @ > if  2drop else ! then
	       (free-range)				( xdr',len' )
	    else					( xdr,len adr )
	       drop					( xdr,len )
	    then					( xdr,len )
	 then						( xdr,len )
         r> pdentry-data@				( xdr,len ptr )
   repeat						( xdr,len )
   " reg" property
;
device-end

stand-init: Build memory nodes
   " probe-memory" memory-node @ $call-method
;
