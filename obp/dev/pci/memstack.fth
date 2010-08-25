\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: memstack.fth
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
id: @(#)memstack.fth 1.3 97/10/09
purpose: PCI bus package
copyright: Copyright 1997 Sun Microsystems Inc  All Rights Reserved

struct
   /n field >stack.next
   /n field >stack.mem-list
   /n field >stack.io-list
   /n field >stack.bar-info
constant /stacknode

variable stack-base stack-base off

: get-pointers ( -- reg mem io )
   bar-struct-addr pci-memlist @  pci-io-list @
;
: set-pointers ( reg mem io -- )
   pci-io-list !  pci-memlist ! to bar-struct-addr
;

: push-stack ( reg new-mem new-io -- )
   /stacknode alloc-mem >r		( reg new-mem new-io )
   get-pointers				( reg new-mem new-io reg mem io )
   r@ >stack.io-list !			( reg new-mem new-io reg mem )
   r@ >stack.mem-list !			( reg new-mem new-io reg )
   r@ >stack.bar-info !			( reg new-mem new-io )
   stack-base @ r@ >stack.next !	( reg new-mem new-io )
   set-pointers				( -- )
   r> stack-base !			( -- )
;

: pop-stack ( -- reg prev-mem prev-io )
   get-pointers				( reg prev-mem prev-io )
   stack-base @	>r			( -- )
   r@ >stack.next @ stack-base !	( -- )
   r@ >stack.bar-info @			( reg prev-mem prev-io reg )
   r@ >stack.mem-list @			( reg prev-mem prev-io reg mem )
   r@ >stack.io-list @			( reg prev-mem prev-io reg mem )
   set-pointers				( reg prev-mem prev-io )
   r> /stacknode free-mem		( -- )			
;
