\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadfcod.fth
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
id: @(#)loadfcod.fth 2.20 06/02/07
purpose: Load file for FCode interpreter
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Load file for FCode interpreter
headers
start-module

fload ${BP}/pkg/fcode/applcode.fth		\ Miscellaneous stuff
fload ${BP}/pkg/fcode/memtest.fth		\ Generic memory test
fload ${BP}/pkg/fcode/common.fth		\ Basic FCode parsing

init-tables

fload ${BP}/pkg/fcode/byteload.fth		\ The compiler loop
	\ Compiling and defining words

fload ${BP}/pkg/fcode/spectok.fth		\ Control structures

fload ${BP}/pkg/fcode/probepkg.fth		\ Probe for FCode packages

fload ${BP}/pkg/fcode/comptokt.fth

fload ${BP}/pkg/fcode/primlist.fth		\ Codes for kernel primitives
fload ${BP}/pkg/fcode/sysprims-nofb.fth		\ Codes for system primitives
64\ fload ${BP}/pkg/fcode/sysprm64.fth		\ Codes for 64-bit system primitives
fload ${BP}/pkg/fcode/vfcodes.fth		\ Common sun vfcodes 

headerless
\ ram-fcode moves the table of FCode tables into RAM.  It is not used
\ in systems where the entire Forth dictionary is always in RAM.
: ram-fcode  ( -- )
   instance-mode off
   token-tables-ptr token@   ( prom-table-ptr )
   init-tables               ( prom-table-ptr )
   token-tables-ptr token@   ( prom-table-ptr ram-table-ptr )
   #token-tables /token *  move   \ Copy old to new
;
end-module

headers
