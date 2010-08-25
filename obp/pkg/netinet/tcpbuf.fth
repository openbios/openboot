\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tcpbuf.fth
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
id: @(#)tcpbuf.fth 1.1 04/09/07
purpose: TCP buffer management routines
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ TCP's send and receive buffers are maintained as circular buffers.
\ The buffer sizes reflect the corresponding initial window sizes.
\ Sequence space computations are translated into corresponding buffer
\ addresses when accessing data.

headerless

struct
   /n  field  >tcpbuf-adr	\ Pointer to buffer
   /l  field  >tcpbuf-size	\ Buffer size
   /l  field  >tcpbuf-start	\ Offset to start of valid data
   /l  field  >tcpbuf-count	\ Data character count
constant /tcp-buffer

: tcpbuf-adr@   ( tcpbuf -- adr )   >tcpbuf-adr   @ ;
: tcpbuf-size@  ( tcpbuf -- size )  >tcpbuf-size  l@ ;

: tcpbuf-count@ ( tcpbuf -- n )  >tcpbuf-count l@ ;
: tcpbuf-count! ( n tcpbuf -- )  >tcpbuf-count l! ;

: tcpbuf-count+! ( tcpbuf n -- )
   over tcpbuf-count@ + swap tcpbuf-count!
;

: tcpbuf-start@ ( tcpbuf -- offset )  >tcpbuf-start l@ ;
: tcpbuf-start! ( offset tcpbuf -- )  >tcpbuf-start l! ;

: tcpbuf-start+! ( tcpbuf n -- )
   over tcpbuf-start@ +  over tcpbuf-size@ mod  swap tcpbuf-start!
;

\ Get amount of free space in buffer.
: tcpbuf-space@ ( tcpbuf -- n )
   dup tcpbuf-size@  swap tcpbuf-count@ -
;

\ Allocate a TCP buffer.
: tcpbuf-init ( tcpbuf bufsize -- )
   2dup alloc-mem  swap >tcpbuf-adr   !
                   over >tcpbuf-size  l!
   0               over >tcpbuf-start l!
   0               swap >tcpbuf-count l!
;

\ Free TCP buffer resources.
: tcpbuf-free ( tcpbuf -- )
   dup tcpbuf-adr@  swap tcpbuf-size@  free-mem
;

\ Convert offset from start of valid data in the buffer to an index
\ from start of the buffer.
: tcpbuf-offset>adrindex ( tcpbuf offset -- index )
   over tcpbuf-start@ +  swap tcpbuf-size@ mod
;

\ Copy 'len' bytes of data from 'adr' into the TCP buffer, starting at 
\ 'offset' bytes from the current start of valid data in the buffer, 
\ handling wraparounds as necessary. The actual amount of data copied
\ is limited by the free space available in the buffer.

: (tcpbuf-write) ( tcpbuf index adr len -- )
   >r >r  >r tcpbuf-adr@ r> ca+  r> swap  r> move
;

: tcpbuf-write ( tcpbuf offset adr len -- len' )
   3 pick tcpbuf-space@ min  dup >r	( buf offset adr len' ) ( r: len' )
   2swap				( adr len' buf offset )
   over swap tcpbuf-offset>adrindex	( adr len' buf index )
   2swap 2over				( buf index adr len' buf index )
   swap tcpbuf-size@ swap - over min	( buf index adr len' n )
   tuck - >r				( buf index adr n ) ( r: len' rem )
   2over 2over (tcpbuf-write)		( buf index adr n )
   + nip 0 swap r> (tcpbuf-write)	( ) ( r: len' )
   r>					( len' ) ( r: )
;

\ Copy 'len' bytes of data starting at 'offset' bytes from current 
\ start of valid data in the TCP buffer to the address at 'adr',
\ handling buffer wraparounds as necessary. The actual amount of 
\ data read is limited by the amount of data at hand.

: (tcpbuf-read) ( tcpbuf index adr len -- )
   >r >r  >r tcpbuf-adr@ r> ca+  r> r> move
;

: tcpbuf-read ( tcpbuf offset adr len -- len' )
   3 pick tcpbuf-count@ min  dup >r	( buf offset adr len' ) ( r: len' )
   2swap				( adr len' buf offset )
   over swap tcpbuf-offset>adrindex	( adr len' buf index )
   2swap 2over				( buf index adr len' buf index )
   swap tcpbuf-size@ swap - over min	( buf index adr len' n )
   tuck - >r				( buf index adr n ) ( r: len' rem )
   2over 2over     (tcpbuf-read)	( buf index adr n )
   + nip 0 swap r> (tcpbuf-read)	( ) ( r: len' )
   r>					( len' ) ( r: )
;

\ Discard n bytes from start of buffer.
: tcpbuf-drop ( tcpbuf n -- )
   over tcpbuf-count@ min  2dup tcpbuf-start+!  negate tcpbuf-count+!
;

headers
