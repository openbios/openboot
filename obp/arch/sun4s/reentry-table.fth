\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: reentry-table.fth
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
id: @(#)reentry-table.fth 1.8 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ the Reentry Eligibility Table is an array of 8 byte words
\ indexed by CPU ID.  This table needs to be created at
\ compile time since POST expects the OBP dictionary entry be
\ locked in I-TLB.  See FWARC/2000/022 for details.
max-mondo-target# /x * constant /reentry-flag-table
/x (align) here /reentry-flag-table allot
dup /reentry-flag-table erase
origin- ROMbase + constant reentry-flag-table

\ mark the given CPU as eligible for reset reentry
: enable-reentry  ( mid -- )
   dup 0 max-mondo-target# within  if		( mid )
      /x * reentry-flag-table + true swap x!	( )
   else						( mid )
      drop					( )
   then						( )
;

\ mark the given CPU as ineligible for reset reentry
: disable-reentry  ( mid -- )
   dup 0 max-mondo-target# within  if		( mid )
      /x * reentry-flag-table + false swap x!	( )
   else						( mid )
      drop					( )
   then						( )
;

stand-init: Enable Reset Reentry Table
   \ slave CPUs will enable reentry for themselves
   mid@ enable-reentry
   reentry-flag-table ROMbase !
;
