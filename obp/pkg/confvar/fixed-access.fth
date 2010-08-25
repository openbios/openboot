\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fixed-access.fth
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
id: @(#)fixed-access.fth 1.9 03/10/28
purpose: 
copyright: Copyright 1998-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\
\ Fixed variables don't have matching hash codes. they are based upon
\ fixed addresses within the device.
\
\ Fixed config variables may not be created at runtime, so all the
\ construction routines are transient.
\
\ Format of a fixed definition:
\	seek-pos		/l	with bit 31 set to indicate no default
\	len			1	data length
\
\ For the fixed data we do write through, with the data being cached.
\ We cache all the 'fixed' bytes, but only checksum from 0x20 to the end.
\
\

unexported-words

0     value 	fixed-buffer		\ Cached data
0     value 	fixed-xfer-buffer	\ Transfer buffer
false value	fixed-store-disabled?	\ Disable device updates 
d# 256 constant /max-dev-path		\ Max len nvram device path with args

exported-headerless

false value fixed-options-open?

: open-nvfixed-region ( nvdevice$ -- ok? )
   \ Concatenate device path and argument strings into allocated memory
   /max-dev-path dup alloc-mem tuck 0 2swap 2>r $add	( dev$ ) ( r: buf,len )
   " :fixed" 2swap $add  nvfixed-open  if		( )
      nvfixed-size dup la1+ alloc-mem is fixed-buffer	( n )
      alloc-mem is fixed-xfer-buffer			( )
      true dup to fixed-options-open?			( true )
   else							( )
      false						( false )
   then                                                 ( ok? )
   2r> free-mem						( ok? )
;

: init-nvfixed-region ( -- )
   fixed-options-open?  if				( )
      0 nvfixed-seek					( )
      fixed-buffer nvfixed-size  2dup la1+ erase	( adr,len )
      nvfixed-write					( )
      0 nvfixed-seek					( )
   then							( )
;

: load-nvfixed-data ( -- )
   fixed-options-open?  if				( )
      0 nvfixed-seek					( )
      fixed-buffer la1+ nvfixed-size nvfixed-read	( )
      nvmagic# fixed-buffer l!				( )
      0 nvfixed-seek					( )
   then							( )
;

: nvfixed-region-ok? ( -- ) true ;

exported-headers
transient

variable fixed-ptr

: fixed-alloc ( n -- ptr )
   fixed-ptr dup @ >r +! r>
;

: fixed-create \ name ( ptr -- )
   ['] $header behavior >r		( ptr )
   ['] ($header) to $header		( ptr )
   parse-word				( ptr adr,len )
   also options definitions		( ptr adr,len )
   $create				( ptr )
   r> to $header			( ptr )
   previous definitions			( ptr )
   l,					( -- )
;

: fixed-config \ name ( len -- )
   fixed-alloc fixed-create  		( -- )
;

: nodefault-fixed-config \ name ( len -- )
   fixed-alloc h# 8000.0000 or fixed-create 		( -- )
;

headerless  resident

unexported-words

: fixed-len@ ( apf -- len )  la1+ c@ ;
: fixed-pos@ ( apf -- pos )  unaligned-l@  h# 8000.0000 invert and ;

: >fixed-default   ( apf -- adr )   la1+ 1+ ;
: fixed-nodefault? ( apf -- flag )  unaligned-l@ h# 8000.0000 and ;

: >fixed-buffer ( pos -- adr )  fixed-buffer la1+ + ;

: fixed-adr ( apf -- adr )
   fixed-options-open?  if
      fixed-pos@ >fixed-buffer
   else
      dup fixed-nodefault?  if drop <no-default>  else  >fixed-default  then
   then
;

: (fixed-write) ( adr len pos -- )
   fixed-store-disabled? 0=  if			( adr len pos )
      nvfixed-ftell >r				( adr len pos ) ( r: curpos )
      nvfixed-seek  nvfixed-write		( )
      r> nvfixed-seek				( ) ( r: )
      nvfixed-sync				( )
   else						( adr len pos )
      3drop					( )
   then						( )
;

: fixed-write ( adr len apf -- )
\nvdebug ." setting fixed data "
   fixed-options-open?  if                      ( adr len apf )
      fixed-pos@  dup >r                        ( adr len pos ) ( r: pos )
      >fixed-buffer swap 2dup 2>r move 2r>      ( bufadr len )
      r> (fixed-write)                          ( ) ( r: )
   else                                         ( adr len apf )
      3drop                                     ( )
   then                                         ( )
;

: fixed-byte! ( byte apf -- )
   >r fixed-xfer-buffer tuck c!			( adr )
   /c r> fixed-write				( )
;

: fixed-int! ( int apf -- )
   >r fixed-xfer-buffer tuck l!			( adr )
   /l r> fixed-write				( )
;

: fixed-xint! ( int apf -- )
   >r fixed-xfer-buffer tuck x!			( adr )
   /x r> fixed-write				( )
;

: fixed-string@ ( apf -- adr len )
   >r r@ fixed-adr				( adr )
   count					( adr' len )
   r> fixed-len@ 2- min				( adr' len' )
;

: fixed-string! ( adr len apf -- )
   >r r@ fixed-len@ 2- min tuck		( len' adr len' )
   fixed-xfer-buffer pack swap 2+ r>	( adr len' apf )
   fixed-write				( )
;

unexported-words
