\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hv-errcode.fth
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
id: @(#)hv-errcode.fth 1.1 06/02/28
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Hypervisor api error codes
    0 constant HV-EOK            \ successful return
    1 constant HV-ENOCPU         \ invalid cpu id
    2 constant HV-ENORADDR       \ invalid real address
    3 constant HV-ENOINTR        \ invalid interrupt id
    4 constant HV-EBADPGSZ       \ invalid pagesize encoding
    5 constant HV-EBADTSB        \ invalid TSB description
    6 constant HV-EINVAL         \ invalid argument
    7 constant HV-EBADTRAP       \ invalid function number
    8 constant HV-EBADALIGN      \ invalid address alignment
    9 constant HV-EWOULDBLOCK    \ cannot complete operation without blocking
d# 10 constant HV-ENOACCESS      \ no access to specified resource
d# 11 constant HV-EIO            \ I/O error
d# 12 constant HV-ECPUERROR      \ cpu is in error state
d# 13 constant HV-ENOTSUPPORTED  \ function not supported
d# 14 constant HV-ENOMAP         \ no mapping found
d# 15 constant HV-ETOOMANY       \ too many items specified / limited reached
d# 16 constant HV-ECHANNEL       \ invalid LDC channel
d# 17 constant HV-EBUSY          \ operation failed as resource is otherwise
                                 \ busy

: hvcheck ( ?? n -- )
   case
      HV-EOK           of exit endof
      HV-ENOCPU        of " Invalid CPU id" endof
      HV-ENORADDR      of " Invalid real address" endof
      HV-ENOINTR       of " Invalid interrupt id" endof
      HV-EBADPGSZ      of " Invalid page size encoding" endof
      HV-EBADTSB       of " Invalid TSB description" endof
      HV-EINVAL        of " Invalid argument" endof
      HV-EBADTRAP      of " Invalid function number" endof
      HV-EBADALIGN     of " Invalid address alignment" endof
      HV-EWOULDBLOCK   of " Call would block" endof
      HV-ENOACCESS     of " No such device/address (service)" endof
      HV-ENOACCESS     of " No access to specified resource" endof
      HV-EIO           of " I/O error" endof
      HV-ECPUERROR     of " CPU is in error state" endof
      HV-ENOTSUPPORTED of " Function not supported" endof
      HV-ENOMAP        of " No mapping found" endof
      HV-ETOOMANY      of " Too many items specified / limit reached" endof
      HV-ECHANNEL      of " Invalid LDC channel" endof
      HV-EBUSY         of " Operation failed as resource is otherwise busy" endof
      " Unknown error"
   endcase
   cmn-error[ " %s" ]cmn-end abort
;
