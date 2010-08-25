\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: wanboot.fth
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
id: @(#)wanboot.fth 1.1 04/09/07
purpose: WANboot support
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ WANboot URLs are of the form 
\	http://hostport/path/wanbootCGI
\ which specifies the server and the location of the CGI script which
\ will deliver WANboot datastreams to the client. 
\
\ To request the bootfile, we construct a query URL of the form
\	http://hostport/path/wanbootCGI/?CONTENT=bootfile&IP=a.b.c.d&CID=cid
\ where, a.b.c.d is the client's network number, and cid is the client 
\ identifier.
\
\ If a client identifier is not in use, a default client identifier
\ is constructed by concatenating the ARP hardware type and the 
\ client's hardware address.

: set-wanboot-clientid ( buf -- )
   if-htype@              over 1+         c!		( buf )
   if-hwaddr if-addrlen@  2 pick 2+ swap  move		( buf )
   if-addrlen@ 1+         swap            c!		( )
;

: wanboot-clientid ( -- $ )
   client-id count  dup 0=  if
      2drop  client-id set-wanboot-clientid  client-id count
   then
   octet-to-hexascii
;

: build-wanboot-requrl$ ( url$ buf$ -- requrl$ )
   2swap                  strcat			( buf$' )
   " /?CONTENT=bootfile"  strcat
   " &IP="                strcat
   ni-netnum inet-ntoa    strcat
   " &CID="               strcat
   wanboot-clientid       strcat			( requrl$ )
;

\ The WANboot datastream comprises of the boot file binary and the 
\ (20 byte) HMAC SHA-1 signature of that file generated using the shared
\ secret key. In the absence of a hashing key ("wanboot-hmac-sha1"), 
\ the signature field contains zeroes.

create wanboot-hmac-keyname  " wanboot-hmac-sha1" cstring,

d# 20  constant  WANBOOT_HMAC_KEYLEN	\ Size of key we use for HMAC SHA-1
d# 32  constant  MAX_KEYLEN		\ Maximum key data length in keystore

MAX_KEYLEN           instance buffer:  hmac-keydata
HMAC_SHA1_DIGEST_LEN instance buffer:  hmac-sha1-digest

: read-hmac-sha1-key ( -- key keylen true | false )
   hmac-keydata MAX_KEYLEN over wanboot-hmac-keyname
   " SUNW,get-security-key" call-cif-method  dup 0<  if
      2drop false
   else
      dup WANBOOT_HMAC_KEYLEN <>  if
         ." Invalid Hash Key Size " .d cr  -1 throw
      then  true
   then
;

: verify-hmac-digest ( adr size digest len -- ok? )
   read-hmac-sha1-key  if			( adr size digest,len key,len )
      2rot 2swap hmac-sha1 digest=		( ok? )
   else						( adr size digest,len )
      2swap 2drop true -rot  bounds do
         i c@ 0<>  if  drop false leave  then 
      loop
   then						( ok? )
;

\ The HTTP payload appears as a multipart-MIME message, the format
\ of which is as follows:
\
\	Content-Length: M
\	Content-Type: multipart/mixed; boundary="Part_Boundary"
\
\	--Part_Boundary
\	Content-Length: N
\	Content-Type: application/octet-stream
\
\	boot file binary goes here
\
\	--Part_Boundary
\	Content-Length: 20
\	Content-Type: application/octet-stream
\
\	keyed hash data goes here
\	--Part_Boundary--

: process-wanboot-response ( adr -- size )
   http-process-headers						( adr )
   http-is-multipart? 0=  if                            	( adr )
      ." Response is not a multipart message" -1 throw
   then                                                 	( adr )

   http-process-part-headers					( adr )
   http-bodypart-length 2dup tuck http-read-body <> if		( adr size )
      ." Error reading bootfile" cr -1 throw
   then  nip							( size )

   http-process-part-headers					( size )
   http-bodypart-length dup HMAC_SHA1_DIGEST_LEN <> if		( size diglen )
      ." Invalid Digest Size " .d cr  -1 throw
   then								( size diglen )
   hmac-sha1-digest over http-read-body  <>  if			( size )
      ." Error reading digest" cr  -1 throw
   then								( size )

   http-process-part-headers					( size )
   http-bodypart-length 0<>  if					( size )
      ." Multipart response has more than 2 parts" -1 throw
   then								( size )
;

\ Load the bootfile from the HTTP server and verify its authenticity. 
\ The server is accessed through a proxy if one was specified. 

: wanboot-load ( adr url$ proxy$ -- size )

   2over 2swap http-init			( adr url$ )

   d# 512 dup alloc-mem  swap >r >r		( adr url$ ) ( r: len,va )
   r@ 0  build-wanboot-requrl$			( adr requrl$ )
   http-send-request				( adr )
   r> r> free-mem				( adr ) ( r: )

   dup ['] process-wanboot-response catch  if	( adr adr )
      http-close -1 throw
   then						( adr size )

   http-close					( adr size )

   tuck hmac-sha1-digest HMAC_SHA1_DIGEST_LEN	( size adr size digest,len )
   verify-hmac-digest 0=  if			( size )
      ." Invalid Hash Digest" cr  -1 throw
   then						( size )
;

headers
