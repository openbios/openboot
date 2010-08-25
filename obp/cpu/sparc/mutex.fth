\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mutex.fth
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
id: @(#)mutex.fth 1.5 01/05/11
purpose: 
copyright: Copyright 1999-2001 Sun Microsystems, Inc.  All Rights Reserved

headers transient

: mutex-create ( -- ) \ name
   label -1 l, end-code
;

: sema-create ( -- ) \ name
   label 1 l, end-code
;

also assembler definitions
hex

: mutex-exit ( scr sc1 sc2 -- ) \ which?
   dup get-mid
   over ' >body origin-  aligned swap  set	\ offset of mutex
   over base  over         add			\ Address of mutex
   rot  >r
   %g0   1           r@    sub			\ -1
\   h# 80 swap        r>    casa
   h# 04 swap        r>    casa
; immediate

: mutex-set ( value-reg scr -- ) \ which?
   ' >body origin- aligned over set
   dup  base  over      add
   %g0                  st
; immediate

\
\ if scr = -1 then you got the lock (ie the lock was -1), otherwise
\ it is the current owner.
\
: mutex-try-enter ( scr sc1 sc2 -- scr ) \ which?
   dup  get-mid
   over ' >body origin-  aligned swap  set	\ offset of mutex
   over base  over         add			\ Address of mutex
   rot  >r
   %g0   1           r@    sub			\ -1
   h# 04 r@   rot >r r@    casa
\   h# 80 r@   rot >r r@    casa
   r>    0           r>    sra
; immediate

: mutex-enter ( scr sc1 sc2 sc3 -- ) \ which?
   over  get-mid
   2dup  move >r
   over ' >body origin-  aligned swap  set	\ offset of mutex
   over base  over         add			\ Address of mutex
   rot  >r
   [ also assembler ]
   begin -rot
      nop nop nop				\ allow a little slack time.
      2r@ drop  over move			\ restore mid
      %g0   1          r@  sub			\ -1
\      h# 80 r> rot dup >r  casa
      h# 04 r> rot dup >r  casa
      r@ 0             r@  sra
      r@ -1                cmp
      0=  if
         r>    r>          cmp
         %g0   %g0   %g0   subcc		\ aquired lock
      then
   0= until  nop
   [ previous ]
; immediate

0 value sema-scr
0 value sema-sc1
0 value sema-sc2

\ src contains the value to init the semaphore with
: init-sema ( scr sc1 -- ) \ name
   to sema-sc1
   to sema-scr
   ' >body origin-  aligned sema-sc1 set	\ sc1 = offset of semaphore
   sema-scr  sema-sc1  base	st		\ store
; immediate

: sema-atsub ( -- )
   sema-scr  base  sema-scr	add		\ VA of semaphore
   sema-scr  %g0   sema-sc1	ld
   begin
      sema-sc1  1  sema-sc2	sub
      sema-scr h# 04 sema-sc1  sema-sc2  casa
      sema-sc1  sema-sc2  %g0	subcc
   0= until annul
      sema-scr  %g0   sema-sc1	ld
   sema-sc1  1  sema-scr	sub  
;

\ decremented value is returned in scr.
: decr-sema ( scr sc1 sc2 -- ) \ name
   to sema-sc2
   to sema-sc1
   to sema-scr
   ' >body origin-  aligned sema-scr set	\ scr = offset of semaphore
   sema-atsub
; immediate

: wait-sema ( scr sc1 sc2 -- ) \ name
   to sema-sc2
   to sema-sc1
   to sema-scr
   ' >body origin-  aligned sema-scr set	\ scr = offset of semaphore
   sema-scr >r
   sema-atsub
   begin
      sema-scr  %g0  %g0  subcc
   0= until annul
      r>  base  sema-scr  ld
; immediate

resident
previous definitions
