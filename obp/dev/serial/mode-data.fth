\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mode-data.fth
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
\ id: @(#)mode-data.fth 1.4 00/03/15
\ purpose: 
\ copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

headerless
\ Some handshake definitions
h# 00 constant hs.none
h# 01 constant hs.sw
h# 02 constant hs.hw

\ Parity definitions
h# 00 constant p.none
h# 01 constant p.even
h# 02 constant p.odd
h# 03 constant p.mark
h# 04 constant p.space

headers
\
\ Some safety values, these are values so a driver can override them..
\
d# 300		value min-baud
d# 38400	value max-baud

headerless
0 instance value uart
0 instance value mask-#data
0 instance value dtr-rts-on?
0	   value uartbase
0	   value opencount
0          value channel-init

defer rs-mode-decode	' false  is rs-mode-decode
defer rs-mode-select	' drop   is rs-mode-select

: /string ( adr len cnt -- adr+cnt len-cnt ) tuck - -rot + swap ;
