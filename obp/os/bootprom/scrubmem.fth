\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: scrubmem.fth
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
id: @(#)scrubmem.fth 2.39 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Clear memory to establish valid check bits.
\ This depends on the availmemory list organization defined in memlist.fth

defer scrub-bank  ( padr-lo padr-hi size -- )

headerless
stand-init: Init scrub-bank
   fpu-enabled? if  ['] bclear-memory-4MB   else  ['] clear-memory  then
   is scrub-bank
;

" /memory" find-device

: scrub-4meg ( pa.lo pa.hi len -- )  lock[ 4meg min  scrub-bank  ]unlock ;

: .megs  ( n -- )
   push-decimal				( n ) ( r: base )
   1meg round-up  1meg /		\ Modulo 1MB
   dup h# fff and if			\ Even GB count?
      5 u.r ." MB"			\ No, list in MegaBytes
   else					( n ) ( r: base )
      d# 10 rshift 5 u.r ." GB"		\ Yes, list in GigaBytes
   then					( ) ( r: base )
   pop-base				( )
;

: next-chunk ( adr,len chunk -- adr+chunk len+chunk )
   2dup >  if  /string  exit  then
   drop + 0
;

: .mem-progress  ( megabytes -- megabytes )
   \ d# 29 to match ".5GB" check in 'scrub-node' below
   dup d# 29 rshift 4 mod " -/|\" drop + c@ emit 1 backspaces
;

: .initializing  ( pa.lo pa.hi len -- pa.lo pa.hi len )
   min+mode?  if
      3dup nip				( pa.lo pa.hi len pa.lo len )
      ." Initializing " .megs ."  of memory at addr "  .nx
      1 spaces				( pa.lo pa.hi len )
   then
;

\ Routine for use with find-node.  Scrubs the nodes memory, returning
\ false so that every node will be processed.
: scrub-node  ( node-adr -- false )
   node-range  pages>phys-adr,len       ( pa.lo pa.hi len )
   .initializing                        ( pa.lo pa.hi len )
   swap >r				( pa.lo len ) ( r: pa.hi )
   min+mode?  -rot			( flag pa.lo len ) ( r: pa.hi )

   begin				( flag pa.lo len ) ( r: pa.hi )
      2dup  r@ swap  scrub-4meg 	( flag pa.lo len ) ( r: pa.hi )
      4meg next-chunk 			( flag pa.lo+ len- ) ( r: pa.hi )
      2 pick  if			( flag pa.lo+ len- ) ( r: pa.hi )
	 \ Slow down idle chatter...only every .5GB or so...often
	 \ enough to indicate "still alive" yet not slow us down
	 dup h# 1ff00000 and 0= if	( flag pa.lo+ len- ) ( r: pa.hi )
	    .mem-progress		( flag pa.lo+ len- ) ( r: pa.hi )
	 then				( flag pa.lo+ len- ) ( r: pa.hi )
      then				( flag pa.lo+ len- ) ( r: pa.hi )
      dup 0<=				( flag pa.lo+ len- ) ( r: pa.hi )
   until				( flag pa.lo+ len- ) ( r: pa.hi )
   r> 3drop false			( flag false )
   swap if  (cr d# 70 spaces (cr  then  ( flag false )
;

headers

: scrub-memory  ( -- )
   memory-clean? @  0=  if
      physavail ['] scrub-node find-node 2drop
      first-phys-avail  drop  0  4meg  map-pages
      memory-clean? on
      ['] clear-memory is clear-mem
   then
;

device-end
