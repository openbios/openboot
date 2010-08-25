\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: action-primitives.fth
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
id: @(#)action-primitives.fth 1.2 03/12/08 13:22:19
purpose: 
copyright: Copyright 2000-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.


transient

  variable sample-v'ble
0 constant sample-const


\  Detect instances of the deplorable practice of changing the
\  value of a constant.
\  If it's being compiled-in to a run-time definition, raise
\  a stink about it!
\  If it's only happening at compile-time, i.e., in interpret
\  mode, let it slide with only a minor whine.
overload: is
   >in @ '					( old->in target-cfa )
   \  Is the target a constant?
   word-type					( old->in target-word-type )
   \  For that matter, let's also keep alert
   \  for attempts at using IS with a variable.
   dup
   (') [ ' sample-v'ble word-type compile, ] =	( old->in targ-w-t v'ble? )
   swap
   (') [ ' sample-const word-type compile, ] =	( old->in v'ble? const? )
   tuck or if					( old->in const? )
      where
      ." Shouldn't use IS with a "		( old->in const? )
      dup if  ." CONSTANT"  else  ." VARIABLE" then
			\  Let it slide if we're in interpret mode.
      state @ if	\  Compiling-in to a run-time definition.
	 ." !  "	\  Raise a stink!	( old->in const? )
	 dup if
	    ." Please redefine  "
	    over >in ! parse-word type
	    ."   as a VALUE"
	 else
	 ." Please use  "
	 over >in ! parse-word type
	 ."  !  instead"  
	 then
	 (compile-time-warning) 		( old->in const? )
      then ." ." cr
   then drop					( old->in )
   >in !	
   postpone is
; immediate

resident
