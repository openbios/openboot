\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: queue.fth
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
id: @(#)queue.fth 1.1 04/09/07
purpose: Generic queue utility functions
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Generic doubly-linked list (queue) implementation. Supports a queue
\ of abstract objects. The queue is maintained within that object.

headerless

struct
    /n  field   >q-next     \ Next entry in queue
    /n  field   >q-prev     \ Previous entry in queue
constant /queue-entry

/queue-entry constant /queue-head

\ Initialize a queue
: queue-init ( qhead -- )  dup  2dup >q-next !  >q-prev ! ;

\ Get to next entry in queue
: queue-next ( qentry -- next )  >q-next @ ;

\ Get to previous entry in queue
: queue-prev ( qentry -- prev )  >q-prev @ ;

\ First entry in queue
: queue-first ( qhead -- qentry )  queue-next ;

\ Last entry in queue
: queue-last ( qhead -- qentry )  queue-prev ;

\ Check if we are at the end of the queue
: queue-end? ( qhead qentry -- flag ) = ;

\ Is the queue empty?
: queue-empty? ( qhead -- flag )  dup queue-first  queue-end? ;

\ Get number of entries in the queue 
: queue-size ( qhead -- qsize )
   0  swap queue-first				( 0 qhead qentry )
   begin  2dup queue-end? 0=  while		( n qhead qentry )
      rot  1+  -rot  queue-next			( n' qhead qentry )
   repeat  2drop				( qsize )
;

\ Insert entry after element "pred". 
: insqueue ( pred qentry -- )
   over queue-next  over >q-next !		\ qentry.next = pred.next
   2dup >q-prev !				\ qentry.prev = pred
   2dup swap queue-next >q-prev !		\ pred.next.prev = qentry
   swap >q-next !				\ pred.next = qentry
;

\ Remove entry from queue
: remqueue ( qentry -- )
   dup  queue-prev  over queue-next >q-prev !
   dup  queue-next  swap queue-prev >q-next !
;

\ Insert element at tail of queue
: enqueue ( qhead qentry -- )
   swap queue-last swap insqueue
;

\ Dequeue element at head of queue
: dequeue ( qhead -- qentry | 0 )
   dup queue-empty? if  drop 0  else  queue-first dup remqueue  then
;

\ Iterate over each item in the queue, performing the desired operation.
: queue-iterate ( qhead acf -- )
   >r  dup queue-first			( qhead qentry ) ( r: acf )
   begin  2dup queue-end? 0=  while	( qhead qentry )
      dup r@ execute  queue-next	( qhead qentry' )
   repeat				( qhead qentry' )
   r> 3drop				( ) ( r: )
;

\ Find a queue entry which matches the specified criteria. "acf" 
\ is executed on each queue entry to determine a match.  The match 
\ routine must have a stack diagram of the form
\       ( ... qentry -- ... match? )
\ Stack items under qentry are values used by the "acf" routine to
\ determine a match.

: find-queue-entry ( ... qhead acf -- ... qentry | ... 0 )
   >r						( ... qhead ) ( r: acf )
   dup queue-first				( ... qhead qentry )
   begin  2dup queue-end? 0=  while		( ... qhead qentry )
      dup r@  2swap >r >r  execute  if		( ... ) ( r: acf qentry qhead )
         r> drop  r>  r> drop exit		( ... qentry ) ( r: )
      then					( ... ) ( r: acf qentry qhead )
      r> r> queue-next				( ... qhead qnext ) ( r: acf )
   repeat					( ... qhead qnext )
   2drop r> drop 0				( ... 0 ) ( r: )
;

headers
