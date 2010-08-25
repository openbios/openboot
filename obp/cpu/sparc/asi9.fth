\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: asi9.fth
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
id: @(#)asi9.fth 1.3 95/05/09
purpose:
copyright: Copyright 1993-1994 Sun Microsystems, Inc.  All Rights Reserved

headers
code spacec@ ( adr asi -- byte )
   sc4             rdasi
   sp         scr  pop
   tos 0           wrasi
   #Sync           membar
   scr 0 %asi tos  lduba
   #Sync           membar
   sc4 0           wrasi
c;
code spacew@ ( adr asi -- word )
   sc4             rdasi
   sp         scr  pop
   tos 0           wrasi
   #Sync           membar
   scr 0 %asi tos  lduha
   #Sync           membar
   sc4 0           wrasi
c;
code spacel@ ( adr asi -- long )
   sc4             rdasi
   sp         scr  pop
   tos 0           wrasi
   #Sync           membar
   scr 0 %asi tos  lda
   #Sync           membar
   sc4 0           wrasi
c;
code spacex@ ( adr asi -- xlong )
   sc4             rdasi
   sp         scr  pop
   tos 0           wrasi
   #Sync           membar
   scr 0 %asi tos  ldxa
   #Sync           membar
   sc4 0           wrasi
c;
code spaced@ ( adr asi -- low high )
   sc4             rdasi
   sp         scr  get
   tos 0           wrasi
   #Sync           membar
   scr 0 %asi sc2  ldda
   #Sync           membar
   sc3        sp   put
   sc2        tos  move
   sc4 0           wrasi
c;

code spacec! ( byte adr asi -- )
   sc4             rdasi
   sp 0 /n*   scr  nget \ adr in scr
   sp 1 /n*   sc1  nget \ byte in sc1
   tos 0           wrasi
   #Sync           membar
   sc1 scr 0 %asi  stba
   #Sync           membar
   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
   sc4 0           wrasi
c;
code spacew! ( word adr asi -- )
   sc4             rdasi
   sp 0 /n*   scr  nget \ adr in scr
   sp 1 /n*   sc1  nget \ word in sc1
   tos 0           wrasi
   #Sync           membar
   sc1 scr 0 %asi  stha
   #Sync           membar
   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
   sc4 0           wrasi
c;
code spacel! ( long adr asi -- )
   sc4             rdasi
   sp 0 /n*   scr  nget \ adr in scr
   sp 1 /n*   sc1  nget \ long in sc1
   tos 0           wrasi
   #Sync           membar
   sc1 scr 0 %asi  sta
   #Sync           membar
   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
   sc4 0           wrasi
c;
code spacex! ( xlong adr asi -- )
   sc4             rdasi
   sp 0 /n*   scr  nget \ adr in scr
   sp 1 /n*   sc1  nget \ xlong in sc1
   tos 0           wrasi
   #Sync           membar
   sc1 scr 0 %asi  stxa
   #Sync           membar
   sp 2 /n*   tos  nget
   sp 3 /n*   sp   add
   sc4 0           wrasi
c;
code spaced! ( low high adr asi -- )
   sc4             rdasi
   sp 0 /n*   scr  nget  \ adr in scr
   sp 1 /n*   sc2  nget  \ high in sc2
   sp 2 /n*   sc3  nget  \ low  in sc3
   tos 0           wrasi
   #Sync           membar
   sc2 scr 0 %asi  stda
   #Sync           membar
   sp 3 /n*   tos  nget
   sp 4 /n*   sp   add
   sc4 0           wrasi
c;

: spacec?  ( adr space# -- )  spacec@ u.  ;
: spacew?  ( adr space# -- )  spacew@ u.  ;
: spacel?  ( adr space# -- )  spacel@ u.  ;
: spacex?  ( adr space# -- )  spacex@ u.  ;
: spaced?  ( adr space# -- )  spaced@ swap u. u.  ;

headers
