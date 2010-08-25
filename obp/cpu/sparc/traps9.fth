\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: traps9.fth
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
id: @(#)traps9.fth 1.4 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
code asi@ ( -- %asi )  tos sp  push   tos      rdasi c;
code asi! ( %asi -- )  tos 0   wrasi  sp  tos  pop   c;

code tpc@  ( -- adr )  tos sp  push   tos      rdtpc  c;
code tpc!  ( adr -- )  tos 0   wrtpc  sp  tos  pop    c;

code tnpc@  ( -- adr )  tos sp  push    tos     rdtnpc  c;
code tnpc!  ( adr -- )  tos 0   wrtnpc  sp tos  pop     c;

code tstate@  ( -- n )  tos sp  push      tos     rdtstate  c;
code tstate!  ( n -- )  tos 0   wrtstate  sp tos  pop       c;

code tt@  ( -- adr )  tos sp  push   tos     rdtt  c;
code tt!  ( adr -- )  tos 0   wrtt   sp tos  pop   c;

code tick@  ( -- adr )  tos sp  push    tos     rdtick  c;
code tick!  ( adr -- )  tos 0   wrtick  sp tos  pop     c;

code tba@  ( -- adr )  tos sp  push   tos     rdtba  c;
code tba!  ( adr -- )  tos 0   wrtba  sp tos  pop    c;

code pstate@  ( -- n )  tos sp  push      tos     rdpstate  c;
code pstate!  ( n -- )  tos 0   wrpstate  sp tos  pop       c;

code tl@  ( -- adr )  tos sp  push  tos     rdtl  c;
code tl!  ( adr -- )  tos 0   wrtl  sp tos  pop   c;

code pil@  ( -- n )  tos sp  push   tos     rdpil  c;
code pil!  ( n -- )  tos 0   wrpil  sp tos  pop    c;

code cwp@  ( -- n )  tos sp push  tos rdcwp  c;
code cwp!  ( n -- )  tos 0  wrcwp  sp tos pop  c;

code cansave@  ( -- n )  tos sp  push       tos     rdcansave  c;
code cansave!  ( n -- )  tos 0   wrcansave  sp tos  pop        c;

code canrestore@  ( -- n )  tos sp  push          tos     rdcanrestore  c;
code canrestore!  ( n -- )  tos 0   wrcanrestore  sp tos  pop           c;

code cleanwin@  ( -- n )  tos sp  push        tos     rdcleanwin  c;
code cleanwin!  ( n -- )  tos 0   wrcleanwin  sp tos  pop         c;

code otherwin@  ( -- n )  tos sp  push        tos     rdotherwin  c;
code otherwin!  ( n -- )  tos 0   wrotherwin  sp tos  pop         c;

code wstate@  ( -- n )  tos sp  push      tos     rdwstate  c;
code wstate!  ( n -- )  tos 0   wrwstate  sp tos  pop       c;

[ifndef] SUN4V
code ver@ ( -- n )  tos sp push  tos rdver  c;
[then]

code fprs@ ( -- n )  tos sp  push    tos     rdfprs  c;
code fprs! ( n -- )  tos 0   wrfprs  sp tos  pop     c;

code y@  ( -- n )  tos sp  push  tos     rdy  c;
code y!  ( n -- )  tos 0   wry   sp tos  pop  c;

code %i6!  ( n -- )  tos %i6  move  sp tos  pop  c;
code %i7!  ( n -- )  tos %i7  move  sp tos  pop  c;

code %o6!  ( n -- )  tos %o6 move  sp  tos  pop   c;
code %o6@  ( n -- )  tos sp  push  %o6 tos  move  c;

: vector-adr ( n -- vadr )  5 << tba@ +  ;
hex
: vector! ( vadr vector# -- )
   vector-adr  >r          ( handler ) ( r: trap-entry-adr )
   xlsplit                 ( handler-lo handler-hi )
   \ sethi %uhi(handler), %g2
   dup a >> 0500.0000 or  r@  0 la+ instruction!
   \ or    %g2, %ulo(handler), %g2
   3ff and  8410.a000 or  r@  1 la+ instruction!
   \ sethi %hi(handler), %g1
   dup a >> 0300.0000 or  r@  2 la+ instruction!
   \ sllx  %g2, 20, %g2
   8528.b020		  r@  3 la+ instruction!
   \ or    %g1, %g2, %g1
   8210.4002              r@  4 la+ instruction!
   \ or    %g1, %lo(handler), %g1
   3ff and 8210.6000 or   r@  5 la+ instruction!
   \ jmpl  %g1, 0, %g0
   81c0.6000              r@  6 la+ instruction!
   \ nop
   0100.0000              r>  7 la+ instruction!
;

: vector@ ( vector# -- vadr )
   vector-adr >r
   r@  0 la+ l@ a <<  n->l              ( uhi )
   r@  1 la+ l@ h# 3ff and or h# 20 <<  ( nhi )
   r@  2 la+ l@ a <<  n->l              ( nhi hi )
   r>  5 la+ l@ h# 3ff and  or          ( nhi nlo )
   swap lxjoin                          ( vadr )
;

: (lock[   ( -- )  pstate@ 2 invert and pstate! ;
: (]unlock ( -- )  pstate@ 2 or pstate!  ;
