\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hmac-sha1.fth
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
id: @(#)hmac-sha1.fth 1.1 04/09/07
purpose: HMAC over SHA-1
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ RFC 2104: HMAC: Keyed-Hashing for Message Authentication
\ RFC 2202: Test Cases for HMAC-MD5 and HMAC-SHA-1

headerless

\ HMAC-SHA1(K, message) can be expressed as
\       SHA1(K' xor opad, SHA1(K' xor ipad, message))
\
\ where,
\   K    = secret key; If the input key is longer than 64 (SHA1_BLK_SIZE)
\          bytes, this is first hashed to produce the 20 (SHA1_DIGEST_LEN)
\          byte hash which is used as the actual key to HMAC.
\   K'   = K with zeroes appended so that the result is SHA1_BLK_SIZE bytes
\   ipad = 0x36 repeated SHA1_BLK_SIZE times
\   opad = 0x5c repeated SHA1_BLK_SIZE times

d# 20  constant  HMAC_SHA1_DIGEST_LEN

: hmac-sha1-hashkey ( keydata keylen -- keydata' keylen' )
   dup SHA1_BLK_SIZE >  if			( key keylen )
      sha1-init  sha1-update  sha1-final  	( key' keylen' )
   then						( key' keylen' )
;

: hmac-sha1-init ( key keylen -- )
   SHA1_BLK_SIZE dup alloc-mem swap		( key,len buf,len )
   2dup 0 fill					( key,len buf,len ) 
   2swap hmac-sha1-hashkey  3 pick swap move	( buf,len )
   2dup bounds ?do				( buf,len )
      i c@  h# 36 xor  i c!			( buf,len )
   loop						( buf,len )
   sha1-init					( buf,len )
   2dup sha1-update				( buf,len )
   free-mem					( )
;

: hmac-sha1-update ( data datalen -- )
   sha1-update
;

: hmac-sha1-final ( key keylen -- digest len )
   SHA1_DIGEST_LEN dup alloc-mem swap		( key,len idigest,len )
   sha1-final  3 pick swap move			( key,len idigest,len ) 

   SHA1_BLK_SIZE dup alloc-mem swap		( key,len idigest,len buf,len )
   2dup 0 fill					( key,len idigest,len buf,len )
   2rot hmac-sha1-hashkey  3 pick swap move	( idigest,len buf,len )

   2dup bounds ?do				( idigest,len buf,len )
      i c@  h# 5c xor  i c!			( idigest,len buf,len )
   loop						( idigest,len buf,len )

   sha1-init
   2dup  sha1-update  free-mem			( idigest,len )
   2dup  sha1-update  free-mem			( )
   sha1-final					( hmac-digest,len )
;

: hmac-sha1 ( adr size key keylen -- digest len )
   2swap 2over hmac-sha1-init			( key keylen adr size )
   begin  dup  while				( key keylen adr rem )
      2dup h# 4000 min  tuck hmac-sha1-update	( key keylen adr rem n )
      tuck - >r ca+ r>				( key keylen adr' rem' )
      show-progress				( key keylen adr' rem' )
   repeat  2drop				( key keylen )
   hmac-sha1-final				( digest,len )
;

[ifdef] DEBUG

d# 80  instance buffer:  hmac-test-keybuf
d# 80  instance buffer:  hmac-test-databuf

: hmac-test ( testid$ adr size key keylen digest len -- )
   >r >r  2rot type 2 spaces  hmac-sha1  r> r> digest=  if 
      ." PASSED"
   else
      ." FAILED"
   then  cr
;

: hmac-tests ( -- )

   " Test 1"
   " Hi There"
   hmac-test-keybuf d# 20  2dup h# 0b fill
   " "(b617318655057264e28bc0b6fb378c8ef146be00)"
   hmac-test

   " Test 2"
   " what do ya want for nothing?"
   " Jefe"
   " "(effcdf6ae5eb2fa2d27416d5f184df9c259a7c79)"
   hmac-test

   " Test 3"
   hmac-test-databuf d# 50  2dup h# dd fill
   hmac-test-keybuf  d# 20  2dup h# aa fill
   " "(125d7342b9ac11cd91a39af48aa17b4f63f175d3)"
   hmac-test

   " Test 4"
   hmac-test-databuf d# 50  2dup h# cd fill
   " "(0102030405060708090a0b0c0d0e0f10111213141516171819)"
   " "(4c9007f4026250c6bc8414f9bf50c86c2d7235da)"
   hmac-test

   " Test 5"
   " Test With Truncation" 
   hmac-test-keybuf d# 20  2dup h# 0c fill
   " "(4c1a03424b55e07fe7f27be1d58bb9324a9a5a04)"
   hmac-test

   " Test 6"
   " Test Using Larger Than Block-Size Key - Hash Key First"
   hmac-test-keybuf d# 80  2dup h# aa fill
   " "(aa4ae5e15272d00e95705637ce8a3b55ed402112)"
   hmac-test

   " Test 7"
   " Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data"
   hmac-test-keybuf d# 80  2dup h# aa fill
   " "(e8e99d0f45237d786d6bbaa7965c7808bbff1a91)"
   hmac-test
;

[then]

headers
