\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: decompress.fth
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
id: @(#)decompress.fth 1.11 02/02/28
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

headers
transient

inline-struct? on
d# 258 constant dc-first-code
d# 257 constant dc-end-code
d# 256 constant dc-clear-code
inline-struct? off

resident

vocabulary decompressor also decompressor definitions
headerless

: decomp-cleanup ( err$ -- )  ." Decomp: " type cr   r> drop  ;

: decomp-alloc ( len -- va )
   0 tuck [ also client-services ] claim [ previous ]
;

: decomp-free ( va len -- )
   swap [ also client-services ] release [ previous ]
;

: maxcode! ( data buffer -- ) >maxcode l! ;

: finchar@ ( buffer -- data ) >fin-char l@ ;
: finchar! ( data buffer -- ) >fin-char l! ;

: de-stack@ ( buffer -- data ) >de-stack l@ ;

: tab-suffix@ ( offset buffer -- data ) >tab-suffix l@ + c@ ;
: tab-suffix! ( data offset buffer -- ) >tab-suffix l@ + c! ;

: tab-prefix@ ( offset buffer -- data ) >tab-prefix l@ swap 2* + w@ ;
: tab-prefix! ( data offset buffer -- ) >tab-prefix l@ swap 2* + w! ;

: free-ent@ ( offset -- data ) >free-ent l@ ;
: free-ent! ( data offset -- ) >free-ent l! ;

: n>maxbits ( n_bits -- maxcode ) 1 swap << 1- ;

: >init-n-bits ( size buffer -- )
   2dup >n-bits  l!			( size buffer )
   swap n>maxbits swap maxcode!		( -- )
;

: clear-prefix ( buffer -- ) >tab-prefix l@  d# 512  0  fill ;

: init-decompress ( src len dest buffer -- )
   dup >r				( src len dest buffer )
   /decomp-control 0 fill		( src len dest )

   r@ >dest-addr	l!		( src )
   r@ >source-size	l!		( src dest )
   r@ >source-addr	l!		( -- )

   #init-bits r@ >init-n-bits
   dc-first-code r@ free-ent!

   r@ >tab-suffix-offset r@ >tab-suffix l!
   r@ >tab-prefix-offset r@ >tab-prefix l!
   r@ >destack-offset	 r@ >de-stack   l!

   \ initialize the first 256 entries in the table.
   r@ clear-prefix
   r@ >tab-suffix l@  h# 100  0 do  i over c!  1+  loop  drop

   r> drop
;

: getcode(n-bits) ( buffer -- code EOF? )
   dup >n-bits l@ swap decomp-getcode		( code )
   dup -1 =					( code -1? )
   over dc-end-code = or			( code EOF? )
;

: (decompress) ( src len dest scratch -- )

   dup >r
   init-decompress

   r@ decomp-getbyte h# 1f =
   r@ decomp-getbyte h# 9e = and 0=  if
      r> drop " Bad MAGIC number" decomp-cleanup
   then

   r@ decomp-getbyte dc-#bits <> if
      r> drop " Bad #bits" decomp-cleanup
   then

   r@ getcode(n-bits) if		( code )
      r> 2drop " short decompress" decomp-cleanup
   then					( code )

   \ putbyte( finchar )
   dup r@ decomp-putbyte		( oldcode )
   dup r@ finchar!			( oldcode )
   r@ de-stack@				( oldcode stackp )
   begin				( oldcode stackp )
      r@ getcode(n-bits) 0=		( oldcode stackp code EOF? )
      over dc-end-code <> and	( oldcode stackp code more? )
      while				( oldcode stackp code )

      dup dc-clear-code = if	( oldcode stackp code )
         drop				( oldcode stackp )

         \ for (i=255; i>=0; i--) tab_prefix[i] = 0;
         r@ clear-prefix		( oldcode stackp )

         \ maxcode = MAXCODE(n_bits = INIT_BITS)
         #init-bits r@ >init-n-bits	( oldcode stackp )

         \ free-ent = first-code - 1
         dc-first-code 1-	 	( oldcode stackp first-code )
         r@ free-ent!			( oldcode stackp )

         \ if ( (code = getcode (n_bits)) == -1 ) break;
         r@ getcode(n-bits) if		( oldcode stackp code )
            r> 2drop 2drop exit		( -- )
         then				( oldcode stackp code )
      then				( oldcpde stackp code )

      \ incode = code
      dup r@ >incode l!			( oldcpde stackp code )

      \ if (code >= free_ent)
      dup r@ free-ent@ >= if		( oldcode stackp code )
         drop				( oldcode stackp )

         \ *stackp++ = finchar
	 r@ finchar@ over c! 1+		( oldcode stackp finchar )

         \ code = oldcode
         over				( oldcode stackp code )
      then

      \ while (code>=256)
      begin				( oldcode stackp code )
         dup d# 256 >= while		( oldcode stackp code )
            tuck r@ tab-suffix@         ( oldcode code stackp data)

            \ *stackp++ = tab_suffix[code]
            over c! 1+			( oldcode code stackp )

            \ code = tab_prefix[code]
            swap r@ tab-prefix@		( oldcode code stackp data )
      repeat				( oldcode stackp code )

      \ finchar = tab_suffix[code]
      tuck r@ tab-suffix@		( oldcode code stackp data )
      dup r@ finchar!			( oldcode code stackp data )

      \ *stackp++ = finchar
      over c! 1+			( oldcode code stackp )

      begin				( oldcode code stackp )
         \ putbyte ( *--stackp )
         1- dup c@ r@ decomp-putbyte
      dup r@ de-stack@ = until		( oldcode code stackp )

      \ code = free-ent
      nip r@ free-ent@			( oldcode stackp code )

      rot				( stackp code oldcode )

      \ if (code < maxmaxcode)
      over maxmaxbits < if		( stackp code oldcode )

         \ tab_prefix[code] = oldcode
         over r@ tab-prefix!		( stackp code )

         \ tab_suffix[code] = finchar
         r@ finchar@			( stackp code finchar )
         over r@ tab-suffix!		( stackp code )

         \ free_ent = code+1
         1+ r@ free-ent!		( stackp )
      else				( stackp code oldcode )
         2drop				( stackp ) 
      then				( stackp )

      \ oldcode = incode
      r@ >incode l@ swap		( oldcode stackp )

      \ if ( free_ent > maxcode )
      r@ free-ent@			( oldcode stackp free-ent )
      r@ >maxcode l@ > if		( oldcode stackp )

         \ n_bits++
         r@ >n-bits 			( oldcode stackp addr )
         1 over l+! l@			( oldcode stackp nbits )

         \ maxcode = ( n_bits == BITS ) ? maxmaxbits : MAXCODE(n_bits)
         dup n>maxbits			( oldcode stackp nbits maxcode )
         swap dc-#bits = if		( oldcode stackp maxcode )
            drop maxmaxbits		( oldcode stackp maxcode )
         then				( oldcode stackp maxcode )
         r@ maxcode!			( oldcode stackp )

      then				( oldcode stackp )
   repeat				( oldcode stackp )

   r> 2drop 2drop			( -- )
;

: bump-addr,len ( addr len n -- addr' len' ) tuck - -rot + swap ;

: (do-decompress) ( addr len dlen -- addr' len' )
   dup /di-header + decomp-alloc	( addr len dlen dest )
   /di-header + swap			( adr len dest dlen )
   over					( adr len dest dlen dest )
   /decomp-data decomp-alloc		( adr len dest dlen dest scratch )
   -rot					( adr len dest scratch dlen dest )
   swap 2>r dup >r			( adr len dest scratch )
   (decompress)				( -- )
   r> /decomp-data decomp-free		( -- )
   2r>					( addr' len' )
;

\
\ Support for other decompression would be added here.
\
headers

: do-decompress ( addr len -- ok? )
  over d# 12 + l@ >r				( addr len ) ( r: dlen )
  over d#  8 + l@ >r				( addr len ) ( r: dlen type )
  d# 16 bump-addr,len				( addr' len' dlen )
  2r> case					( addr' len' dlen )
    h# 434f4d50 of (do-decompress) true endof	( true ) \ COMP
\   h# 475a4950 of ...         true endof	( true ) \ GZIP
    ( default ) 2drop 0 swap			( false )
  endcase					( flag? )
;

: finish-decompress ( addr' len' -- )
   [ 0 /di-header - ] literal bump-addr,len decomp-free
;

previous definitions
headerless
