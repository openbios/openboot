\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: allocator.fth
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
id: @(#)allocator.fth 1.2 98/03/24
purpose: 
copyright: Copyright 1998 Sun Microsystems, Inc.  All Rights Reserved

\ XXX This is a crude brute-force allocation scheme that won't work for
\ many cases, but probably will work for most of the situations we will
\ face in practise -- a prototype version that gets lots of memory once,
\ releases it once, and while the host adaptor is active, parcels out bits
\ and pieces on request.

-1 value dma-base			\ Must be global
-1 value dev-dma-base			\  Ditto

h# 10.0000 constant #grab

: get-mem  ( -- )
   #grab dma-alloc  to dma-base
   dma-base #grab false  dma-map-in  to dev-dma-base
;

: give-mem  ( -- )
   dma-base dev-dma-base #grab dma-map-out
   -1 to dev-dma-base
   dma-base #grab dma-free
   -1 to dma-base
;

: sync-mem  ( -- )
   dma-base dev-dma-base #grab dma-sync
;

: virt>offset  ( virt -- offset )  dma-base     -  ;
: dev>offset   ( dev -- offset )   dev-dma-base -  ;

: offset>virt  ( offset -- virt )  dma-base     +  ;
: offset>dev   ( offset -- dev )   dev-dma-base +  ;

: virt>dev  ( virt -- dev )  virt>offset offset>dev  ;

: dev>virt  ( dev -- virt )  dev>offset offset>virt  ;

\ XXX alignment restrictions.  first fit.  keep list in sorted order.  key
\ on virt address.  keep actual requested amount and allocated amount for
\ now.  do in 1k byte chunks for now.  this gives 1000 entries for 1000
\ pieces to get to 1 meg grabbed in the first place.
\ most alignment can actually be done to 32 bytes.

\ The allocation table has one entry for each chunk of the dma space.
\ So, 1k entries * 1kbytes/entry = 1meg.  The entry is marked if that
\ chunk is allocated.  It is unmarked if that chunk is available.  This
\ gives coalescing chunks for free.

\ The memory must be like dma-alloc and dma-free -- the requester must free
\ exactly what it asked for.

struct
   /n field >marker		\ non-zero if allocated
\   /n field >asked
\   /n field >given
   /n field >caller-addr	\ in case this is a copy buffer
constant /entry
   
h# 400 constant /slot		\ #bytes for each table slot

#grab /slot / constant #mem-entries

#mem-entries /entry * buffer: mem-table

\ In case the table representation changes, use these:
: mark  ( tbl-addr #slots -- )
   0 do
      true
      over  i /entry *  +  !
   loop
   drop
;

: unmark  ( tbl-addr #slots -- )
   /entry *  erase
;

: slot>tbl-addr  ( slot# -- table-addr )  /entry *  mem-table +  ;

: marked?  ( slot# -- marker )  slot>tbl-addr >marker @  ;

: virt>slot  ( virt -- slot# )  virt>offset  /slot /  ;

: slot>virt  ( slot# -- virt )  /slot *  dma-base +  ;

: #slots  ( #bytes -- #slots-taken )	\ number of slots for this many bytes
   /slot /mod
   swap  if  1+  then
;

\ slot#1 is the start slot.  slot#2 is the first slot that is unmarked.
\ There had better be one, or this will fail.  slot#2 could = slot#1
\ could use left-parse-string
: find-next-open  ( slot#1 -- slot#2 )
   dup #mem-entries swap -  0 do
      dup i +  marked?  0=  if
         i leave
      then
   loop
   +
;

\ could fill a region of memory w. 0's and do successive compares
\ XXX again, there had better be a chunk that works somewhere in the table
\ or crash will occur.
: enough-slots?  ( slot# #slots-needed -- yes? )
   true -rot
   0 do
      dup i + marked?  if  nip false swap leave  then
   loop
   drop
;

\ XXX this is dumb.  brute force.  slows down in a region of not enough slots.
: find-start-slot  ( #slots -- slot# )		\ slot# is start of region
   >r  0  begin				( test-slot ) ( R: #slots )
      dup r@ enough-slots? 0=
   while				( bad-slot# ) ( R: #slots )
      1+ find-next-open 
   repeat
   r> drop
;

\ find the first non-zero. count number of succeeding zeros.  are there enough?
\ if so, done.  if not, go to the next non-zero and start over.
\ XXX there better be enough room left or the whole thing will crash.
\ XXX assume it never fails:
: get-chunk  ( #bytes -- virt )		\ acquire dma memory
   dup
   #slots dup
   find-start-slot			( #bytes #slots slot# )
   tuck
   slot>tbl-addr swap mark
   slot>virt				( #bytes virt )
   tuck swap erase
;

: give-chunk  ( virt #bytes -- )	\ return dma memory
   #slots swap
   virt>slot slot>tbl-addr swap
   unmark
;

: new-mem-table  ( -- )
   mem-table  #mem-entries /entry * erase
;
