id: @(#)allocph.fth 2.32 06/02/16 19:19:49
purpose: 
copyright: Copyright 1990-2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Copyright 1994 FirmWorks               All Rights Reserved
copyright: Use is subject to license terms.

\ Allocator for physical memory.

\ Methods:

\ claim  ( [ phys.lo phys.hi ] alignment size -- base.lo base.hi )
\       If "alignment" is non-zero, allocates at least "size" bytes of
\	physical memory aligned on the indicated boundary, returning
\	its address "base.lo base.hi".  This implementation rounds
\	"alignment" up to a multiple of the page size.
\
\	If "alignment" is zero, removes the range of physical memory
\	denoted by phys.lo, phys.hi, and size from the list of available
\	physical memory, returning "base.lo base.hi" equal to "phys.lo phys.hi"
\
\ release  ( phys.lo phys.hi size -- )
\	Frees the physical memory range denoted by phys.lo, phys.hi, and size.

\ clear-mem is a deferred word so that a system-dependent implementation,
\ perhaps using bzero hardware, can be installed in the system-dependent
\ part of the load sequence.

: no-phys-memory ( -- phys.lo phys.hi len )  0 0 0  ;
defer clear-mem  ( phys space size -- )  ' 3drop is clear-mem
defer initial-memory  ( -- phys.lo phys.hi len )  ' no-phys-memory to initial-memory

root-device
new-device

" memory" device-name

list: physavail   0 physavail !

headerless
: bytes>pages ( bytes -- #pages )  pageshift rshift  ;
: pages>bytes ( #pages -- bytes )  pageshift lshift  ;

: pages>phys-adr,len ( page# #pages -- phys.lo phys.hi size )
   pages>bytes   >r                   ( page# ) ( r: size )
   dup pages>bytes                    ( page# p.lo ) ( r: size )
   swap bits/cell pageshift - rshift  ( p.lo p.hi ) ( r: size )
   r>                                 ( phys.lo phys.hi size )
;
: phys-adr,len>pages ( phys.lo phys.hi size -- page# #pages )
   bytes>pages  >r                ( phys.lo phys.hi ) ( r: #pages )
   bits/cell pageshift - lshift   ( phys.lo page#.hi ) ( r: #pages )
   swap bytes>pages  or  r>       ( page# #pages )
;

headers
: first-phys-avail  ( -- phys.lo phys.hi size )
   physavail last-node            ( node )
   node-range pages>phys-adr,len  ( phys.lo phys.hi size )
;


\  Variable to indicate when all physical memory is clean.
\  Gets turned on after the scrubbing operation is complete.
\  Platforms that know that their memory is pre-cleaned can
\  cause this to be turned on by defining the compile-time
\  switch  PreCleanedMemory
also forth definitions variable memory-clean?  previous definitions

[ifdef] PreCleanedMemory
   memory-clean? on
[else]
   memory-clean? off
[then]

headerless

: accum-size  ( total node -- total' false )  >size @ +  false  ;
: total-size  ( list -- size-lo size-hi )
   0 swap ['] accum-size find-node  2drop
   1 pages>phys-adr,len drop
;

: allocate-aligned-physical  ( alignment size -- phys-adr space )
   \ Minumum granularity of memory chunks is 1 page
   swap mmu-pagesize round-up  bytes>pages
   swap mmu-pagesize round-up  bytes>pages   ( aln+ size+ )
   tuck physavail                        ( size alignment size list )
   allocate-memrange                     ( size [ adr ] error? )
   abort" Insufficient physical memory"  ( size adr )
   swap pages>phys-adr,len               ( phys.lo phys.hi bytes )

   \  Don't re-clear memory after it's been scrubbed,
   \  or if it's been pre-cleaned.
   memory-clean? @ 0= if
      3dup  clear-mem                       ( phys.lo phys.hi bytes )
   then

   drop
;

\ variable allow-reclaim  true allow-reclaim !
: claim-physical  ( adr space size -- )
   ['] 2drop is ?splice
   swap >r                                        ( adr size ) ( r: space )
   >page-boundaries                               ( adr' size' )
   r> swap phys-adr,len>pages                     ( page# #pages )

   \ Look first in the monitor's piece list
   physavail  ['] contained?  find-node           ( page#,#pages prev next|0 )
   is next-node  is prev-node                     ( page#,#pages )

   next-node 0= abort" physical address already used"  ( page#,#pages )

   \ There are 4 cases to consider in removing the requested physical
   \ address range from the list:
   \ (1) The requested range exactly matches the list node range
   \ (2) The requested range is at the beginning of the list node range
   \ (3) The requested range is at the end of the list node range
   \ (4) The requested range is in the middle of the list node range

   \ Remember the range of the node to be deleted
   next-node node-range                            ( page#,#pages node-a,l )

   \ Remove the node from the list
   prev-node delete-after  memrange free-node      ( page#,#pages node-a,l )

   \ Give back any left-over portion at the beginning
   over 4 pick over -  dup  if            ( page#,#pages node-a,l begin-a,l )
      physavail free-memrange
   else
      2drop
   then                                            ( page#,#pages node-a,l )

   \ Give back any left-over portion at the end
   2swap +  -rot  +   over -                            ( end-a,l )
   ?dup  if  physavail free-memrange  else  drop  then  (  )
;

\  Adjust the alignment and size of a given range of memory to match
\  the granularity of what will actually be freed-up.
: range>page-boundaries ( phys.lo phys.hi size -- phys.lo' phys.hi size' )
   swap >r			  ( phys.lo bytes )	( R: phys.hi )
   >page-boundaries		  ( phys.lo' bytes' )	( R: phys.hi )
   r> swap			  ( phys.lo' phys.hi bytes' )
;

\  Free-up the given range of physical memory.
\  It's expected to be all adjusted and aligned...
: free-phys-range ( phys.lo' phys.hi size' -- )
   phys-adr,len>pages		  ( page# #pages )
   ['] 2drop  is ?splice
   physavail free-memrange        (  )
;

\  Initialize the "available" list.  Formerly, this was accomplished
\  by using the  release  function, but now that memory-clearing has
\  been introduced there, this function needs to be distinct.
: init-phys-mem ( phys.lo phys.hi size -- )
   range>page-boundaries  free-phys-range
;

headers
: claim ( [ phys.lo phys.hi ] size align -- base.lo base.hi )
   ?dup  if                          ( size align )
      \ Alignment should be next power of two
      swap allocate-aligned-physical ( base.lo base.hi )
   else                              ( phys.lo phys.hi size )
      3dup claim-physical drop       ( base.lo base.hi )
   then                              ( base.lo base.hi )
;

: release ( phys.lo phys.hi size -- )
   range>page-boundaries	     ( phys.lo' phys.hi size' )

   \ We need to clear the memory when we release it in case we disable 
   \ clearing at allocation time in the future. Therefore, before we 
   \ set the 'memory-clean?' variable, we will be clearing the memory 
   \ during both the 'claim' and 'release' client interface calls.
   3dup  clear-mem                       ( phys.lo phys.hi bytes )

   free-phys-range		     (  )
;
: close  ( -- )  ;
: open  ( -- ok? )
   physavail @  if  true exit  then
   initial-memory  dup  if   ( p.lo p.hi size )
      init-phys-mem
   else
      3drop
   then
   true
;

\ Leave it up to the MMU driver
-1 constant mode

finish-device
device-end

stand-init: Opening the physical memory package
   " /memory" open-dev  memory-node !
;
