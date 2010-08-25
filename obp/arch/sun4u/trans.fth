\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: trans.fth
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
id: @(#)trans.fth 1.22 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
: (initial-memory)  ( -- phys.lo phys.hi len )
   hi-memory-base @ pageshift lshift obmem
   hi-memory-size @ pageshift lshift
;
' (initial-memory) to initial-memory

: (.trans) ( ?? va len tte -- ?? )
   push-hex
   .vpt space swap
   d# 12 .r
   d#  9 .r cr
   pop-base
;

headers
: .trans ( -- )  ['] (.trans) vpt-walker  ;

headerless

\ The "translations" property is generated on-demand by walking
\ the vpt and saving the valid translations in a buffer.
\ The last-translation-buffer is used to store the last set of
\ translations retrieved. Once the client takes over the tba
\ obp will return what is stored in the last-translation-buffer.
\ Since the last-translation-buffer is fixed if the number of
\ translations exceeds its size they are clipped.
\
\ If a client makes a request via a cif call, we use the client's
\ buffer to store the translations. This handles cases where the
\ number of translations overflows the buffer allocated for the
\ last-translation-buffer. If the client request is simply for
\ the length of the translations property, we only count them.
\ For client requests we rely on the cif-buf indicating if its 
\ a getprop or getproplen request.
\
\  last-translation-buffer = adr,len of the translations buffer 
\  trans-max = max # translations that fit in allocated buffer
\  trans-cur = current count of translations while walking vpt
\  /trans-entry = # bytes for translation made up of va,size,tte

h# 8010 constant trans-max
h# 18   constant /trans-entry
variable trans-cur  0 trans-cur !
2variable last-translation-buffer  0 0 last-translation-buffer 2!

: alloc-trans-buf ( -- )
   trans-max alloc-mem
   0 last-translation-buffer 2!
;

\ vpt-walker calls with each valid mapping to count # translations 
: count-translations ( adr,len va len tte -- adr,len' )
   3drop /trans-entry +
;

\ vpt-walker calls with each valid mapping to save in buffer
: save-all-translations ( adr,len va len tte -- adr',len' )
   >r >r 2 pick 2 pick + tuck x!
   8 + r> over x!
   8 + r> swap x!
   /trans-entry +
;

\ vpt-walker calls with each valid mapping to save until buffer full
: save-clip-translations ( adr,len va len tte -- adr',len' )
   /trans-entry trans-cur +!
   trans-cur @ trans-max <= if
      >r >r 2 pick 2 pick + tuck x!
      8 + r> over x!
      8 + r> swap x!
      /trans-entry +
   else
      3drop
   then 
;

\ called to generate "translations" property on-the-fly
\ once client takes over the trap table there will be no additional
\ mappings in the vpt so we return the last saved translations
\ (assumes translations property is retrieved at least once before TBA set)
: make-translations ( -- xdr,len )
   obp-control-relinquished? if
      last-translation-buffer 2@			( xdr,len )
   else
      \ if cif-buf has non-zero len then this is cif request
      \ if non-zero adr then this is a getprop call, otherwise its getproplen
      [ also client-services ] cif-buf [ previous ]	( cifbuf )
      2@ dup if						( xdr,len )
         over if					( xdr,len )
            drop 0					( xdr,0 )
            ['] save-all-translations vpt-walker	( xdr,len )
            2dup last-translation-buffer		( xdr,len xdr,len last ) 
            2@ over swap erase				( xdr,len xdr,len buf )
            swap trans-max min				( xdr,len xdr buf len' )
            2dup last-translation-buffer 2!		( xdr,len xdr buf len' )
            cmove					( xdr,len )
         else
            drop 0 ['] count-translations vpt-walker	( xdr,len )
         then
      else
         2drop last-translation-buffer 2@		( xdr,len )
         over swap erase 0				( xdr,0 )
         0 trans-cur !
         ['] save-clip-translations vpt-walker		( xdr,len )
         2dup last-translation-buffer 2!
      then
   then
;

: (allocate-page ( -- pa-lo pa-hi )
   mmu-pagesize dup mem-claim
;
' (allocate-page is allocate-page

create err-invalid-index ," Index must be in the range: 7 < index < 64"

5 actions
action:  drop make-translations ;	( )
action:  drop 2drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

headers

" /virtual-memory" find-device

   " translations" make-property-name  use-actions

   : open  ( -- ok? )
      0 memrange !				\ Clear free list
      d# 20  memrange  more-nodes		\ Get enough nodes "forever"

      \ Create the available memory list from which the firmware is allowed
      \ to dynamically allocate virtual memory.

      monvirtbase  monvirtsize     set-node  fwvirt  insert-after

      monvirtbase  dictionary-top over -	claim-virtual drop
      RAMbase      RAMsize			claim-virtual drop
      mondvmabase  mondvmasize			claim-virtual drop

      \ Create the available memory list from which the firmware
      \ is not allowed to dynamically allocate virtual memory.

      0                          monvirtbase  add-os-piece
      monvirtbase monvirtsize +  1.0000.0000  add-os-piece

      \ Allocate ffff.e000 -> ffff.ffff for safety
      -1 n->l 1 claim-virtual drop

      \ virtual address hole on ultrasparc I/II due to 44 bit MMU support
      \ don't want to add this range to the free list so skip over it
[ifexist] hole-start
      h# 1.0000.0000 hole-start over -  noreclaim-free-virtual
      hole-end dup 0 swap - vpt-size -  noreclaim-free-virtual
[else]
      h# 1.0000.0000 0 over -		noreclaim-free-virtual
[then]

      true
   ;
   caps @ caps off
   : SUNW,itlb-load ( index tte-data vaddr -- )
      rot dup 8 0 #itlb-entries within if	( tte-data vaddr index )
	 -rot mmu-highbits tuck			( index tag tte-data tag )
	 over tte>size bounds  ?do		( index tte-tag tte-data )
	    i h# 20 or demap-itlb		( index tte-tag tte-data )
         mmu-pagesize  +loop			( index tte-tag tte-data )
         -rot 0 swap 				( tte-data index 0 tte-tag )
	 pil@ >r itlb-tar-data! r> pil!		(  )
      else					( tte-data vaddr index )
         err-invalid-index throw
      then					(  )
   ;
   : SUNW,dtlb-load ( index tte-data vaddr -- )
      rot dup 8 0 #dtlb-entries within if	( tte-data vaddr index )
         -rot mmu-highbits  tuck		( index tag tte-data tag )
         over tte>size bounds  ?do		( index tte-tag tte-data )
            i h# 20 or demap-dtlb		( index tte-tag tte-data )
	 mmu-pagesize  +loop			( index tte-tag tte-data )
         -rot 0 swap				( tte-data index 0 tte-tag )
	 pil@ >r dtlb-tar-data! r> pil!		(  )
      else					( tte-data vaddr index )
         err-invalid-index throw
      then					(  )
   ;
   caps !
device-end

stand-init: Allocate translations buffer
   alloc-trans-buf
;

headers
