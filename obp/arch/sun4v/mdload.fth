\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mdload.fth
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
id: @(#)mdload.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0 value reset-reason

: power-on-reset? ( -- flag )  reset-reason 0=  ;

headers

: pdscan-node ( ?? acf node -- ?? )
   (pdselect-node) 					( ?? acf )
   begin
      pdnext-prop ?dup while				( ?? acf ptr )
         swap >r r@ execute				( ?? )
         r>						( ?? acf )
   repeat drop
;

headerless
\
\ This assumes the acf is an action object..
\
: pdget-required-property ( name$ node acf -- )
   >r >r 2dup					( prop$ prop$ node )
   -1 r> pdget-prop ?dup if			( prop$ node )
      pdentry-data@ r> do-is 2drop		( )
   else						( prop$ )
      r> drop					( prop$ )
      cmn-fatal[ " Missing required property: %s" ]cmn-end
   then
;

2 2 h# 01 0 hypercall: hv-get-pd ( len buf -- len status )

stand-init: Get partition Description
   \ Hcall will fail, and return the actual length
   0 0 hv-get-pd drop					( n )
   dup h# 1f + alloc-mem				( va )
   h# 20 round-up is pd-data				( n )
   pd-data >physical drop  hv-get-pd  if		( len )
      cmn-fatal[ " Failed to read machine description" ]cmn-end
   then  drop						( )
   
   " reset-reason" pd-rootnode ['] reset-reason pdget-required-property
   power-on-reset? if
      \ On 'power-on' ie guest first init memory is always clean
      memory-clean? on
   then
;

