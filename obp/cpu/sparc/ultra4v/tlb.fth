\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tlb.fth
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
id: @(#)tlb.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: va>va,ctx ( vadr -- vadr ctx# )
   dup page#mask and swap  pagemask and
;

: demap-tlb  ( addr -- )
 3 0 rot demap-page drop
;

: demap-itlb  ( addr -- )
   2 0 rot demap-page drop
;
: demap-dtlb  ( addr -- )
   1 0 rot demap-page drop
;
: (.tte-soft1) ( tte -- )
   4 bits drop 2 bits .x drop
;
: (.tte-soft2) ( tte -- )
   d# 60 bits drop 2 bits .x drop
;

: itlb-tar-dir! ( tte vadr -- )
   2 -rot va>va,ctx swap  map-addr drop
;

: dtlb-tar-dir! ( tte vadr -- )
   1 -rot va>va,ctx swap  map-addr drop
;

: itlb-tar-data! ( tte index tlb# vadr -- )
   nip nip		( tte vadr )
   2 -rot va>va,ctx swap  map-perm-addr drop
;

: dtlb-tar-data! ( tte index tlb# vadr -- )
   nip nip		( tte vadr )
   1 -rot va>va,ctx swap  map-perm-addr drop
;

headers
defer .soft1 ( tte -- ) ' (.tte-soft1) is .soft1
defer .soft2 ( tte -- ) ' (.tte-soft2) is .soft2

: flush-tlb-page    ( vadr -- )
   pagesize round-down  demap-tlb
;

: flush-tlb-range ( vadr size -- )
   over +  pagesize round-up  swap pagesize round-down
   ?do  i demap-tlb  pagesize +loop
;

: flush-tlb-context ( -- )	\ XXX is this correct??? XXX
\   h# 40  dup demap-itlb demap-dtlb
;

: .tlb ( tlbdata -- )
   >r r@
   ." Size:"       3 bits .x
   1bits drop
   ." Soft1:"      2 bits drop r@ .soft1
   ." W:"          1bits .
   1bits drop
   ." P:"          1bits .
   ." CV:"         1bits .
   ." CP:"         1bits .
   ." E:"          1bits .
   ." IE:"         1bits .
   ." PA[39:13]:"  d# 27 bits dup .x
   ." PA:"         pageshift lshift .x cr
   ( reserved )    d# 20 bits drop
   ." Soft2:"      2 bits drop r@ .soft2
   ." NFO:"        1bits .
   ." V:"          1bits .
   r> 2drop
;

headerless
: is-ultra3+? ( ver -- flag )
   d# 32 >> dup h# ff and swap d# 8 >> h# ff00 and or  h# 3e15 =
;

: is-ultra4? ( ver -- flag )
   d# 32 >> dup h# ff and swap d# 8 >> h# ff00 and or  h# 3e18 =
;

: is-dtlb#3? ( ver -- flag )
   dup is-ultra3+? swap is-ultra4? or
;

: is-cmp? ( ver -- flag) is-ultra4? ;

: #dtlb-entries ( tlb# -- #tlb-entries )  drop d# 128  ;
: #itlb-entries ( tlb# -- #tlb-entries )  drop d# 128  ;

headers
