\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: dhcp-h.fth
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
id: @(#)dhcp-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

struct
   /c       field  >dhcp-op		\ Message opcode
   /c       field  >dhcp-htype		\ Hardware address type
   /c       field  >dhcp-hlen		\ Hardware address length
   /c       field  >dhcp-hops		\ Used by relay agents 
   /l       field  >dhcp-xid		\ Transaction ID
   /w       field  >dhcp-secs		\ Time since boot began
   /w       field  >dhcp-flags		\ Flags
   /ip-addr field  >dhcp-ciaddr		\ Client IP address
   /ip-addr field  >dhcp-yiaddr		\ "Your" IP address (from server)
   /ip-addr field  >dhcp-siaddr		\ Boot server IP address
   /ip-addr field  >dhcp-giaddr		\ Relay agent IP address
   d# 16    field  >dhcp-chaddr		\ Client hardware address
   d# 64    field  >dhcp-sname		\ Boot server hostname
   d# 128   field  >dhcp-file		\ Boot filename
   d# 4     field  >dhcp-cookie		\ Magic cookie
   0        field  >dhcp-options	\ Options, variable length
constant /dhcp-header

d# 300  constant  DHCP_MIN_PKTLEN	\ Minimum length of DHCP/BOOTP packet

\ Message opcode types
1     constant	BOOTREQUEST		\ BOOTP Request Opcode
2     constant  BOOTREPLY		\ BOOTP Reply Opcode

\ Magic cookie
h# 63.82.53.63 constant	BOOTMAGIC 	\ RFC 1048 Magic Cookie

\ DHCP message types
1     constant	DHCP_DISCOVER
2     constant	DHCP_OFFER
3     constant	DHCP_REQUEST
d# 4  constant	DHCP_DECLINE
d# 5  constant	DHCP_ACK
d# 6  constant	DHCP_NAK
d# 7  constant	DHCP_RELEASE
d# 8  constant	DHCP_INFORM

\ Generic DHCP option structure
struct
   1  field  >dhcpopt-code
   1  field  >dhcpopt-len
   0  field  >dhcpopt-data
constant /dhcp-option

\ DHCP Option Codes
0       constant  CD_PAD
1       constant  CD_SUBNETMASK
3       constant  CD_ROUTER
d#  12  constant  CD_HOSTNAME
d#  43  constant  CD_VENDOR_SPEC
d#  50  constant  CD_REQ_IPADDR
d#  52  constant  CD_OPTION_OVERLOAD
d#  53  constant  CD_DHCP_TYPE
d#  54  constant  CD_SERVER_ID
d#  55  constant  CD_REQUEST_LIST
d#  57  constant  CD_MAXMSG_SIZE
d#  60  constant  CD_CLASSID
d#  61  constant  CD_CLIENTID
d#  67  constant  CD_BOOTFILE_NAME
d# 255  constant  CD_END

\ Sun Vendor specific options
d# 16  constant  VS_BOOT_URI		\ Boot file URI
d# 17  constant  VS_HTTP_PROXY		\ HTTP Proxy URL for WAN boot

\ DHCP states
0     constant  DHCPS_INIT
1     constant  DHCPS_INFORM
2     constant  DHCPS_SELECTING
3     constant  DHCPS_REQUESTING
d# 4  constant	DHCPS_VERIFYING
d# 5  constant  DHCPS_BOUND
d# 6  constant  DHCPS_CONFIGURED

headers
