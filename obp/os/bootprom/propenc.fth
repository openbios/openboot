\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: propenc.fth
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
id: @(#)propenc.fth 1.5 98/04/08
purpose: Property encoding and decoding primitives
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ External encoding and decoding for primitive data types

\ Encode integers into a byte array, suitable for passing to Unix.
\ Decode integers from a byte array.

decimal
headers
\ Merge two property-encoded arrays into a single array
\ Assumes that adr0+len0 == adr1
: encode+    ( adr0 len0 adr1 len1 -- adr0 len0+len1 )  nip +  ;


\ Copy a byte array into the dictionary.
: encode-bytes  ( adr len -- adr' len )
   here >r                      ( adr len )
   bounds  ?do  i c@ c,  loop   ( rs: start )
   r> here over -               ( adr' len )
;

: decode-bytes  ( adr1 len1  len2  -- adr1+len2 len1-len2  adr1 len2 )
   >r  over swap r@ /string  rot r>
;


\ Copy a string to the dictionary, and add a null byte at the end
: encode-string  ( adr len -- adr' len+1 )
   here >r                             ( adr len )
   bounds  ?do  i c@ c,  loop   0 c,   ( )  ( rs: start )
   r> here over -                      ( adr' len+1 )
;

\ adrb,lenb is the initial null-terminated string from the argument string.
\ lenb does not include the null.  adra lena is the remainder string.
: decode-string  ( adr len -- adra lena adrb lenb )
   0 left-parse-string
;
: get-encoded-string  ( adr len -- adr len-1 )  1-  ;

\ Copy an int as 4 bytes to the dictionary
: encode-int  ( i -- adr len )   here  swap be-l,  /l  ;

: decode-int  ( adr len -- adr' len' n )
   over be-l@ >r  /l /string  r>
;
: get-encoded-int  ( adr len -- n )  drop be-l@  ;

headerless

: ?base  ( adr len -- adr' len' )
   dup 2 >  if                     ( adr len )
      over c@ ascii 0  =  if       ( adr len )
         over 1+ c@ ascii x =  if  ( adr len )
	    hex  2 /string         ( adr+2 len-2 )
	 else                      ( adr len )
            octal  1 /string       ( adr+1 len-1 )
         then                      ( adr' len' )
      then                         ( adr' len' )
   then                            ( adr' len' )
;

headers
: encode-number  ( adr len apf -- n )
   drop					( adr,len )
   base @ >r  decimal			( adr,len )   ( r: base )
   ?base  strip-blanks			( adr',len' ) ( r: base )
   $number  r> base !  if		(  )
      p" bad-number" throw		(  )
   then					( n )
;
