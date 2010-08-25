\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cfg-params.fth
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
id: @(#)cfg-params.fth 1.1 04/09/07
purpose: Configuration information global to the package
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

d# 64  constant MAX_CID_LEN	\ Maximum client identifier length 

\ Network configuration information
/ip-addr  instance buffer:  my-ip-addr		\ My IP Address
/ip-addr  instance buffer:  my-netmask		\ Subnet mask
/ip-addr  instance buffer:  router-ip		\ Default router

\ Boot information
d#   8         instance buffer: config-strategy	\ RARP, DHCP or manual
d# 256         instance buffer: bootfile	\ URI or TFTP filename 
d# 256         instance buffer: hostname	\ Hostname to use for DHCP
d#  32         instance buffer: http-proxy	\ HTTP proxy
/ip-addr       instance buffer: tftp-server-ip	\ TFTP server
MAX_CID_LEN 1+ instance buffer: client-id	\ Client identifier

-1  instance value  dhcp-max-retries		\ Max DHCP retries
-1  instance value  tftp-max-retries		\ Max TFTP retries

: use-rarp? ( -- flag )  config-strategy count " rarp" $=  ;
: use-dhcp? ( -- flag )  config-strategy count " dhcp" $=  ;

headers
