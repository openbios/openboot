\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: arcbpsup.fth
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
id: @(#)arcbpsup.fth 1.16 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ System-architecture-dependent definitions for breakpoints.

headerless
h# 17f  constant breakpoint-trap#

0 value bp-vadr
pagesize 2*   constant bp-va-size
bp-va-size 1- constant bp-va-mask

h# 8000.0000	\ Class 2
h# 1000.0000 +	\ condition always
h#  1d0.0000 +	\ Trap on Integer Condition Codes
h#      2000 +	\ Immediate
breakpoint-trap# h# ff and +  constant sun4u-bp-opcode

: arch-bp-trap?  ( -- flag )  last-trap# breakpoint-trap#  =  ;

: page-valid? ( vadr -- flag )
   \ This used to contain prom-virt? unfortunately that allows
   \ addresses that are in the VPT to be considered as valid stack
   \ pointers, so now we crop the range down to just OBP. BUGID: 4262883
   dup ROMbase RAMtop between  if  pgmap@  valid-tte?  exit  then
   0 find-client-tte  if  ( tte vadr )
      2drop true          ( flag )
   else                   (  )
      false               ( flag )
   then                   ( flag )
;

' page-valid? is accessible?

: sun4u-op@  ( adr -- op|0 )
   dup accessible?  if  l@  else  drop 0  then
;
: va>pa ( vadr -- pa.lo pa.hi true -or- false )
   dup  0 find-client-tte  if       ( vadr tte vadr' )
      drop  tuck  tte>size 1-  and  ( tte offset )
      swap tte> >r or r>  true      ( pa.lo pa.hi true )
   else                             ( vadr )
      drop false                    ( false )
   then
;
: sun4u-op!  ( op adr -- )
   dup accessible? 0=  if  2drop exit  then  ( op adr )

   \ prom addresses cannot be breakpointed
   dup prom-virt?  if  2drop exit  then     ( op adr )

   dup  va>pa  if           ( op vadr pa.lo pa.hi )
      rot  bp-va-mask and   ( op pa.lo pa.hi offset )
      dup  bp-vadr  or      ( op pa.lo pa.hi bpoffset bpva )
      2>r r@  map-page      ( op ) ( r: bpoffset bpva )

      \ Store the instruction and IFLUSH
      r>  instruction!  r>  ( bpoffset )

      \ Force D$ displacement flush
      origin+ l@ drop       (  )
      \ trigger a demap of bp-vadr
      bp-vadr unmap-page	(  )
   else                     ( op adr )
      2drop                 (  )
   then                     (  )
;

stand-init: Install breakpoint ops
   ['] sun4u-op@      is op@
   ['] sun4u-op!      is op!
   ['] arch-bp-trap?  is breakpoint-trap?
   sun4u-bp-opcode    is breakpoint-opcode
   bp-va-size dup mmu-claim is bp-vadr
;

