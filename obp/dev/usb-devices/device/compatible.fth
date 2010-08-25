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
id: @(#)compatible.fth 1.3 99/01/29
purpose: 
copyright: Copyright 1998 Sun Microsystems, Inc.  All Rights Reserved

\ XXX can use dma-alloc, since this is only for probe time.
h# 1000 buffer: string1			\ XXX prototype size

-1 value d-addr
-1 value c-addr

: dev-class  ( -- dev-class )  d-addr d-descript-class c@  ;

: multi-config?  ( -- multi-config? )  d-addr d-descript-#configs c@  1 <>  ;

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

: $usb  ( -- addr len )  " usb"  ;

: $.config  ( -- addr len )  " .config"  ;

: $,class  ( -- addr len )  " ,class"  ;

: dev4-#s  ( -- pid vid )
   d-addr d-descript-product le-w@
   d-addr d-descript-vendor le-w@
;

: #s>dev-compat4  ( pid vid -- addr len )		\ text string
   $usb string1 $save
   #append
   ,append
   #append
;

: dev2-#s  ( -- rev pid vid )
   d-addr d-descript-device le-w@
   dev4-#s
;

: #s>dev-compat2  ( rev pid vid -- addr len )
   #s>dev-compat4
   .#append
;

: dev1-#s  ( -- config-id rev pid vid )
   c-addr c-descript-config-id c@
   dev2-#s
;

: #s>dev-compat1  ( config-id rev pid vid -- addr len )
   #s>dev-compat2
   $.config append
   #append
;

: dev3-#s  ( -- config-id pid vid )
   c-addr c-descript-config-id c@
   dev4-#s
;

: #s>dev-compat3  ( config-id pid vid -- addr len )
   #s>dev-compat4
   $.config append
   #append
;

: dev7-#s  ( -- dev-class vid )
   dev-class
   d-addr d-descript-vendor le-w@
;

: #s>dev-compat7  ( dev-class vid -- addr len )
   $usb string1 $save
   #append
   $,class append
   #append
;

: dev6-#s  ( -- dev-sub dev-class vid )
   d-addr d-descript-sub c@
   dev7-#s
;

: #s>dev-compat6  ( dev-sub dev-class vid -- addr len )
   #s>dev-compat7
   .#append
;

: dev5-#s  ( -- dev-prot dev-sub dev-class vid )
   d-addr d-descript-protocol c@
   dev6-#s
;

: #s>dev-compat5  ( dev-prot dev-sub dev-class vid -- addr len )
   #s>dev-compat6
   .#append
;

: dev10-#s  ( -- dev-class )
   dev-class
;

: #s>dev-compat10  ( dev-class -- addr len )
   $usb string1 $save
   $,class append
   #append
;

: dev9-#s  ( -- dev-sub dev-class )
   d-addr d-descript-sub c@
   dev10-#s
;

: #s>dev-compat9  ( dev-sub dev-class -- addr len )
   #s>dev-compat10
   .#append
;

: dev8-#s  ( -- dev-prot dev-sub dev-class )
   d-addr d-descript-protocol c@
   dev9-#s
;

: #s>dev-compat8  ( dev-prot dev-sub dev-class -- addr len )
   #s>dev-compat9
   .#append
;

: dev-compat11  ( -- addr len )
   " usb,device"
;

\ For non-zero dev-class
: encode-dev-class  ( prop-addr1 prop-len1 -- prop-addr2 prop-len2 )
   dev5-#s #s>dev-compat5 string+
   dev6-#s #s>dev-compat6 string+
   dev7-#s #s>dev-compat7 string+
   dev8-#s #s>dev-compat8 string+
   dev9-#s #s>dev-compat9 string+
   dev10-#s #s>dev-compat10 string+
;

: create-device-compat  ( config-descrip-addr dev-descrip-addr  -- )
   is d-addr  is c-addr
   multi-config?  if
      dev1-#s #s>dev-compat1 encode-string
      dev2-#s #s>dev-compat2 string+
   else
      dev2-#s #s>dev-compat2 encode-string
   then
   multi-config?  if
      dev3-#s #s>dev-compat3 string+
   then
   dev4-#s #s>dev-compat4 string+
   dev-class  if  encode-dev-class  then
   dev-compat11 string+
   " compatible" property
;
