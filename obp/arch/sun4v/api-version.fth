\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: api-version.fth
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
id: @(#)api-version.fth 1.3 06/05/10 
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

fload ${BP}/arch/sun4v/hv-errcode.fth 

struct
   /w    field  >id          \ api group id
   /w    field  >major       \ major number
   /w    field  >minor       \ minor number
constant /apiver-info

\ htrap number
h# 7f constant core-trap#

\ htrap function numbers
h# 00 constant api-set-version-func#
h# 01 constant api-putchar-func#  \ Is an alias for fast-trap func cons-putchar
h# 02 constant api-exit-func#     \ Is an alias for fast-trap func mach-exit
h# 03 constant api-get-version-func#


\ Hypervisor calls
2 3 api-set-version-func# core-trap#
    hypercall: api-set-version  ( mnr mjr grp -- amnr err )

3 1 api-get-version-func# core-trap#
    hypercall: api-get-version  ( grp -- amnr amjr err )

\ The hypervisor and OBP are tightly coupled and are released together in
\ the same package so the minors numbers in the OBP table are the largest
\ available numbers supported in the hypervisor. We don't need to save the
\ minor numbers because the numbers returned from hypervisor are expected
\ to match those of OBP list.
\
stand-init: Configure required API call availability
   apigroup-ptr dup #api /apiver-info * + swap do ( )
      i >minor w@                                 ( mnr )
      i >major w@                                 ( mnr mjr )
      i >id w@                                    ( mnr mjr grp )
      api-set-version hvcheck drop                ( )
   /apiver-info +loop                             ( )
;

headers
\ SUNW,set-sun4v-api-version
\
\    Input:  api group id
\            major number
\            requested minor number
\    Output: hypervisor call error status
\            supported minor number
\    - Return the smaller of the requested minor numbers. (This might change
\      and still TBD)
\
\    - Note about selecting the smaller minor number:
\        Because guest components are decoupled, different components may 
\        want to choose different versions of the same API group. The 
\        recommendation is that guests should resolve difference as follows:
\ 
\        * If two different components request services in different API 
\          groups, they may interact freely.
\        * If two different components request services in the same API 
\          group, but with different major numbers, one of the components 
\          must be denied the service.
\        * If two different components request services in the same API 
\          group, with the same major number, but with different minor 
\          numbers, the two components should be constrained to use the 
\          smaller of the requested minor numbers.
\
cif: SUNW,set-sun4v-api-version  ( mnr mjr grp -- amnr err )
   apigroup-ptr dup #api /apiver-info * + swap do   ( mnr mjr grp )
      dup i >id w@ = if                             ( mnr mjr grp )
         over i >major w@ = if                      ( mnr mjr grp )
            rot i >minor w@ min -rot                ( mnr' mjr grp )
            leave                                   
         else                                       ( mnr mjr grp )
            3drop 0 HV-EBUSY                        ( amnr err )
            unloop exit                             
         then
      then
   /apiver-info +loop                               ( mnr' mjr grp )
   api-set-version                                  ( amnr err )
;

\ SUNW,get-sun4v-api-version
\
\    Input:  api group id
\    Output: hypervisor call error status
\            major number
\            minor number
\
\    - Return the API version info as reported by the hypervisor.
\
cif: SUNW,get-sun4v-api-version  ( grp -- amnr amjr err )
   api-get-version
;

headerless

stand-init: Special for compatibility w/ old Solaris
   0 1 niagara-id api-set-version hvcheck drop  ( )
   0 1 niagara-crypto-service-id api-set-version hvcheck drop     ( )
   0 1 intr-id api-set-version hvcheck drop ( )
;
