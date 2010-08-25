\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fontdi.fth
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
\ id: @(#)fontdi.fth 1.4 01/04/06
\ purpose: 
\ copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved
\
\ Support for drop in font code
\ 
\ a drop in font looks like:
\   High address:
\
\      font-data    (size)	 bytes of font data
\      default-font (16 bytes)	 Null-terminated string
\      Reserved	    (4 bytes)	 reserved for future extension - must be 0
\      Checksum	    (4 bytes)	 32-bit sum of image bytes
\      Image size   (4 bytes)	 size in bytes of image
\      Magic Number (4 bytes)	 "OBMD"
\      Sync bytes   (1-3 bytes)	 Enough 0x01 bytes to align the Magic Number
\				 on a 4-byte boundary.
\
\   Low address:

headerless
0 value (romfont)
: (install-font) " fonts" do-drop-in (romfont) ;
['] (install-font) is romfont

\ The idea behind this is: The first call that requires a font
\ causes the dropin to load, then after that only the address of the
\ loaded font is returned.
\
\ This save us memory when nobody is using a display device.
\
tail-chain: execute-buffer  ( adr len -- )
   over 4 " font" $= if			( addr len )
     dup alloc-mem dup to (romfont)	( adr len vadr )
     ['] (romfont) is romfont		( -- )
     swap move				( -- )
     exit
   then
tail;

