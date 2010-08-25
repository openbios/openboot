\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: switchcpu.fth
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
id: @(#)switchcpu.fth 1.14 02/09/20
purpose: 
copyright: Copyright 1995-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: cpu-status?	( cpu status -- flag )
   over mid-ok? if
      swap >cpu-struct >cpu-status @ =
   else
      2drop false
   then
;

: cpu-started? ( cpu# -- flag )  CPU-STARTED cpu-status?  ;
: cpu-idled?   ( cpu# -- flag )  CPU-PARKED  cpu-status?  ;
: idle-cpu ( cpu# -- )
   dup cpu-started?  over mid@ <>  and if	( cpu# )
      xcall-idle-cpu				( fail? )
   then  drop					( )
;
: resume-cpu ( cpu# -- )
   dup cpu-idled?  over mid@ <>  and if		( cpu# )
      xcall-resume-cpu				( fail? )
   then  drop					( )
;

: idle-other-cpus ( -- )	['] idle-cpu  do-foreach-cpu  ;
: resume-other-cpus ( -- )	['] resume-cpu  do-foreach-cpu ;

headers

: switch-cpu ( cpu# -- )
   \ Simply return if cpu# is the currently running CPU
   dup mid@ =  if  drop exit  then
   dup mid-ok? if				( cpu# )
      dup xcall-get-pc  0= if			( cpu# pc )
         drop					( cpu# )
         dup idle-cpu				( cpu# )
         dup >cpu-struct >cpu-status @		( cpu# status )
         CPU-IDLING <>  if			( cpu# )
            d# 5 0 do dup cpu-idled? ?leave d# 100 ms loop
            dup cpu-idled?			( cpu# switch? )
         else					( cpu# )
            true				( cpu# true )
         then					( cpu# switch? )
         if  master-release-prom  else  drop  then
      then
   then						( )
  drop ." CPU not responding" cr
;

chain: enterforth-chain
   idle-other-cpus
;

chain: go-chain
   resume-other-cpus
;

