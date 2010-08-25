\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: rootnexus.fth
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
id: @(#)rootnexus.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

root-device

   2 " #size-cells" integer-property
   2 " #address-cells" integer-property

   " sun4v" " compatible" string-property

   " sun4v" " device_type" string-property

   breakpoint-trap# h# 7f and " breakpoint-trap"  integer-property

   : open  ( -- true )  true  ;
   : close  ( -- )  ;

   : map-in  ( pa.lo pa.hi size -- virtual )
      >r lxjoin					( pa )
      dup 8 << 8 >>				( pa pa' )
      swap d# 56 >> h# c0 = if			( pa' )
         ." ERROR: cant map 4v cfg space" cr
         abort
      then					( pa )
      0 r>  memmap				( va )
   ;
   : map-out  ( virtual size -- )
      swap cif-release
   ;

   : encode-unit  ( pa.lo pa.hi -- adr,len )
      push-hex
      swap					( hi lo )
      <# ?dup if u#s drop ascii , hold then >r r@ h# fff.ffff and u#s
       r> d# 28 >> case
         h# 0 of  ascii m hold endof
         h# 8 of  ascii i hold endof
         h# c of               endof
	 ." ERROR: reserved bits set in address" cr -1 abort
      endcase u#>
      pop-base
   ;

   : decode-unit   ( adr len -- pa.lo pa.hi )
      over c@ case
         ascii i of 1 /string h# 8000.0000 endof
         ascii m of 1 /string 0 endof
         h# c000.0000 swap
      endcase >r
      ascii , left-parse-string parse-int >r parse-int r>
      r> +
   ;

device-end \ root device

fload ${BP}/arch/sun4v/cpu.fth
fload ${BP}/arch/sun4v/root-prober.fth
