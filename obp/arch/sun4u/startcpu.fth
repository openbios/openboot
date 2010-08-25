\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: startcpu.fth
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
id: @(#)startcpu.fth 1.18 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: cif-idled-slave ( -- )
   reclaim-machine
   slave-idle-loop
;

\ The cpuid (HW mid used during cross calls) of a processor may be
\ stored as one of three different device node properties: cpuid,
\ portid, or upa-portid.
: phandle>cpu-mid ( phandle -- mid false -or- true )
   >r							( )
   " cpuid" r@ get-package-property if			( )
      " portid" r@ get-package-property if		( )
         " upa-portid" r@ get-package-property if	( )
            r> drop true exit				( true )
         then						( xdr,len )
      then
   then							( xdr,len )
   r> drop						( xdr,len )
   decode-int false 2swap 2drop				( mid 0 )
;

cif: SUNW,start-cpu ( arg addr phandle -- failed? )
   phandle>cpu-mid  if  2drop true  exit  then  ( arg addr mid )
   xcall-start-cpu                              ( failed? )
;

headerless

\ Valid cpu is one with non-zero cpu-status field.
: mid-valid-cpu?  ( portid -- valid? )
   dup mid-ok? if
      >cpu-struct >cpu-status @ 0<>
   else
      drop false
   then
;
headers

\ Per FWARC/2001/745
\ stop the cpu identified by cpuid, using the same cross call mechanism
\ used to park CPUs on an enter or breakpoint.
\ CPUs parked in this fashion may be started using the 'start-cpu' interfaces
\ Slave CPUs will be idled with PIL=F and IE=1, it is assumed that a CPU
\ about to be stopped is idling somewhere with IE=1 also, if not the xcall
\ and the cif call will fail.
\ 
cif: SUNW,stop-cpu-by-cpuid ( cpuid -- failed? )
   dup mid-valid-cpu?					( cpuid ok? )
   over mid@ <> and if					( cpuid )
      ['] cif-idled-slave over xcall-execute 0= if	( cpuid )
         >cpu-struct >cpu-status 			( va )
         d# 20 begin					( va cpuid )
            over @ CPU-IDLING <> over 0<> and while	( va cpuid )
               1- 1 ms					( va ms )
         repeat						( va ms )
         nip 0=	exit					( failed? )
      then						( failed? )
   then							( failed? )
   drop true						( failed )
;

\ Identical to SUNW,start-cpu, except cpuid is given rather than phandle
cif: SUNW,start-cpu-by-cpuid  ( arg addr cpuid -- failed? )
   dup mid-valid-cpu?  if	( arg addr cpuid )
      xcall-start-cpu		( failed? )
   else				( arg addr cpuid )
      3drop true		( true )
   then				( failed? )
;

headers
