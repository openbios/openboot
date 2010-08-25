\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: malloc.fth
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
id: @(#)malloc.fth 2.10 03/09/09
purpose: 
copyright: Copyright 1990-2001, 2003 Sun Microsystems, Inc.  All Rights Reserved

\ Forth dynamic storage managment.
\
\ By Don Hopkins, University of Maryland
\ Modified by Mitch Bradley, Bradley Forthware
\ Public Domain
\
\ First fit storage allocation of blocks of varying size.
\ Blocks are prefixed with a usage flag and a length count.
\ Free blocks are collapsed downwards during free-memory and while
\ searching during allocate-memory.  Based on the algorithm described
\ in Knuth's _An_Introduction_To_Data_Structures_With_Applications_,
\ sections 5-6.2 and 5-6.3, pp. 501-511.
\
\ init-allocator  ( -- )
\     Initializes the allocator, with no memory.  Should be executed once,
\     before any other allocation operations are attempted.
\
\ add-memory  ( adr len -- )
\     Adds a region of memory to the allocation pool.  That memory will
\     be available for subsequent use by allocate-memory.  This may
\     be executed any number of times.
\
\ allocate-memory  ( size -- adr false  |  error true )
\     Tries to allocate a chunk of memory at least size bytes long.
\     Returns error code and true on failure, or the address of the
\     first byte of usable data and false on success.
\
\ free-memory  ( adr -- )
\     Frees a chunk of memory allocated by malloc.  adr should be an
\     address returned by allocate-memory.  Error if adr is not a
\     valid address.
\
\ memory-available  ( -- size )
\     Returns the size in bytes of the largest contiguous chunk of memory
\     that can be allocated by allocate-memory .

headers
vocabulary allocator
also allocator also definitions
headerless
8 constant #dalign	\ Machine-dependent worst-case alignment boundary

2 base !
1110000000000111 constant *dbuf-free*
1111010101011111 constant *dbuf-used*
decimal

\ : field  \ name  ( offset size -- offset' )
\    create over , +  does> @ +
\ ;

struct
   /n field >dbuf-flag
   /n field >dbuf-size
aligned
   0  field >dbuf-data
   /n field >dbuf-suc
   /n field >dbuf-pred
constant dbuf-min

\ In a multitasking system, the memory allocator head node should
\ be located in a global area, instead in the per-task user area.

dbuf-min ualloc user dbuf-head

: dbuf-data>  ( adr -- 'dbuf )  0 >dbuf-data -  ;

: dbuf-flag!  ( flag 'dbuf -- )   >dbuf-flag !   ;
: dbuf-flag@  ( 'dbuf -- flag )   >dbuf-flag @   ;
: dbuf-size!  ( size 'dbuf -- )   >dbuf-size !   ;
: dbuf-size@  ( 'dbuf -- size )   >dbuf-size @   ;
: dbuf-suc!   ( suc 'dbuf -- )    >dbuf-suc  !   ;
: dbuf-suc@   ( 'dbuf -- 'dbuf )  >dbuf-suc  @   ;
: dbuf-pred!  ( pred 'dbuf -- )   >dbuf-pred !   ;
: dbuf-pred@  ( 'dbuf -- 'dbuf )  >dbuf-pred @   ;

: next-dbuf   ( 'dbuf -- 'next-dbuf )  dup dbuf-size@ +  ;

\ Insert new-node into doubly-linked list after old-node
: insert-after  ( new-node old-node -- )
   >r  r@ dbuf-suc@  over  dbuf-suc!	\ old's suc is now new's suc
   dup r@ dbuf-suc!			\ new is now old's suc
   r> over dbuf-pred!			\ old is now new's pred
   dup dbuf-suc@ dbuf-pred!		\ new is now new's suc's pred
;

: link-with-free  ( 'dbuf -- )

\  Following code will look for possibility of this node getting
\  merged with any of the other nodes.  If it cannot be merged than
\  create a new node and mark it as "free".  The algorithm is to
\  start with the "head" node and look for "next-dbuf" of the first
\  node if it's free node and see if it matches with the start address
\  of the current node.  If it does, then just add this node's "size" to
\  the node.  If this can not be merged or the dbuf is not free then 
\  continue search with the next dbuf until we go through all the nodes.

   dbuf-head dbuf-suc@          ( 'dbuf head-suc )
   begin                        ( 'dbuf dbuf-suc )
     dup dbuf-head = if         ( 'dbuf dbuf-suc )
        drop                    ( 'dbuf )
        *dbuf-free*  over  dbuf-flag!   \ Set node status to "free"
        dbuf-head insert-after          \ Insert in list after head node
        exit
     else                       ( 'dbuf dbuf-suc )
        dup dbuf-flag@ *dbuf-free* = if         ( 'dbuf dbuf-suc )
           over >r              ( 'dbuf dbuf-suc ) ( r: 'dbuf )
           dup next-dbuf        ( 'dbuf dbuf-suc next-dbuf ) ( r: 'dbuf )
           rot                  ( dbuf-suc next-dbuf 'dbuf ) ( r: 'dbuf )
           = if                 ( dbuf-suc ) ( r: 'debuf )
              r> dbuf-size@     ( dbuf-suc dbuf-size )
              over dbuf-size@ + ( dbuf-suc dbuf-new-size )
              swap dbuf-size!   ( )     \ Found node to link, just add the size
              true              ( true )
           else                 ( dbuf-suc ) ( r: 'dbuf )
              dbuf-suc@ r>      ( dbuf-suc 'dbuf )
              swap false        ( 'dbuf dbuf-suc false )
           then
        else                    ( 'dbuf dbuf-suc )
           dbuf-suc@            ( 'dbuf dbuf-suc )
           false                ( 'dbuf dbuf-suc false )
        then
      then
   until
;

\ Remove node from doubly-linked list

: remove-node  ( node -- )
   dup dbuf-pred@  over dbuf-suc@ dbuf-pred!
   dup dbuf-suc@   swap dbuf-pred@ dbuf-suc!
;

\ Collapse the next node into the current node

: merge-with-next  ( 'dbuf -- )
   dup next-dbuf dup remove-node  ( 'dbuf >next-dbuf )   \ Off of free list

   over dbuf-size@ swap dbuf-size@ +  rot dbuf-size!     \ Increase size
;

\ 'dbuf is a free node.  Merge all free nodes immediately following
\ into the node.

: merge-down  ( 'dbuf -- 'dbuf )
   begin
      dup next-dbuf dbuf-flag@  *dbuf-free*  =
   while
      dup merge-with-next
   repeat
;

: .node  ( 'dbuf -- )
   base @ swap hex
   dup 8 u.r  3 spaces
   dup dbuf-flag@  5 u.r
   dup dbuf-size@  9 u.r
   dup dbuf-suc@   9 u.r
   dbuf-pred@      9 u.r
   cr
   base !
;

headers
: .list  ( -- )
   dbuf-head
   begin  dbuf-suc@ dup  dbuf-head <>  while  dup .node  repeat
   drop
;
headerless
forth definitions

: msize  ( adr -- count )  dbuf-data>  dbuf-size@  dbuf-data>  ;

: free-memory  ( adr -- )
   dbuf-data>   ( 'dbuf )
   dup dbuf-flag@ *dbuf-used* - if
      \ This is here because the the allocator has completely given up
      \ and rather than corrupt state we just deliberately puke.
      \ the old 'abort' was insufficient because it was being caught and the
      \ error code mis-interpreted; so instead we force a hard fault that we
      \ can back trace.
      ??cr ." FATAL: free-memory: bad address." cr -1 @
   then
   merge-down link-with-free
;

: add-memory  ( adr len -- )
   \ Align the starting address to a "worst-case" boundary.  This helps
   \ guarantee that allocated data areas will be on a "worst-case"
   \ alignment boundary.

   swap dup  #dalign round-up      ( len adr adr' )
   dup rot -                       ( len adr' diff )
   rot swap -                      ( adr' len' )
   #dalign round-down              ( adr' len'' )

   \ Set size and flags fields for first piece

   \ Subtract off the size of one node header, because we carve out
   \ a node header from the end of the piece to use as a "stopper".
   \ That "stopper" is marked "used", and prevents merge-down from
   \ trying to merge past the end of the piece.

   dbuf-data>                      ( 'dbuf-first #dbuf-first )

   \ Ensure that the piece is big enough to be useable.
   \ A piece of size dbuf-min (after having subtracted off the "stopper"
   \ header) is barely useable, because the space used by the free list
   \ links can be used as the data space.

   dup dbuf-min < abort" add-memory: piece too small"

   \ Set the size and flag for the new free piece

   *dbuf-free* 2 pick dbuf-flag!   ( 'dbuf-first #dbuf-first )
   2dup swap dbuf-size!            ( 'dbuf-first #dbuf-first )

   \ Create the "stopper" header

   \ XXX The stopper piece should be linked into a piece list,
   \ and the flags should be set to a different value.  The size
   \ field should indicate the total size for this piece.
   \ The piece list should be consulted when adding memory, and
   \ if there is a piece immediately following the new piece, they
   \ should be merged.

   over +                          ( 'dbuf-first 'dbuf-limit )
   *dbuf-used* swap dbuf-flag!     ( 'dbuf-first )

   link-with-free
;

: (allocate-memory)  ( size -- adr false  |  error-code true )
   \ Keep pieces aligned on "worst-case" hardware boundaries
   #dalign round-up                 ( size' )

   >dbuf-data dbuf-min max          ( size )

   \ Search for a sufficiently-large free piece
   dbuf-head                        ( size 'dbuf )
   begin                            ( size 'dbuf )
      dbuf-suc@                     ( size 'dbuf )
      dup dbuf-head =  if           \ Bail out if we've already been around
         2drop 1 true exit          ( error-code true )
      then                          ( size 'dbuf-suc )
      merge-down                    ( size 'dbuf )
      dup dbuf-size@                ( size 'dbuf dbuf-size )
      2 pick >=                     ( size 'dbuf big-enough? )
   until                            ( size 'dbuf )

   dup dbuf-size@ 2 pick -          ( size 'dbuf left-over )
   dup dbuf-min <=  if              \ Too small to fragment?

      \ The piece is too small to split, so we just remove the whole
      \ thing from the free list.

      drop nip                      ( 'dbuf )
      dup remove-node               ( 'dbuf )
   else                             ( size 'dbuf left-over )

      \ The piece is big enough to split up, so we make the free piece
      \ smaller and take the stuff after it as the allocated piece.

      2dup swap dbuf-size!          ( size 'dbuf left-over) \ Set frag size
      +                             ( size 'dbuf' )
      tuck dbuf-size!               ( 'dbuf' )
   then
   *dbuf-used* over dbuf-flag!      \ Mark as used
   >dbuf-data false                 ( adr false )
;

: memory-available  ( -- size )
   0 >dbuf-data                     ( current-largest-size )

   dbuf-head                        ( size 'dbuf )
   begin                            ( size 'dbuf )
      dbuf-suc@  dup dbuf-head <>   ( size 'dbuf more? )
   while                            \ Go once around the free list
      merge-down                    ( size 'dbuf )
      dup dbuf-size@                ( size 'dbuf dbuf-size )
      rot max swap                  ( size' 'dbuf )
   repeat
   drop  dbuf-data>                 ( largest-data-size )
;

\ Head node has 0 size, is not free, and is initially linked to itself

: init-allocator  ( -- )
   *dbuf-used* dbuf-head dbuf-flag!
   0 dbuf-head dbuf-size!	\ Must be 0 so the allocator won't find it.
   dbuf-head  dup  dbuf-suc!	\ Link to self
   dbuf-head  dup  dbuf-pred!
;

previous previous definitions

\ Tries to allocate, and if that fails, requests more memory from the system

also allocator also

defer more-memory  ( request-size -- adr actual-size false | error-code true )

: allocate-memory  ( size -- adr false  |  error-code true )
   dup (allocate-memory)  if	      ( size error-code )
      \ No more memory in the heap; try to get some more from the system
      drop                            ( size )
      \ use same alignment requirements and add space 
      \ for header and stopper header as in (allocate-memory)
      dup #dalign round-up            ( size size' )
      >dbuf-data >dbuf-data           ( size size' )
      more-memory  if                 ( size error-code )
         nip true                     ( error-code true )
      else                            ( size adr actual )
         add-memory                   ( size )
	 (allocate-memory)            ( adr false  |  error-code true )
      then                            ( adr false  |  error-code true )
   else                               ( size adr )
      nip false                       ( adr false )
   then                               ( adr false  |  error-code true )
;
previous  previous

: heap-alloc-mem  ( bytes -- adr )
   allocate-memory abort" Out of memory"
;

: heap-free-mem  ( adr size -- )  drop free-memory  ;

init-allocator

headers
h# 10.0000 constant 1meg
