\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: chipmap.fth
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
id: @(#)chipmap.fth 1.4 02/11/07
purpose: 
copyright: Copyright 1997, 2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

d# 15 constant max-ports	\ ohci has max 15 downstream ports

\ ohci registers

struct
	       4 field hc-rev
	       4 field hc-control
	       4 field hc-cmd-status
	       4 field hc-int-status
	       4 field hc-int-enable
	       4 field hc-int-disable
	       4 field hc-hcca
	       4 field hc-period-current
	       4 field hc-control-head
	       4 field hc-control-current
	       4 field hc-bulk-head
	       4 field hc-bulk-current
	       4 field hc-done-head
	       4 field hc-fm-interval
	       4 field hc-fm-remaining
	       4 field hc-fm#
	       4 field hc-period-start
	       4 field hc-ls-threshold
	       4 field hc-roota
	       4 field hc-rootb
	       4 field hc-root-status
   max-ports 4 * field hc-port-status

( chip reg. size ) constant /controller

0 value chip-base

: map-regs  ( -- )
   my-address my-space h# 200.0010 + /controller " map-in" $call-parent
   to chip-base
   my-space 4 +  " config-w@" $call-parent
   h# 146 or
   my-space 4 +  " config-w!" $call-parent
;

: unmap-regs  ( -- )
   0 my-space 4 +  " config-w!" $call-parent
   chip-base /controller " map-out" $call-parent
   -1 to chip-base
;

: show-reg  ( addr -- )
   rl@
   <# u# u# u# u# ascii . hold u# u# u# u# u#>
   type
;

\ XXX this is really crude
: show-rio  ( -- )		\ display current values in chip
   cr
   chip-base  4 +  h# 10 bounds  do	\ skip hc-rev
      i show-reg 4 spaces
   4 +loop
   cr
   chip-base h# 14 +  h# 10  bounds  do
      i show-reg 4 spaces
   4 +loop
   cr
   chip-base h# 24 +  h# 10  bounds  do
      i show-reg 4 spaces
   4 +loop
   cr
   chip-base h# 34 +  h# 10  bounds  do
      i show-reg 4 spaces
   4 +loop
   cr
   chip-base h# 44 +  h# 10  bounds  do
      i show-reg 4 spaces
   4 +loop
   cr
   chip-base h# 54 +  h# 10  bounds  do
      i show-reg 4 spaces
   4 +loop
\   cr
\   chip-base h# 60 + show-reg
   cr
;

\ host controller communications area

struct
    h# 80 field interrupt-table
        2 field frame#
        2 field pad1
        4 field done-head
   d# 120 field reserved1

( hcca size ) constant /hcca

0 value hcca
0 value dev-hcca

\ hcca must also be synced before getting the done-q pointer.
\ XXX what happens if the controller is writing the frame# while syncing?
: sync-hcca  ( -- )
   sync-mem
;

\ XXX must be aligned on 256 byte bdry.  ohci 7.2.1
: map-hcca  ( -- )
   /hcca get-chunk  to hcca
   hcca virt>dev  to dev-hcca
;

: unmap-hcca  ( -- )
   -1 to dev-hcca
   hcca /hcca give-chunk
   -1 to hcca
;

: setup-hcca  ( -- )
   dev-dummy-endpoints				\ setup interrupt table
   hcca interrupt-table  d# 32 la+
   hcca interrupt-table  do
      dup  i le-l!  /endpoint +
   /l +loop  drop
   sync-hcca
;

: dump-hcca  ( -- )  ;				\ XXX may not be needed

: make-structs  ( -- )
   map-hcca
   make-dummies
   setup-hcca
;

: dump-structs  ( -- )
   dump-hcca
   dump-dummies
   unmap-hcca
;

\ XXX is there a way to force dma-map-in to give aligned addresses?  need
\ 16 byte alignment and 32 byte alignment.  Can over allocate and then
\ use an aligned part of the total allocation.
