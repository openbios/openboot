\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: bad-dev.fth
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
id: @(#)bad-dev.fth 1.4 01/10/25
purpose: 
copyright: Copyright 1999-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Make a bad device node.  Could be inherited FCode like hub, device, etc.

: de-activate-port  ( port -- )
   dup disable-port
\   dup unpower-port		\ RIO ports powered on all the time
   dup clear-connect-change
   clear-port-enable
   clear-hub-change
;

: won't-take-address  ( port speed -- )		\ set-address fails
   drop
   dup de-activate-port
   new-device
   " device" encode-string  " name" property
   ( port ) encode-int  " reg" property
   " disabled" encode-string  " status" property
   finish-device
;

: won't-send-config  ( port speed -- )		\ get-config1 fails; address good?
   won't-take-address
;

: won't-take-config  ( port speed -- )		\ set-config fails; config data ok?
   won't-take-address
;

: won't-send-descriptor  ( port speed -- )	\ get-descriptor fails; config set?
   won't-take-address
;

