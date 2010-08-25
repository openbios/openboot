\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: machine-init.fth
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
id: @(#)machine-init.fth 1.2 06/03/21
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
0 1     0 0 hypercall: partition-exit
0 0	2 0 hypercall: partition-restart

chain: (reset-all
   partition-restart
;
' (reset-all is reset-all

headers
: power-off ( -- ) 0 partition-exit ;

headerless
: make-prop-from-pd ( name$ -- )
   2>r 2r@ -1 -1 pdget-prop ?dup if	( ptr )
      >r r@ pdentry-data@ r> pdentry-tag@ PROP_VAL = if
         encode-int
      else
         encode-string
      then
      2r@ property			( )
   then 2r> 2drop
;

: make-root-props ( -- )
   root-device
      " platform" 0 pdfind-node drop
      " stick-frequency" 2>r 2r@ PROP_VAL -1 pdget-prop pdentry-data@
      dup is system-tick-speed encode-int 2r> property
      " clock-frequency" make-prop-from-pd
      " name" make-prop-from-pd
      " banner-name" make-prop-from-pd
   device-end
;

stand-init: Build root-properties
   make-root-props
;
