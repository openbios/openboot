\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: go.fth
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
id: @(#)go.fth 1.22 06/03/14
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
\ A wrapper for the cif calls.
overload: do-cif ( ( adr  -- result )
   mid@ cif-owner l!  do-cif  -1 cif-owner l!
;

1 1 ' do-cif make-c-entry  create &cif-func() token,
headers
: cif-func() ( -- adr )  &cif-func() token@  ;

headers
: (init-program)  ( -- )

   cif-64	\ 64-Bit IEEE 1275 Client Interface

   init-c-stack	\ Erase any previous C stack state

   \ Zero all the general registers.
   0w
   0 to %g0  0 to %o0  0 to %l0  0 to %i0
   0 to %g1  0 to %o1  0 to %l1	 0 to %i1
   0 to %g2  0 to %o2  0 to %l2	 0 to %i2
   0 to %g3  0 to %o3  0 to %l3	 0 to %i3
   0 to %g4  0 to %o4  0 to %l4	 0 to %i4
   0 to %g5  0 to %o5  0 to %l5	 0 to %i5
   0 to %g6  0 to %o6  0 to %l6	 0 to %i6
   0 to %g7  0 to %o7  0 to %l7	 0 to %i7

   cif-func() to %o4 	\ IEEE 1275 Client Services Handler
   %o6@       to %o6	\ C stack pointer

   trap-table to %tba	\ Set trap table

   h#  0 to %y       h#   4 to %fprs
   h# 16 to %pstate  h#  0d to %pil

   7 to %cleanwin   0 to %otherwin
   0 to %wstate     0 to %canrestore
   6 to %cansave    0 to %cwp

   h# 16 8 lshift to %tstate-c

   load-base set-pc

[ifdef] SUN4V
\ Since we are initializing a stack, make sure we clear out previous saved
\ state indications. This affects ultra4v/savecpu.fth:restore-cpu-state,
\ which is invoked shortly after this.

   0 to full-save?
[then]

   sp@ saved-sp !  rp@ saved-rp !       \ Needed for later callbacks into Forth

   state-valid on  restartable? on
   true to already-go?
[ifdef] Starcat?
   RELEASE-SLAVE-INVALID release-slaves? l!
[then]
;

\ Allow dropin drivers to be standalone programs.

headers
tail-chain: execute-buffer  ( adr len -- )
   over adjust-elf32-header  if      ( adr,len entry )
      (init-program)  set-pc  2drop  ( entry )
      go
      exit
   then                              ( adr,len )
tail;

tail-chain: execute-buffer  ( adr len -- )
   over adjust-elf64-header  if      ( adr,len entry )
      (init-program)  set-pc  2drop  ( entry )
      go
      exit
   then                              ( adr,len )
tail;

tail-chain: execute-buffer  ( adr len -- )
   over 2 + unaligned-w@  h# 107  =  if       ( adr len )
      over a.out-header /a.out-header move    ( adr len )
      2dup  initsyms                          ( adr len )
      drop /a.out-header + entry-adr          ( src dest )
      /text /data + move                      (  )
      entry-adr /text /data + + /bss erase    (  )
      (init-program)  entry-adr  set-pc       (  )
      go      \ XXX we need some way to get back!
      exit
   then
tail;

tail-chain: execute-buffer  ( adr len -- )
   over 2 + unaligned-w@  h# 107  =  if       ( adr len )
      over >r                                 ( adr len ) ( r: adr )
      r@ a_entry l@   r@ a_text l@  r> a_data l@  or or
      h# 9000.0000 tuck and =  if             ( adr len )
	 >r dup dup /a.out-header - r> move   ( adr len )
	 (init-program)   set-pc              ( adr len )
	 go      \ XXX we need some way to get back!
	 exit
      then                                    ( adr len )
   then                                       ( adr len )
tail;

cif: enter   ( -- )  reenter  call  ;
cif: exit    ( -- )  exittomon call  ;
\ cif: chain   ( len args entry size virt -- )  op-chain  ;

headers
: init-program ( -- )
   load-base file-size @  'execute-buffer execute  (init-program)
;
