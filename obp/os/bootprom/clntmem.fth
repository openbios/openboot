\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: clntmem.fth
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
id: @(#)clntmem.fth 1.18 03/07/15
purpose: Implements client interface "claim" and "release"
copyright: Copyright 1994-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
variable memory-node
variable mmu-node
headers
' memory-node  " memory" chosen-variable
' mmu-node     " mmu"    chosen-variable

headerless

\ Build the memory and mmu node allocation and mapping methods using
\ a method builder that saves the ihandle, crash acf and method name at
\ compile time. The runtime behavior finds the crash acf on the first
\ call, does a lookup of the method with the ihandle and replaces
\ the crash acf with the method acf. Future calls then use the cached
\ acf for faster performance.
\
\ the basic layout is:
\	[n0]	variable containing ihandle for node
\	[n1]	['] crash for lookup else method acf
\	[n2]+	method$ name

transient
: (method-builder)
   create
   token,		\ save the variable
   ['] crash token,	\ not referenced yet
   parse-word ",	\ save the string
;
resident headerless

\ this routine is never going to be used at runtime because the defining
\ words have been disposed, only the does> clause matters.
: (method:) ( acf -- )
   does>
   >r					( ?? )
   r@ token@ execute @			( ?? ihandle )   
   r@ ta1+ token@ dup ['] crash = if	( ?? acf )
      drop dup				( ?? ihandle ihandle )
      r@ 2 ta+ count			( ?? ihandle ihandle method$ )
      rot ihandle>phandle find-method	( ?? ihandle,acf,true | ihandle,0 )
      0= abort" FATAL: lookup failed"	( ?? )
      dup r@ ta1+ token!		( ?? )
   then					( ?? ihandle acf )
   r> drop swap call-package		( ?? )
;

transient
: mem-method: \ method-name method
   ['] memory-node (method-builder) (method:)
;

: mmu-method: \ method-name method
   ['] mmu-node (method-builder) (method:)
;
resident

\ mem-claim  ( [ phys.lo phys.hi ] size align -- base.lo base.hi )
mem-method: mem-claim claim

\ mem-release  ( phys.lo phys.hi size -- )
mem-method: mem-release release

\ mem-mode     (  -- mode )
mem-method: mem-mode mode

\ mmu-map       ( phys-lo phys-hi virt size mode -- )
mmu-method: mmu-map map

\ mmu-claim     ( [ virt ] size align -- base )
mmu-method: mmu-claim claim

\ mmu-release   ( virt size -- )
mmu-method: mmu-release release

\ mmu-unmap     ( virt size -- )
mmu-method: mmu-unmap unmap

\ mmu-translate ( virt -- false | phys-lo phys-hi mode true )
mmu-method: mmu-translate translate

\ mmu-pagesize  ( -- n )
\ mmu-method: mmu-pagesize pagesize
alias mmu-pagesize pagesize

: mmu-lowbits   ( adr1 -- lowbits  )  mmu-pagesize  1-         and  ;
: mmu-highbits  ( adr1 -- highbits )  mmu-pagesize  1- invert  and  ;

: (map)  ( size phys space virthint mode -- virtual )
   >r                                ( size phys space virtual ) ( r: mode )
   ?dup  if                          ( size phys space virtual ) ( r: mode )
      2 pick mmu-lowbits  over mmu-lowbits
      <> abort" Inconsistent page offsets"
      3 pick  0  mmu-claim           ( size phys space virtual ) ( r: mode )
   else                              ( size phys space )         ( r: mode )
      over mmu-lowbits  3 pick +     ( size phys space size' )   ( r: mode )
      mmu-pagesize  mmu-claim        ( size phys space virtual ) ( r: mode )
   then                              ( size phys space virtual ) ( r: mode )

   2 pick mmu-lowbits        ( size phys space virtual offset )  ( r: mode )
   over mmu-highbits +       ( size phys space virtual virtual' )  ( r: mode )
   r> swap >r                ( size phys space virtual mode ) ( r: virtual' )
   4 roll  swap  mmu-map     ( )  ( r: virtual' )
   r>                        ( virtual' )
;

: (allocate-aligned)  ( alignment size virthint mode -- virtual )
   2 pick 0=  if  2drop 2drop 0 exit  then
   >r rot >r                  ( size virthint ) ( r: mode align )
   2dup mmu-lowbits +         ( size virthint size' ) ( r: mode align )
   dup r> 1 max               ( size virthint size' size' align ) ( r: mode)
   mem-claim                  ( size virthint size' p.lo p.hi ) ( r: mode )

   \ Now we map in the allocated memory
   rot r> 2over swap          ( size virthint p.lo p.hi size' mode p.hi p.lo )
   rot  2swap  2>r 2>r        ( size virthint  p.lo,hi ) ( r: size' p.hi,lo md )

   -rot over mmu-lowbits +     ( size p.hi virthint p.lo )  ( r: " )
   -rot                        ( size p.lo' p.hi virthint ) ( r: " )

   r>  ['] (map)  catch  ?dup  if  ( 4*x error-code ) ( r: size' p.hi,lo)

      \ If the mapping operation fails, we give back the
      \ physical memory that we have already allocated.

      nip nip nip nip         ( error-code )
      r> r> r> mem-release    ( error-code )
      throw                    \ Propagate the error

   then                        ( virtual )  ( r: size p.hi,lo )
   r> r> r> 3drop              ( virtual )
;
: allocate-aligned  ( alignment size virthint -- virtual )
   mem-mode  ['] (allocate-aligned) catch  if  3drop 0  then
;

headers

cif: claim  ( align size virt -- base )
   rot  dup  if         ( size virt align )
      nip  swap 0       ( align size 0 )
   else
      drop  1 -rot      ( size virt )
   then                 ( align size virthint )
   allocate-aligned     ( base )
;
cif: release  ( size virt -- )
   swap >r dup mmu-translate  if  ( virt phys.lo phys.hi mode ) ( r: size )
      drop 2dup memory?  if       ( virt phys.lo phys.hi )      ( r: size )
	 r@ mem-release           ( virt )                      ( r: size )
      else                        ( virt phys.lo phys.hi )      ( r: size )
	 2drop                    ( virt )                      ( r: size )
      then  r>                    ( virt size )
   then  2dup  mmu-unmap  mmu-release  (  )
;


headerless
also client-services
alias cif-release release
alias cif-claim   claim
previous

headers
