\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 1.2 02/03/12
purpose: 
copyright: Copyright 2000, 2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ common routines for debugging and common routines typically used by leaf
\ nodes.
\ 
headers

0 value usb-debug?

: le-w@  ( addr -- w )  dup c@ swap char+ c@ bwjoin  ;

: le-w!  ( w addr -- )  >r  wbsplit r@ char+ c!  r> c!  ;

: le-l@  ( addr -- l )  dup le-w@  swap wa1+ le-w@  wljoin  ;

: le-l!  ( l addr -- )  >r  lwsplit r@ wa1+ le-w!  r> le-w!  ;

: diag-crtype  ( addr len -- )
   usb-debug?  if  cr type  else  2drop  then
;

: dma-map-in  ( virt size cacheable? -- devadr )  " dma-map-in" $call-parent  ;

: dma-map-out  ( virt devadr size -- )		" dma-map-out" $call-parent  ;

: dma-sync  ( virt devadr size -- )		" dma-sync" $call-parent  ;
