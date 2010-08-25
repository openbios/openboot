\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dropin.fth
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
id: @(#)dropin.fth 1.3 01/04/06
purpose: 
copyright: Copyright 1994-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless

fload ${BP}/pkg/decompressor/data.fth
fload ${BP}/pkg/decompressor/sparc/decomp.fth
fload ${BP}/pkg/decompressor/decompress.fth

\ The format of a compressed dropin:
\ Dropin Header
\   4 bytes	magic-number	= COMP
\   4 bytes	size		= dropinhdr->size
\   4 bytes	comp-type
\   4 bytes	decomp-size

: dropin-compressed? ( header -- flag )
  \ Caution here..
  [ 0 to di-header ]
  dup [ di-size ] literal + l@		( header size )
  swap [  di-image ] literal +		( size data-ptr )
  dup l@ h# 434f4d50 =			( size data-ptr comp? )
  swap 4 + l@				( size comp? size )
  rot = and				( flag )
;

\
\ These two are the compressed dropin support entry points.
\
overload: (dropin>data) ( -- data,len )
   di-image di-size l@
   di-header dropin-compressed? if	( data len )
      [ also decompressor ]
      2dup do-decompress if		( data len data' len' )
         [ 0 to di-header ]		( data len data' len' )
         2swap 2drop			( data' len' )
         over /di-header - dup		( data' len' di-hdr di-hdr )
         di-header swap /di-header move	( data' len' di-hdr )
         h# 434f4d50 swap		( data' len' data di-hdr )
         [ di-exp ] literal + l!	( data' len' )
      then				( data len )
      [ previous ]
   then					( data len )
;

\ When the compressed data is copied into memory we also copy the dropin
\ header, the (dropin>data) routine will have marked the di-exp field
\ with the COMP flag so that this routine knows to release the memory that
\ the decompressed data is living in.
: (release-di-data) ( data len -- )
   [ 0 to di-header ]
   over [ /di-header di-exp - ] literal - l@ h# 434f4d50 = if
      [ also decompressor ]
      finish-decompress
      [ previous ]
   else
      2drop
   then 
;

' (dropin>data)		is dropin>data
' (release-di-data)	is release-di-data

