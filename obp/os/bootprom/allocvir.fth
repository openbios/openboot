\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: allocvir.fth
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
id: @(#)allocvir.fth 2.38 03/07/17
purpose:
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Virtual memory allocator for mapping in devices.

\ allocate-virtual  ( size -- phys space adr )
\	Allocates at least "size" bytes of virtual memory.  The actual
\	allocation size is "size" rounded up to a multiple of the page size.
\

\ The firmware is allowed to allocate from 2 ranges of virtual memory, by
\ (partially historical) agreement with the OS kernel.
\ The first, and preferred, range is the 2 MByte range from 0xffd0.0000
\ to 0xffef.ffff.  This range contains the mappings for the firmware itself,
\ and the firmware's stacks, RAM space, and device mappings, leaving a little
\ more than a megabyte for mapping plug-in devices.
\
\ For larger framebuffers, 1 MByte is not enough, so the firmware is also
\ allowed to allocate from the virtual region below 0xff00.0000.  Unix
\ calls this address "Sysbase".  There is over 100 MBytes of otherwise
\ unused virtual space between the end of the kernel text+data+bss+buffers
\ at approximately 0xf820.0000 and Sysbase.
\
\ One possible problem with this region below 0xff00.0000 is that it is
\ inaccessable to DVMA from some devices, particularly the AMD Ethernet
\ interface on the 4/60 and derived products.  That interface has a 24-bit
\ DMA interface, with bits A31:A24 hardwired to 0xff, so DVMA addresses
\ for that device must be at or above 0xff00.0000.
\
\ One solution is to use the "below 0xff00.0000" region for very large
\ devices, say 1MByte or greater, thus leaving enough space for everything
\ else in the high region above 0xffd0.0000.
\
\ For now, we use a "first-fit" policy and hope.

\ If the PMEG containing "splice-adr" is completely contained within the
\ indicated node, free that PMEG.  This code assumes that "splice-adr" itself
\ is contained within the node.  If "splice-adr" is a segment boundary,
\ then we don't need to free the PMEG, because it will have already been
\ taken care of at a higher level.

defer check-range  ' noop is check-range

root-device
new-device

" virtual-memory" device-name

headers
list: fwvirt	\ Virtual memory available list
list: osvirt	\ Virtual memory that the OS can use but the firmware can't

headerless

: ?free-segment  ( splice-adr node -- )
   >r                                              ( splice-adr )
   dup segmentsize round-down                      ( splice-adr seg-adr )
   \ Exit if the splice is exactly on a segment boundary
   tuck  =  if  drop r> drop exit  then            ( sdg-adr )
   segmentsize                                     ( seg-adr seg-size )
   r> contained?  if                               ( seg-adr seg-size )
      drop deallocate-segment
   else                                            ( seg-adr seg-size )
      2drop
   then                                            ( )
;

\ Frees the virtual address range "adr len"

: noreclaim-free-virtual  ( adr len -- )
   >page-boundaries
   over  monvirtbase  dup monvirtsize +  within  if  ( adr len )
      fwvirt
   else                                              ( adr len )
      over low-base   dup low-size +  within  if     ( adr len )
         fwvirt
      else                                           ( adr len )
         osvirt
      then
   then                                              ( adr len memorylist )
   free-memrange
;
\ Finds the starting address and size of any segments completely contained
\ within the range adr,len

: enclosed-segments  ( adr len -- seg-start seg-len )
   bounds >r                 ( end-adr )      ( r: start-adr )
   segmentsize round-down    ( seg-end )      ( r: start-adr )
   dup r@ u<  if             ( seg-end )      ( r: start-adr )
      drop r> 0 exit         ( start-adr 0 )  ( r: start-adr )
   then                      ( seg-end )      ( r: start-adr )
   r> segmentsize round-up   ( seg-end seg-start )
   over umin                 ( seg-end seg-start' )
   tuck -                    ( seg-start seg-len )
;


: reclaim-segments  ( adr len -- )
   >page-boundaries
   enclosed-segments         ( seg-adr seg-len )
   bounds  ?do               ( )
      i deallocate-segment   ( )
   segmentsize +loop         ( )
;

headers
\ Frees virtual memory and PMEGs, but not the physical memory behind it
: free-virtual-only  ( adr len -- )
   >page-boundaries
   2dup reclaim-segments
   ['] ?free-segment  is ?splice    ( adr' len' )
   noreclaim-free-virtual
;

headerless
: segment-boundaries  ( adr len -- end-adr seg-end seg-start start-adr )
   2dup bounds 2swap  ( end-adr start-adr adr len )
   enclosed-segments  ( end-adr start-adr seg-start seg-len )
   bounds rot
;

\ Allocates "segment-level" mapping resources for the indicated address range

: ?allocate-segments  ( adr size -- )
   segment-boundaries       ( end-adr seg-end seg-start start-adr )
   ?allocate-segment        ( end-adr seg-end seg-start )
   over swap  ?do           ( end-adr seg-end )
      i ?allocate-segment   ( end-adr seg-end )
   segmentsize +loop        ( end-adr seg-end )
   tuck -  if  ?allocate-segment  else  drop  then      ( )
;

\ Allocates at least "size" bytes of virtual memory
headers
: allocate-aligned-virtual ( alignment size -- virt-adr )
   \ Minumum granularity of memory chunks is 1 page
   swap mmu-pagesize round-up
   swap mmu-pagesize round-up           ( alignment+ size+ )
   tuck fwvirt                          ( size alignment size list )
   allocate-memrange                    ( size [ adr ] error? )
   abort" Insufficient virtual memory"  ( size adr )
   tuck swap ?allocate-segments         ( adr )
;

: allocate-virtual  ( size -- virt )
   1 swap allocate-aligned-virtual
;
headerless
: claim-virtual  ( adr size -- adr )
   over >r  >page-boundaries                          ( adr,len' )
   \ Look first in the monitor's piece list
   fwvirt  ['] contained?  find-node                  ( adr,len' prev next|0 )
   dup  0=  if
      \ If not found in the monitor's virtual list, look in
      \ the OS's virtual list.
      2drop
      osvirt  ['] contained?  find-node               ( adr,len' prev next|0 )
   then
   is next-node  is prev-node                         ( adr,len' )

   next-node 0= abort" Virtual address already used"  ( adr,len' )

   \ There are 4 cases to consider in removing the requested virtual
   \ address range from the list:
   \ (1) The requested range exactly matches the list node range
   \ (2) The requested range is at the beginning of the list node range
   \ (3) The requested range is at the end of the list node range
   \ (4) The requested range is in the middle of the list node range

   \ Remember the range of the node to be deleted
   next-node node-range                                ( adr,len' node-a,l )

   \ Remove the node from the list
   prev-node delete-after  memrange free-node          ( adr,len' node-a,l )

   \ Give back any left-over portion at the beginning
   over 4 pick over -                        ( adr,len' node-a,l begin-a,l )
   dup  if  noreclaim-free-virtual  else  2drop  then  ( adr,len' node-a,l )

   \ Give back any left-over portion at the end
   2over +  -rot  +   over -                           ( adr,len' end-a,l )
   dup  if  noreclaim-free-virtual  else  2drop  then  ( adr,len' )

   ?allocate-segments                                  ( )
   r>                                                  ( adr )
;

: add-os-piece  ( start-adr end-adr -- )
   over -  set-node  osvirt  insert-after
;

headers
[ifdef] notdef
\ The open method of /virtual-memory is highly system dependent.
\ Below is an example open method which may not work for
\ every system. The corret version of this method should
\ be defined in the system dependent MMU driver which presumably
\ knows about the limitations and futures of the MMU hardware.
: open  ( -- ok? )
   0 memrange !				\ Clear free list
   d# 20  memrange  more-nodes		\ Get enough nodes "forever"

   \ Create the available memory list from which the firmware is allowed
   \ to dynamically allocate virtual memory.

   low-base     low-size        set-node  fwvirt  insert-after
   monvirtbase  monvirtsize     set-node  fwvirt  insert-after

   ROMbase      dictionary-top over -	claim-virtual drop
   RAMbase      RAMsize			claim-virtual drop

   \ Create the available memory list from which the firmware is not allowed
   \ to dynamically allocate virtual memory.

   hole-end hole-start <> if
      0                          hole-start  add-os-piece
      hole-end                   low-base    add-os-piece
   else
      0                          low-base    add-os-piece
   then
   low-base low-size +        monvirtbase add-os-piece
   monvirtbase monvirtsize +  0           add-os-piece

   true
;
[then] \ notdef

: close  ( -- )  ;

: claim  ( [ virt ] size align -- base )
   ?dup  if                          ( size align )
      \ Alignment should be next power of two
      swap allocate-aligned-virtual  ( base )
   else                              ( virt size )
      claim-virtual                  ( base )
   then                              ( base )
;
: release ( virt size -- )  free-virtual-only  ;

: modify  ( virt size mode -- )
   -rot  >page-boundaries bounds  ?do    ( mode )
      dup  i pgmap@  mode>tte  i pgmap!  ( mode )
   mmu-pagesize  +loop  drop             (  )
;

: map  ( phys-lo phys-hi virt size mode -- )
   >r 2dup 2>r  map-pages    (  ) ( r: mode virt size )
   2r> r>  modify            (  )
;

alias unmap  unmap-pages ( virt size -- )

: translate  ( virt -- false | phys-lo phys-hi mode true )
   dup >physical 2dup -1 -1 d=  if  ( virt -1 -1 )
      3drop false
   else                             ( virt phys-lo phys-hi )
      rot pgmap@  tte>mode  true    ( phys-lo phys-hi mode true )
   then
;
pagesize constant pagesize
pagesize " page-size" integer-property

finish-device
device-end

stand-init: Opening the virtual memory package
   " /virtual-memory" open-dev  mmu-node !
;
