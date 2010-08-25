\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: range.fth
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
id: @(#)range.fth 1.2 02/04/24
purpose: 
copyright: Copyright 1999-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
\ Utility routine to avoid always saying encode-int encode+
: ei+ ( propaddr proplen int -- propaddr proplen ) encode-int encode+ ;
: 0+ ( propaddr proplen 0 -- propaddr proplen ) 0 ei+ ;

\  Encode an X-integer as X.hi X.lo
: ex+ ( propaddr proplen X  -- propaddr proplen )
   xlsplit swap >r  ei+  r>  ei+
;

: encode-range ( prop-adr,len type base sizeX -- prop-adr,len )
   dup xlsplit or if		  ( prop-adr,len type base sizeX )
      >r >r			  ( prop-adr,len type ) ( R: sizeX base )

      \  Convert type to PCI-style "space"
      d# 24 << 1 d# 31 << or	  ( prop-adr,len type-space ) ( R: sizeX base )

      \  Stash a copy for later
      dup 2swap rot		  ( type-space prop-adr,len type-space )

      \  Encode type-space
      ei+			  ( type-space prop-adr,len ) ( R: sizeX base )

      \  Encode Base.hi,lo
      r@ ex+			  ( type prop-adr,len )       ( R: sizeX base )

      \  Encode space
      rot ei+			  ( prop-adr,len )	      ( R: sizeX base )

      \  Encode Base.hi,lo
      r> ex+			  ( prop-adr,len )	      ( R: sizeX )

      \  Encode Size.hi,lo = 0
      r> ex+			  ( prop-adr,len )
   else 			  ( prop-adr,len type base )
      drop 2drop		  ( prop-adr,len )
   then 			  ( prop-adr,len )
;
