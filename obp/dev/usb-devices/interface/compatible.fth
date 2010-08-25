\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: compatible.fth
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
id: @(#)compatible.fth 1.3 99/09/16
purpose: 
copyright: Copyright 1998-1999 Sun Microsystems, Inc.  All Rights Reserved

\ XXX could use dma-alloc here, since it is only for probe time.
h# 1000 instance buffer: string1	\ XXX prototype size; not required to be instance

-1 instance value d-addr			\ not required to be instance
-1 instance value c-addr			\ "
-1 instance value i-addr			\ "

: int-class  ( -- int-class )  i-addr i-descript-class c@  ;

\ : #>$  ( n -- str len )  base @ >r  hex  (u.)  r> base !  ;
\ XXX hack for bad tokenizer that thinks (u.) is <# #s #>
: #>$  ( n -- str len )  base @ >r  hex  <# u#s u#>  r> base !  ;

: $save  ( str len addr -- addr len )	\ move string to addr
   swap 2dup  >r >r
   move
   r> r>
;

: append  ( addr1 len1 addr2 len2 -- addr1 len1+len2)	\ append to string1
   2over 2over 2swap + swap move
   nip +
;

: ,append  ( addr len1 -- addr len2 )			\ append ,
   " ," append
;

: #append  ( n addr len1 -- addr len2 )		\ append a number str.
   rot #>$ append
;
   
: .#append  ( n addr len1 -- addr len2 )	\ append . and number
   " ." append  #append
;

: string+  ( prop-adr,len string-adr,len -- prop-adr,len' )
   encode-string  encode+
;

: $.config  ( -- addr len )  " .config"  ;

: $,class  ( -- addr len )  " ,class"  ;

: $usbif  ( -- addr len )  " usbif"  ;

: dev4-#s  ( -- pid vid )
   d-addr d-descript-product le-w@
   d-addr d-descript-vendor le-w@
;

: dev2-#s  ( -- rev pid vid )
   d-addr d-descript-device le-w@
   dev4-#s
;

: dev1-#s  ( -- config-id rev pid vid )
   c-addr c-descript-config-id c@
   dev2-#s
;

: dev3-#s  ( -- config-id pid vid )
   c-addr c-descript-config-id c@
   dev4-#s
;

: int1-#s  ( -- int-id config-id rev pid vid )
   i-addr i-descript-interface-id c@
   dev1-#s
;

: #s>int-compat1  ( int-id config-id rev pid vid -- addr len )
   $usbif string1 $save
   #append
   ,append
   #append
   .#append
   $.config append
   #append
   .#append
;

: int2-#s  ( -- int-id config-id pid vid )
   i-addr i-descript-interface-id c@
   dev3-#s
;

: #s>int-compat2  ( int-id config-id pid vid -- addr len )
   $usbif string1 $save
   #append
   ,append
   #append
   $.config append
   #append
   .#append
;

: int5-#s  ( -- int-class vid )
   int-class
   d-addr d-descript-vendor le-w@
;

: #s>int-compat5  ( int-class vid -- addr len )
   $usbif string1 $save
   #append
   $,class append
   #append
;

: int4-#s  ( -- i-sub int-class vid )
   i-addr i-descript-sub c@
   int5-#s
;

: #s>int-compat4  ( i-sub int-class vid -- addr len )
   #s>int-compat5
   .#append
;

: int3-#s  ( -- i-prot i-sub int-class vid )
   i-addr i-descript-protocol c@
   int4-#s
;

: #s>int-compat3  ( i-prot i-sub int-class vid -- addr len )
   #s>int-compat4
   .#append
;

: int8-#s  ( -- int-class )
   int-class
;

: #s>int-compat8  ( int-class -- addr len )
   $usbif string1 $save
   $,class append
   #append
;

: int7-#s  ( -- i-sub int-class )
   i-addr i-descript-sub c@
   int8-#s
;

: #s>int-compat7  ( i-sub int-class -- addr len )
   #s>int-compat8
   .#append
;

: int6-#s  ( -- i-prot i-sub int-class )
   i-addr i-descript-protocol c@
   int7-#s
;

: #s>int-compat6  ( i-prot i-sub int-class -- addr len )
   #s>int-compat7
   .#append
;

\ For non-zero int-class:
: encode-int-class  ( prop-addr1 prop-len1 -- prop-addr2 prop-len2 )
   int3-#s #s>int-compat3 string+
   int4-#s #s>int-compat4 string+
   int5-#s #s>int-compat5 string+
   int6-#s #s>int-compat6 string+
   int7-#s #s>int-compat7 string+
   int8-#s #s>int-compat8 string+
;

: create-interface-compat
		( int-descrip-addr config-descrip-addr dev-descrip-addr -- )
   is d-addr  is c-addr  is i-addr
   int1-#s #s>int-compat1 encode-string
   int2-#s #s>int-compat2 string+
   int-class  if  encode-int-class  then
   " compatible" property
;
