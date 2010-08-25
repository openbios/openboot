\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadconfig.fth
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
id: @(#)loadconfig.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

fload ${BP}/pkg/confvar/loadcvar.fth                \ NVRAM device support
fload ${BP}/pkg/confvar/definitions/standard.fth    \ standard data types

fload ${BP}/arch/sun4u/config/reset-recovery.fth

fload ${BP}/pkg/confvar/definitions/confvoc/verbosity-types-voc.fth
: verbosity-default ( -- adr,len ) " min" ;

fload ${BP}/arch/sun4v/niagara/fixed.fth
fload ${BP}/arch/sun4u/config/nvramrc.fth

" disk net"   d# 256  config-string  boot-device
" "           d# 128  config-string  boot-file
" boot"       d# 64   config-string  boot-command
" "             d# 512  config-long-string      network-boot-arguments

true	              config-flag    auto-boot?

default-load-base     config-int     load-base

false   config-flag    auto-boot-on-error?

" virtual-console"  d# 32  config-string input-device
" virtual-console"  d# 32  config-string output-device

headers
: virtual-console " /virtual-devices/console" ;
headerless

' virtual-console  is fallback-device

fload ${BP}/arch/sun4u/config/console.fth

" 9600,8,n,1,-" d# 16 config-string ttya-mode

fload ${BP}/arch/sun4u/config/termemu.fth
fload ${BP}/arch/sun4u/config/banner.fth
fload ${BP}/arch/sun4u/config/scsi-id.fth

false   config-flag     fcode-debug?
true   	config-flag     local-mac-address?

\ Install hook for fcode-debug?
' fcode-debug?  to (fcode-debug?)

fload ${BP}/pkg/confvar/interfaces/standard.fth     \ support consumers

: set-mfg-defaults ( -- )
   cmn-type[ " Setting diag-switch? NVRAM parameter to true" ]cmn-end
   true to diag-switch?
;
' set-mfg-defaults is reset-config

: pdnvupdate ( ptr -- )
   dup pdentry-tag@ PROP_ARC = if  drop exit then
   >r r@ pdentry-data@
   r@ pdentry-name@ 2dup ['] options search-wordlist if
      nip nip set r> drop
   else
      2drop r> pdentry-tag@ PROP_VAL = if  drop else  2drop  then
   then
;

stand-init: Update NVRAM with PD data
   " options" 0 pdfind-node ?dup if
      ['] pdnvupdate swap pdscan-node
   then
;
