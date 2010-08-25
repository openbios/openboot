\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: standini.fth
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
id: @(#)standini.fth 1.10 06/02/07
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc  All Rights Reserved
copyright: Use is subject to license terms.

headerless
chain: stand-init ( -- )
   hex
   0 to #args  0 to args
   true to standalone?
   0 to 'source-id
\ [ifdef] stand-init-debug
\    showstack
\ [then]
;
\ Initial stand-init
[ifdef] stand-init-debug
[ifdef] stand-init-interact
\ Carefull with these.. they are setup to stop at the bottom most
\ stand init and then from there you can chose how many to do before
\ pausing again or if you want to stop at all

variable stop-after stop-after off
variable stop-counter stop-counter off
[then]
[then]

only forth also hidden also forth definitions
headers
[ifdef] stand-init-debug
[ifdef] stand-init-interact
: stop-me? ( -- )
   stop-counter @ stop-after @ = if interact then
   stop-counter @ 1+ stop-counter !
;

: resumes ( n -- ) stop-after tuck @ + swap ! resume ;
: one-resume ( -- ) 1 resumes ;
[then]
[then]

[ifdef] stand-init-debug
: si-type ( text$ -- )
   ??cr ." stand-init: " type ."  -- Stack: " .s cr
;
[then]

headers transient

: stand-init:
   " stand-init" (headerless-chain:)  (make-chain) optional-arg$
[ifdef] stand-init-debug
   ?dup  if 
      compile (")			\ compile token: count text following
      ",				\ compile in raw text to be counted
      compile si-type			\ compile token: stand-init handler
   then
  [ifdef] stand-init-interact
  compile stop-me?
  [then]
[else]
   2drop
[then] \ stand-init-debug
; immediate

resident headerless

stand-init:  First interactive stand-init
;

only forth also definitions
headers
