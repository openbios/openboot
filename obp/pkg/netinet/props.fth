\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: props.fth
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
id: @(#)props.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Publish parameters used for this boot (or load). Information about
\ arguments processed by the package are reported as chosen properties.
\ For DHCP boots, the DHCP module will publish the contents of the
\ DHCPACK/BOOTREPLY response in /chosen:bootp-response.

headerless

\ Delete stale network boot properties.
: delete-network-boot-props ( -- )
   " /chosen" find-package  if
      my-self >r  0 to my-self
      push-package
         "net-config-strategy"  delete-property
         "network-boot-file"    delete-property
         "host-ip"              delete-property
         "router-ip"            delete-property
         "subnet-mask"          delete-property
         "tftp-server"          delete-property
         "client-id"            delete-property
         "hostname"             delete-property
         "http-proxy"           delete-property
         "bootp-response"       delete-property
      pop-package
      r> to my-self
   then
;

: ?publish-ipaddr-arg ( ipaddr name$ -- )
   rot dup inaddr-any? 0=  if
      inet-ntoa encode-string 2swap set-chosen-property
   else
      3drop
   then
;

: ?publish-string-arg ( value$ name$ -- )
   2swap dup if
      encode-string 2swap set-chosen-property
   else
      2drop 2drop
   then
;

: publish-network-boot-props ( -- )
   delete-network-boot-props
   config-strategy count  "net-config-strategy"  ?publish-string-arg
   bootfile count         "network-boot-file"    ?publish-string-arg
   hostname count         "hostname"             ?publish-string-arg
   http-proxy count       "http-proxy"           ?publish-string-arg
   my-ip-addr             "host-ip"              ?publish-ipaddr-arg
   router-ip              "router-ip"            ?publish-ipaddr-arg
   my-netmask             "subnet-mask"          ?publish-ipaddr-arg
   tftp-server-ip         "tftp-server"          ?publish-ipaddr-arg
   client-id count dup if
      2dup encode-bytes   "client-id"            set-chosen-property
   then  2drop
;

headers
