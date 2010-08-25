\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fcode32.fth
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
id: @(#)fcode32.fth 1.14 04/08/13
purpose: 
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

code 2l->n ( l1 l2 -- x1 x2 )
   tos 0  tos   sra
   sp  0  scr   ldx
   scr 0  scr   sra
   scr    sp 0  stx
c;

: l-$number ( adr len -- true | n false )  swap n->l swap  $number ;

: l-move ( adr1 adr2 cnt -- )  rot n->l rot n->l rot n->l  move  ;
: l-fill ( adr cnt byte -- )  rot n->l rot n->l rot  fill  ;

: lcpeek ( adr -- { byte true } | false )  n->l  cpeek  ;
: lwpeek ( adr -- { byte true } | false )  n->l  wpeek  ;
: llpeek ( adr -- { byte true } | false )  n->l  lpeek  ;

: lcpoke ( byte adr -- ok? )  n->l  cpoke  ;
: lwpoke ( byte adr -- ok? )  n->l  wpoke  ;
: llpoke ( byte adr -- ok? )  n->l  lpoke  ;

: lb?branch  ( [ <mark ] -- [ >mark ] )

   \ New feature of IEEE 1275
   state @ 0=  if  ( flag )
      l->n  if  get-offset drop  else  skip-bytes  then
      exit
   then

   compile l->n

   get-offset 0<  if  ( )
      \ The get-backward-mark is needed in case of the following valid
      \ ANS Forth construct:    BEGIN  .. WHILE .. UNTIL .. THEN
      get-backward-mark  [compile] until
   else
      [compile] if
   then
; immediate

code l+! ( n addr -- )
      tos 0    tos  srl
      sp       scr  get
\dtc  tos      sc1  lget

\itc  tos 0    sc1  lduh
\itc  tos 2    sc2  lduh
\itc  sc1 10   sc1  sll
\itc  sc1 sc2  sc1  add
      bubble
      sc1 scr  sc1  add
\dtc   sc1      tos   lput
\itc   sc1  tos 2     sth
\itc   sc1 10   sc1   srl
\itc   sc1  tos 0     sth
   sp  1 /n*  tos  nget
   sp  2 /n*  sp   add
c;

code l>>a     ( n1 cnt -- n2 )
   sp       scr  pop
   scr tos  tos  sra
c;
code lrshift  ( n1 cnt -- n2 )
   sp  scr       pop
   scr tos  tos  srl
c;

: lb(of)     ( marks -- marks )
   drop-offset  +level compile 2l->n -level  [compile] of
; immediate
: lb(do)     ( -- )
   drop-offset  +level compile 2l->n -level  [compile]  do
; immediate
: lb(?do)    ( -- )
   drop-offset  +level compile 2l->n -level  [compile]  ?do
; immediate
: lb(+loop)  ( -- )
   drop-offset  +level compile l->n -level  [compile] +loop
; immediate

transient
also assembler definitions
: compare
   sp  scr  pop
   scr tos  cmp
;
: leaveflag  ( condition -- )
\ macro to assemble code to leave a flag on the stack
   if  ,%icc
   0  tos  move   \ Delay slot
      -1 tos move
   then
;
previous definitions
resident
warning @ warning off
\ Note: l0= and l= clash with the link defs in kernport.fth
code l0=  ( n -- f )  tos test  0=  leaveflag c;
code l0<> ( n -- f )  tos test  0<> leaveflag c;
code l0<  ( n -- f )  tos test  0<  leaveflag c;
code l0<= ( n -- f )  tos test  <=  leaveflag c;
code l0>  ( n -- f )  tos test  >   leaveflag c;
code l0>= ( n -- f )  tos test  0>= leaveflag c;

code l<   ( n1 n2 -- f )  compare <   leaveflag c;
code l>   ( n1 n2 -- f )  compare >   leaveflag c;
code l=   ( n1 n2 -- f )  compare 0=  leaveflag c;
code l<>  ( n1 n2 -- f )  compare <>  leaveflag c;
code lu>  ( n1 n2 -- f )  compare u>  leaveflag c;
code lu<= ( n1 n2 -- f )  compare u<= leaveflag c;
code lu<  ( n1 n2 -- f )  compare u<  leaveflag c;
code lu>= ( n1 n2 -- f )  compare u>= leaveflag c;
code l>=  ( n1 n2 -- f )  compare >=  leaveflag c;
code l<=  ( n1 n2 -- f )  compare <=  leaveflag c;
warning !

: l-between ( n1 n2 n3 -- flag )  >r over l<= swap r> l<= and  ;
: l-within  ( n1 n2 n3 -- flag )  over - >r - r> lu<  ;
: l-max     ( n1 n2 -- max )  2dup l< if  swap  then  drop  ;
: l-min     ( n1 n2 -- min )  2dup l> if  swap  then  drop  ;
: l-abs     ( n -- |n| )  dup l0< if  negate  then  ;

code l-@   ( addr -- n )
      tos 0    tos  srl
\dtc  tos 0     tos  ld
\itc  tos 2     scr  lduh   tos 0   tos  lduh
\itc  tos h# 10 tos  sll    scr tos tos  add
c;

code l-!   ( n addr -- )
    tos 0    tos  srl
    sp  0  scr  nget
\dtc   scr     tos 0   st
\itc   scr     tos 2  sth
\itc   scr 10  scr    srl
\itc   scr     tos 0  sth

   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;

code l2@  ( addr -- d )
    tos 0    tos  srl
    tos /n   sc1  lduh
    tos /n 2 +   scr  lduh  sc1 10   sc1  sll   scr sc1  sc1  add
    tos /n 4 +   scr  lduh  sc1 10   sc1  sllx  scr sc1  sc1  add
    tos /n 6 +   scr  lduh  sc1 10   sc1  sllx  scr sc1  scr  add

    scr      sp   push

    tos  0  sc1  lduh
    tos 2   scr  lduh  sc1 10   sc1  sll  scr sc1  sc1  add
    tos 4   scr  lduh  sc1 10   sc1  sllx  scr sc1  sc1  add
    tos 6   scr  lduh  sc1 10   sc1  sllx

    scr  sc1  tos  add
c;
code l2!  ( d addr -- )
    tos 0    tos  srl
    sp  0   scr    nget
    bubble

    scr   tos 6  sth  scr 10  scr  srlx
    scr   tos 4  sth  scr 10  scr  srlx
    scr   tos 2  sth  scr 10  scr  srl
    scr   tos 0  sth

    sp  /n  scr    nget

    bubble

    scr   tos /n 6 + sth  scr 10  scr  srlx
    scr   tos /n 4 + sth  scr 10  scr  srlx
    scr   tos /n 2 + sth  scr 10  scr  srl
    scr   tos /n 0 + sth

    sp  2 /n*   tos    nget
    sp  3 /n*   sp     add
c;

code ll@  ( addr -- l ) \ longword aligned
    tos 0    tos  srl
    tos tos lget
c;
code ll!  ( n addr -- )
    tos 0    tos  srl
    sp  0  scr  nget
    bubble
    scr   tos 0 st
    sp  1 /n*  tos  nget
    sp  2 /n*  sp   add
c;

code l<w@ ( addr -- w )
    tos 0  tos  srl
    tos 0  tos  ldsh
    tos 0  tos  sra
c;

code lw@  ( addr -- w ) \ 16-bit word aligned
    tos 0    tos  srl
    tos 0  tos  lduh
c;

code lw!  ( w addr -- )
   tos 0    tos  srl
   sp  0  scr  nget
   bubble
   scr   tos 0 sth
   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;

code lc@  ( addr -- c )
    tos 0    tos  srl
    tos 0  tos  ldub
c;
code lc!  ( c addr -- )
    tos 0    tos  srl
    sp  0  scr  nget
    bubble
    scr   tos 0 stb
    sp  1 /n*  tos  nget
    sp  2 /n*  sp   add
c;

code lon ( addr -- )
      tos  0 tos   srl
      -1   scr     move
\dtc  scr  tos 0   st
\itc  scr  tos 0   sth
\itc  scr  tos 2   sth
       sp  tos     pop
c;
code loff ( addr -- )
       tos  0 tos  srl
\dtc   %g0  tos 0  st
\itc   %g0  tos 0  sth
\itc   %g0  tos 2  sth
        sp  tos    pop
c;

: lbase  ( -- adr ) +level  compile base   compile la1+  -level  ; immediate
: l#out  ( -- adr ) +level  compile #out   compile la1+  -level  ; immediate
: l#line ( -- adr ) +level  compile #line  compile la1+  -level  ; immediate
: lspan  ( -- adr ) +level  compile span   compile la1+  -level  ; immediate

code lrl@  ( addr -- l ) \ longword aligned
    tos 0    tos  srl
    tos tos lget
c;
code lrl!  ( n addr -- )
    tos 0    tos  srl
    sp  0  scr  nget
    bubble
    scr   tos 0 st
    sp  1 /n*  tos  nget
    sp  2 /n*  sp   add
c;

code lrw@  ( addr -- w ) \ 16-bit word aligned
    tos 0    tos  srl
    tos 0  tos  lduh
c;

code lrw!  ( w addr -- )
   tos 0    tos  srl
   sp  0  scr  nget
   bubble
   scr   tos 0 sth
   sp 1 /n*  tos  nget
   sp 2 /n*  sp   add
c;

code lrb@  ( addr -- c )
    tos 0    tos  srl
    tos 0  tos  ldub
c;
code lrb!  ( c addr -- )
    tos 0    tos  srl
    sp  0  scr  nget
    bubble
    scr   tos 0 stb
    sp  1 /n*  tos  nget
    sp  2 /n*  sp   add
c;

transient
vocabulary fcode32
also fcode32 definitions

alias ,     l,
alias /n    /l
alias na+   la+
alias cell+ la1+
alias cells /l*
alias b?branch lb?branch
alias +!       l+!
alias >>a      l>>a
alias rshift   lrshift
alias b(of)    lb(of)
alias b(do)    lb(do)
alias b(?do)   lb(?do)
alias b(+loop) lb(+loop)
alias 0=       l0=
alias 0<>      l0<>
alias 0<       l0<
alias 0<=      l0<=
alias 0>       l0>
alias 0>=      l0>=
alias <        l<
alias >        l>
alias =        l=
alias <>       l<>
alias u>       lu>
alias u<=      lu<=
alias u<       lu<
alias u>=      lu>=
alias >=       l>=
alias <=       l<=
alias between  l-between
alias within   l-within
alias max      l-max
alias min      l-min
alias abs      l-abs
alias @        l-@
alias !        l-!
alias 2@       l2@
alias 2!       l2!
alias l@       ll@
alias l!       ll!
alias <w@      l<w@
alias w@       lw@
alias w!       lw!
alias c@       lc@
alias c!       lc!
alias on       lon
alias off      loff
alias base     lbase
alias #out     l#out
alias #line    l#line
alias span     lspan

alias rl!      lrl!
alias rl@      lrl@
alias rw!      lrw!
alias rw@      lrw@
alias rb!      lrb!
alias rb@      lrb@

alias $number  l-$number
alias move     l-move
alias fill     l-fill
alias cpeek    lcpeek
alias wpeek    lwpeek
alias lpeek    llpeek
alias cpoke    lcpoke
alias wpoke    lwpoke
alias lpoke    llpoke

previous definitions
resident

headerless
variable token-table0-64
variable token-table2-64
variable token-table0-32
variable token-table2-32

token-tables 0 ta+ token@ token-table0-64 token!
token-tables 0 ta+  !null-token

token-tables 2 ta+ token@ token-table2-64 token!
token-tables 2 ta+  !null-token

headers
also fcode32 definitions
fload ${BP}/pkg/fcode/primlist.fth		\ Codes for kernel primitives
fload ${BP}/pkg/fcode/sysprims-nofb.fth	\ Codes for system primitives
fload ${BP}/pkg/fcode/obsfcod2.fth
fload ${BP}/pkg/fcode/sysprm64.fth
fload ${BP}/pkg/fcode/regcodes.fth
previous definitions

token-tables 0 ta+ token@ token-table0-32 token!
token-tables 2 ta+ token@ token-table2-32 token!

headers
: fcode-32 ( -- )
   token-table0-32 token@ token-tables 0 ta+ token!
   token-table2-32 token@ token-tables 2 ta+ token!
;

: fcode-64 ( -- )
   token-table0-64 token@ token-tables 0 ta+ token!
   token-table2-64 token@ token-tables 2 ta+ token!
;

fcode-64

stand-init: Chose fcode32 mode
   fcode-32
;
