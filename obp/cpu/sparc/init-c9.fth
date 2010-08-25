\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: init-c9.fth
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
id: @(#)init-c9.fth 1.9 00/02/15
purpose: 
copyright: Copyright 1999 Sun Microsystems, Inc.  All Rights Reserved

headerless
0 value c-stack

\
\ If OBP takes an exception fairly early, the exception handler tries to
\ use this before we have allocated enough state to cope.
\
: init-c-stack  ( -- )
   c-stack 0= if  exit  then   
   lock[
      7 cleanwin!  0 otherwin!
      0 wstate!    0 canrestore!
      6 cansave!   0 cwp!
      c-stack %o6!
      0 %i6!   0 %i7!
      c-stack  /entry-frame negate  0  fill
   ]unlock
;

: create-c-stack  ( -- )
   \ Establish the C stack
   mmu-pagesize dup 0                           ( align size virt )
   [ also client-services ] claim [ previous ]  ( stack-bottom-adr )
   dup mmu-pagesize erase
   mmu-pagesize + d# 7 invert and
   /entry-frame +  V9_SP_BIAS -  to  c-stack
   init-c-stack
;

stand-init: Creating C stack
   create-c-stack
;
headers
