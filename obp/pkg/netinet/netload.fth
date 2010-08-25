\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: netload.fth
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
id: @(#)netload.fth 1.2 06/01/06
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

headerless

\ Frequently used strings in arg processing & property creation (space savings)
: "net-config-strategy" ( -- $ )  " net-config-strategy" ;
: "network-boot-file"	( -- $ )  " network-boot-file" ;
: "host-ip"             ( -- $ )  " host-ip" ;
: "router-ip"           ( -- $ )  " router-ip" ;
: "subnet-mask"         ( -- $ )  " subnet-mask" ;
: "hostname"            ( -- $ )  " hostname" ;
: "http-proxy"          ( -- $ )  " http-proxy" ;
: "tftp-server"         ( -- $ )  " tftp-server" ;
: "client-id"           ( -- $ )  " client-id" ;
: "dhcp-retries"        ( -- $ )  " dhcp-retries" ;
: "tftp-retries"        ( -- $ )  " tftp-retries" ;

fload ${BP}/pkg/netinet/args.fth	\ Argument processing
fload ${BP}/pkg/netinet/props.fth	\ Interface to client programs

headerless

: default-config-strategy$ ( -- $ )  " rarp" ;

: init-config-parameters ( -- )
   inaddr-any  my-ip-addr      copy-ip-addr
   inaddr-any  my-netmask      copy-ip-addr
   inaddr-any  router-ip       copy-ip-addr
   inaddr-any  tftp-server-ip  copy-ip-addr

   null$  bootfile    pack drop
   null$  hostname    pack drop
   null$  http-proxy  pack drop
   " /" " local-client-id" get-property client-id pack drop

   default-config-strategy$  config-strategy  pack drop
;

: default-boot-filename ( -- $ )
   use-rarp?  if					( )
      my-ip-addr /ip-addr octet-to-hexascii 		( $ )
   else							( )
      use-dhcp?  if					( )
         dhcp-classid count				( $ )
      else						( )
         null$ 						( null$ )
      then						( $ )
   then							( $ )
;

: init-protocol-stack  ( -- )
   netif-init arp-init ip-init udp-init tcp-init
;

: close-protocol-stack ( -- )
   tcp-close udp-close ip-close arp-close netif-close
;

: configure-protocol-stack ( -- )
   ip-configure
;

: load-bootfile ( adr -- size )
   bootfile count  2dup is-http-url?  if		( adr url$ )
      http-proxy count  wanboot-load			( size )
   else							( adr $ )
      2dup is-tftp-uri?  if				( adr tftpuri$ )
         2dup tftpuri>srv tftp-server-ip inet-aton drop	( adr tftpuri$ )
         tftpuri>file					( adr file$ )
      then						( adr file$ )
      dup 0=  if					( adr null$ )
         2drop  default-boot-filename			( adr file$ )
      then						( adr file$ )
      tftp-server-ip  tftp-load				( size )
   then							( size )
;

\ Perform validity checks on configuration parameters before proceeding
\ to download the file. If using DHCP and TFTP, the TFTP server must 
\ be known. 

: check-netconfig-params ( -- )
   use-dhcp?  bootfile count is-uri? 0=  and if
      tftp-server-ip inaddr-any? if
         ." TFTP server not specified"  -1 throw
      then
   then
;

external

: open ( -- ok? )
   init-protocol-stack
   init-config-parameters
   my-args ['] process-args catch  if
      2drop close-protocol-stack false
   else
      true
   then
;

: close ( -- )  close-protocol-stack ;

: load ( adr -- size )
   publish-network-boot-props				( adr )
   use-rarp?  if					( adr )
      my-ip-addr inaddr-any? if  do-rarp  then		( adr )
   else							( adr )
      use-dhcp?  if  do-dhcp  then			( adr )
   then							( adr )
   check-netconfig-params				( adr )
   configure-protocol-stack				( adr )
   load-bootfile					( size )
;

headers
