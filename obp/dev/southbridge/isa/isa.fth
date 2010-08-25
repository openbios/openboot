\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: isa.fth
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
id: @(#)isa.fth 1.7 02/05/24
purpose: 
copyright: Copyright 1996-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

" isa" encode-string " name" property

2 encode-int " #address-cells" property
1 encode-int " #size-cells" property

external
: config-b@ ( offset -- b )  " config-b@" $call-parent  ;
: config-w@ ( offset -- w )  " config-w@" $call-parent  ;
: config-l@ ( offset -- l )  " config-l@" $call-parent  ;

: config-b! ( b offset -- )  " config-b!" $call-parent  ;
: config-w! ( w offset -- )  " config-w!" $call-parent  ;
: config-l! ( l offset -- )  " config-l!" $call-parent  ;

headers
: my-b@ ( offset -- b )  my-space or config-b@  ;
: my-w@ ( offset -- w )  my-space or config-w@  ;
: my-l@ ( offset -- l )  my-space or config-l@  ;

: my-b! ( b offset -- )  my-space or config-b!  ;
: my-w! ( w offset -- )  my-space or config-w!  ;
: my-l! ( l offset -- )  my-space or config-l!  ;

: en+  encode-int encode+  ;
: 0+       0 en+  ;

0 0 encode-bytes
my-space                 en+ 0+ 0+ 0+          0+
my-space h# 8100.0010 or en+ 0+ 0+ 0+ h#  1.0000 en+		\ IO
my-space h# 8200.0014 or en+ 0+ 0+ 0+ h# 10.0000 en+		\ 1meg memory
[ifdef] isa-flashprom?
my-space h# 8200.0018 or en+ 0+ h# f000.0000 en+ 0+ h# 10.0000 en+ \ flashprom
[then]
" reg" property

0 0 encode-bytes
0+ 0+ my-space h# 8100.0010 or en+ 0+ 0+ h#  1.0000 en+
1 en+ 0+ my-space h# 8200.0014 or en+ 0+ 0+ h# 10.0000 en+
[ifdef] isa-flashprom?
2 en+ 0+ my-space h# 8200.0018 or en+ 0+ h# f000.0000 en+ h# 10.0000 en+
[then]
" ranges" property

alias sb@ my-b@
alias sb! my-b!

external

\ Southbridge does not really have the base registers, se we
\ need to fake them.
: map-in ( pa.lo pa.hi len -- va )
   >r case						( lo )
      0  of  h# 10 h# 81 0 endof			( lo bar type off )
      1  of  h# 14 h# 82 0 endof			( lo bar type off )
      2  of  h# 18 h# 82 h# f000.0000 endof		( lo bar type off )
   endcase						( lo bar type off )
   >r d# 24 lshift					( lo bar type' )
   my-space or or					( lo hi )
   swap r> + 0 rot r>					( lo' 0 hi len )
   " map-in" $call-parent				( va )
;

: map-out ( va len -- )  " map-out" $call-parent  ;

: dma-alloc  ( n -- vaddr ) " dma-alloc" $call-parent  ;
: dma-free   ( vaddr n -- ) " dma-free"  $call-parent  ;

: dma-map-in   ( vaddr n cache? -- devaddr ) " dma-map-in"  $call-parent  ;
: dma-map-out  ( vaddr devaddr n -- )        " dma-map-out" $call-parent  ;

: dma-sync  ( vaddr devaddr n -- )
   " dma-sync" ['] $call-parent
   catch  if
      2drop 3drop	\ no parent dma-sync, and none needed
   then
;

: decode-unit  parse-2int  ;
: encode-unit ( l h -- ) swap <# u#s drop ascii , hold u#s u#>  ;
: open  ( -- ok? )  true  ;
: close ( -- )            ;

headers


