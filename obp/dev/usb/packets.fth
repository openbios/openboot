\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: packets.fth
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
id: @(#)packets.fth 1.6 01/06/27
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

\ packet ids; includes check bits

\ e1 constant out-pid
\ 69 constant in-pid
\ a5 constant sof-pid		\ done by the chip
\ 2d constant setup-pid
\ c3 constant data0-pid		\ done by the chip
\ 4b constant data1-pid		\ done by the chip
\ d2 constant ack-pid		\ XXX needed?
\ 5a constant nak-pid		\ XXX needed?
\ 1e constant stall-pid		\ XXX needed?
\ 3c constant pre-pid		\ done by the chip

\ packet offsets for usb device requests

struct
	1 field request-type
	1 field request
	2 field req-value
	2 field req-index
	2 field req-len
( request block size ) constant /request

\ first two bytes of request block -- type and request together:

h# 0001 constant clear-feature-req	\ twiddle bits for interface, endpoint
h# 8008 constant get-config-req
h# 8006 constant get-descript-req
h# 810a constant get-interface-req
h# 8000 constant get-status-req		\ twiddle bits for interface, endpoint;
					\ note dir bit for endpoints
h# 0005 constant set-address-req
h# 0009 constant set-config-req
h# 0003 constant set-feature-req	\ twiddle bits for interface, endpoint
h# 010b constant set-interface-req

\ XXX dir bit for endpoints applies to all requests? E.g., clear-feature &
\ set-feature? 1.1 implies that it does.

\ descriptor types, used by get-descript-req:

1 constant device-descript
2 constant config-descript
3 constant string-descript
4 constant interface-descript
5 constant endpoint-descript

\ Feature selectors:

0 constant endpoint-stall

d# 64 instance value max-packet		\ get from device descriptor; for child endpt 0
0 instance value child-speed		\ used to unstall endpoints

\ device descriptor fields:

struct
	1 field d-descript-len
	1 field d-descript-type
	2 field d-descript-release
	1 field d-descript-class
	1 field d-descript-sub
	1 field d-descript-protocol
	1 field d-descript-maxpkt
	2 field d-descript-vendor
	2 field d-descript-product
	2 field d-descript-device
	1 field d-descript-imanufact
	1 field d-descript-iproduct
	1 field d-descript-iserial
	1 field d-descript-#configs
( device descriptor size ) constant /dev-descriptor

\ configuration descriptor fields:

struct
	1 field c-descript-len
	1 field c-descript-type
	2 field c-descript-total
	1 field c-descript-#interfaces
	1 field c-descript-config-id
	1 field c-descript-iconfig
	1 field c-descript-attributes
	1 field c-descript-max-power
( configuration descriptor size ) constant /config-descriptor

\ interface descriptor fields:

struct
	1 field i-descript-len
	1 field i-descript-type
	1 field i-descript-interface-id
	1 field i-descript-alt-id
	1 field i-descript-#endpoints
	1 field i-descript-class
	1 field i-descript-sub
	1 field i-descript-protocol
	1 field i-descript-itext
( interface descriptor size ) constant /interface-descriptor

\ endpoint descriptor fields:

struct
	1 field e-descript-len
	1 field e-descript-type
	1 field e-descript-endpoint-id
	1 field e-descript-attributes
	2 field e-descript-max-pkt
	1 field e-descript-interval
( endpoint descriptor size ) constant /endpoint-descriptor

\ Probably not needed:
\ string descriptor fields:

\ struct
\	1 field s-descript-len
\	1 field s-descript-type
\	1 field s-descript-string	\ actually, s-descript-len minus 2
\ ( string descriptor size ) constant /string-descriptor

\ XXX not really correct since there can be multiple optional fields tacked
\ on
\ Probably not needed:
\ HID descriptor fields:

\ struct
\	1 field h-descript-len
\	1 field h-descript-type
\	2 field h-descript-release
\	1 field h-descript-country
\	1 field h-descript-#descriptors
\	1 field h-descript-XXX			\ XXX eh? 6.2.1 HID document
\	2 field h-descript-report-len		\ XXX really?
\	1 field h-descript-XXX
\	2 field h-descript-XXX-len
\ ( HID descriptor size ) constant /hid-descriptor

\ There must be at least one report descriptor, and possibly also physical
\ descriptors.

\ We can probably ignore physical descriptors.
