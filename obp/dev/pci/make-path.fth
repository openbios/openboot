\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: make-path.fth
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
id: %Z%%M% %I% %E% %U%
purpose: %Y%
copyright: Copyright 2000-2002 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

h# 80 buffer: pci-path

\ I'm not sure if the userland interpreter can cope with the
\ package-to-path client-service; so just in case it cannot
\ I have implemented a recursive FCODE implementation.
\
\ Unless memory is an issue; use-cif? need not be defined.
\

[ifdef] use-cif?
defer package-to-path  0 " package-to-path" do-cif is package-to-path

: make-path$ ( -- ok? )
   pci-path 0 over c!				( buf )
   h# 7f over 1+				( buf len buf' )
   my-self ihandle>phandle			( buf len phandle )
   package-to-path				( buf len' )
   swap c!					( )
   true						( true )
;

[else]

: >path$ ( $adr,len -- )
   tuck pci-path count +		( len adr len buf-end-adr )
   swap move				( len )
   pci-path dup c@			( len buf-adr buf-old-len )
   rot + swap c!
;

: (assemble-path) ( -- )
   " name"           get-my-property if        exit  then	( namep,len )
   " reg"            get-my-property if  2drop exit  then
   " #address-cells"  my-parent ihandle>phandle get-package-property
   if  2 else  decode-int nip nip then
   dup >r 0 ?do					( namep,len regp,len )
      decode-int -rot				( namep,len ?? regp,len' )
   loop 2drop					( namep,len ?? )
   r> case
     2 of  swap  endof
     3 of  -rot swap  endof
   endcase					( namep,len pa.lo..pa.hi )
   " encode-unit" $call-parent			( namep,len unit$ )
   " /" >path$ 2swap decode-string >path$	( unit$ xdr,len )
   2drop " @" >path$ >path$ 			( )
;

: (fallback-make-path$) ( -- )
   recursive
   my-parent if
      my-self >r  my-parent  is  my-self
      (fallback-make-path$)  r> is my-self
      (assemble-path)
   then
;

: make-path$ ( -- ok? )
   0 pci-path c!  (fallback-make-path$)  true
;
[then]

: .path$ ( -- )  pci-path count type  ;

headerless
