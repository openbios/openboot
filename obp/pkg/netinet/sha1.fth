\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sha1.fth
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
id: @(#)sha1.fth 1.1 04/09/07
purpose: SHA-1 digest computation
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ FIPS 180-1: Secure Hash Standard
\ RFC   3174: US Secure Hash Algorithm 1 (SHA1)

\ Although SHA-1 allows for messages of any length less than 2^64 bits,
\ this implementation only works with messages with a length that is 
\ a multiple of 8-bits. 
\
\ This implementation assumes big-endian host byte ordering, 64-bit
\ cell size, and uses 64-bit FCODE extensions.

headerless

d# 64  constant  SHA1_BLK_SIZE
d# 20  constant  SHA1_DIGEST_LEN

SHA1_DIGEST_LEN instance buffer:  sha1-state	\ State (A, B, C, D, E)
/x              instance buffer:  sha1-nbits	\ #bits processed so far 
/x              instance buffer:  sha1-length	\ Message length, in bits
SHA1_BLK_SIZE   instance buffer:  sha1-buf	\ Undigested/realigned input
d# 80 /l*       instance buffer:  sha1-W	\ 80 word buffer

\ Compare digests 
: digest= ( digest1 len1 digest2 len2 -- same? )  byte-compare ; 

\ Display digest
: .digest ( digest len -- )  octet-to-hexascii type ;

\ Initialize SHA1 context in preparation for computing a message digest
: sha1-init ( -- )
   0 sha1-nbits x!
   h# 67452301  sha1-state tuck  l!  la1+		
   h# efcdab89  over             l!  la1+
   h# 98badcfe  over             l!  la1+
   h# 10325476  over             l!  la1+
   h# c3d2e1f0  swap             l!
;

\ Get current hash state
: sha1-state@ ( -- a b c d e )
   sha1-state dup l@  swap
   la1+       dup l@  swap
   la1+       dup l@  swap
   la1+       dup l@  swap
   la1+           l@
;

\ Update hash digest at end of each processing round
: sha1-state+! ( a b c d e -- )
   sha1-state >r  r@ 4 la+ +!  r@ 3 la+ +!  r@ 2 la+ +!  r@ 1 la+ +!  r> +!
;

\ Basic SHA1 functions 
\   F(b, c, d)		(((b) & (c)) | ((~b) & (d)))
\   G(b, c, d)		((b) ^ (c) ^ (d))
\   H(b, c, d)		(((b) & (c)) | ((b) & (d)) | ((c) & (d)))

: sha1-F ( b c d -- n )  >r  over and  swap invert  r> and  or ;
: sha1-G ( b c d -- n )  xor xor ;
: sha1-H ( b c d -- n )  2dup and >r  or  and  r>  or ;

\ Circular left shift (rotation) of 32-bit argument by n bits.
: rotate-left ( x n -- y )
   >r 0 rshift r>  lshift xlsplit or
;

\ Each processing round is of the form
\   A,B,C,D,E <- (E + f(t; B,C,D) + S^5(A) + W[t] + K[t]), A, S^30(B), C, D 
\
\ To improve performance, all state variables are maintained on the
\ stack and the assignments are achieved by stack manipulation.

: sha1-transform ( a b c d e f{b,c,d} w[t] k -- a' b' c' d' e' )
   + + +  4 pick 5 rotate-left +			( a b c d temp )
   -rot  >r >r  -rot  d# 30 rotate-left  r> r>		( temp a n c d )
;

\ Process the next 64-byte block of the message.
: sha1-process-block ( block -- )
   dup 3 and  if					( block )	
      sha1-buf tuck SHA1_BLK_SIZE move			( aligned-block )
   then							( blk )
   sha1-W tuck SHA1_BLK_SIZE move			( wbuf )
   d# 80 d# 16 do					( wbuf )
      dup  i d#  3 - la+ l@
      over i d#  8 - la+ l@  xor
      over i d# 14 - la+ l@  xor
      over i d# 16 - la+ l@  xor
      1 rotate-left					( wbuf W[t] )
      over i la+ l!					( wbuf )
   loop  drop						( )
   sha1-state@ sha1-W					( a b c d e wbuf )
   d# 20 0 do
      dup la1+ >r >r 2over 3 pick sha1-F r> l@ h# 5a827999 sha1-transform r>
   loop
   d# 40 d# 20 do
      dup la1+ >r >r 2over 3 pick sha1-G r> l@ h# 6ed9eba1 sha1-transform r>
   loop
   d# 60 d# 40 do
      dup la1+ >r >r 2over 3 pick sha1-H r> l@ h# 8f1bbcdc sha1-transform r>
   loop
   d# 80 d# 60 do
      dup la1+ >r >r 2over 3 pick sha1-G r> l@ h# ca62c1d6 sha1-transform r>
   loop  drop
   sha1-state+!
;

\ Process the next portion of the message. Complete any partial blocks 
\ awaiting processing, transform as many full-sized blocks as possible
\ and buffer the remaining input.

: sha1-update ( adr len -- )

   \ Get number of bytes awaiting processing and update the number
   \ of bits processed.
   sha1-nbits x@ 				( adr len nbits )
   over 3 lshift  over +  sha1-nbits x!		( adr len nbits )
   3 rshift  h# 3f and				( adr len nleft )

   \ If we have at least one full sized block, process it. If
   \ we had a partial block outstanding, complete that block and
   \ transform it. Then, transform all full sized blocks.
   2dup +  SHA1_BLK_SIZE >=  if			( adr len nleft )
      ?dup if					( adr len nleft )
         >r  over SHA1_BLK_SIZE r@ - tuck  r>	( adr len n adr n nleft )
         sha1-buf swap ca+ swap move		( adr len n )
         tuck - >r ca+ r>			( adr' len' )
         sha1-buf sha1-process-block		( adr' len' )
      then					( adr' len' )
      begin  dup SHA1_BLK_SIZE >=  while	( adr' len' )
         over sha1-process-block		( adr' len' )
         SHA1_BLK_SIZE tuck - >r ca+ r>		( adr" len" )
      repeat  0					( adr" len" 0 )
   then						( adr" len" nleft )

   \ Buffer the remaining input
   sha1-buf swap ca+  swap move				( )
;

\ End an SHA1 digest operation, finalizing the message digest. The message 
\ must be padded to an even multiple of 512-bits. The first padding bit 
\ is '1'. The last 64 bits represent the length of the original message 
\ (before padding). All bits in between are zeroes.

: sha1-final ( -- digest len )
   SHA1_BLK_SIZE dup alloc-mem tuck swap erase		( padbuf )
   h# 80 over c!					( padbuf )
   sha1-nbits x@ dup sha1-length x!			( padbuf nbits )
   3 rshift h# 3f and  d# 56  2dup >=  if		( padbuf n 56 )
      SHA1_BLK_SIZE +					( padbuf n 120 )
   then  swap -						( padbuf npad )
   over swap sha1-update				( padbuf )
   sha1-length /x sha1-update				( padbuf )
   SHA1_BLK_SIZE free-mem				( )
   sha1-state SHA1_DIGEST_LEN				( digest len )
;

[ifdef] DEBUG

\ Test cases from RFC 3174 (This includes the 3 tests documented in 
\ FIPS 180-1 plus one test where the data is an exact multiple of
\ 512 bits) .

: sha1-test ( testid$ adr size nrepetitions digest len -- )
   >r >r
   sha1-init
   0 ?do  2dup sha1-update  loop  2drop
   sha1-final
   r> r>
   2rot type space
   digest=  if  ." PASSED"  else  ." FAILED"  then  cr
;

: sha1-tests ( -- )
   " Test 1"
   " abc"
   1
   " "(a9993e364706816aba3e25717850c26c9cd0d89d)"
   sha1-test

   " Test 2"
   " abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
   1
   " "(84983e441c3bd26ebaae4aa1f95129e5e54670f1)"
   sha1-test

   " Test 3"
   " a"
   d# 1000000
   " "(34AA973CD4C4DAA4F61EEB2BDBAD27316534016F)"
   sha1-test

   " Test 4"
   " 0123456701234567012345670123456701234567012345670123456701234567"
   d# 10
   " "(dea356a2cddd90c7a7ecedc5ebb563934f460452)"
   sha1-test
;

[then]

headers
