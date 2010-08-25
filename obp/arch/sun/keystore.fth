\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: keystore.fth
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
id: @(#)keystore.fth 1.1 04/09/07
purpose: 
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

0 value keystore-ihandle
0 value keystore-buf		\ Cached data
0 value /keystore		\ Size of keystore partition

struct
   /w  field  >keystore-magic
   /w  field  >keystore-len	\ Keystore data length, including header
   /w  field  >keystore-crc
constant /keystore-header

: keystore-len@ ( -- n )   keystore-buf >keystore-len w@ ;
: keystore-len! ( n -- )   keystore-buf >keystore-len w! ;

: keydata-start@ ( -- adr )  keystore-buf /keystore-header + ;
: keydata-end@   ( -- adr )  keystore-buf keystore-len@ + ;

: keyrecord-len@ ( adr -- n )  dup count ca+ count ca+ swap - ;

: keystore-open ( -- ihandle | 0 )
   d# 256 dup alloc-mem swap  over >r		( va len ) ( r: va ) 
   0 r@ c!					( va len )
   nvram-package phandle>devname  r@ $cat	( va len )
   " :keys"                       r@ $cat	( va len )
   r> count open-dev				( va len ihandle ) ( r: )
   -rot  free-mem				( ihandle )
;

: $call-keystore-method ( ?? method$ -- ?? )  keystore-ihandle $call-method  ;

: keystore-seek ( offset -- )  0 " seek" $call-keystore-method throw ;

: keystore-read ( adr len -- )
   keystore-ihandle 0=  if  2drop exit  then
   tuck " read" $call-keystore-method <>  throw
;

: keystore-write ( adr len -- )
   keystore-ihandle 0=  if  2drop exit  then
   tuck " write" $call-keystore-method <>  throw
;

: (keystore-crc) ( accumulator adr len -- n )
   bounds ?do  i c@ +  wbsplit +  loop
;

: keystore-crc ( -- crc )
   keystore-buf keystore-len@				( adr len )
   2dup wbsplit +  swap /w 2*  (keystore-crc)  -rot	( n adr len )
   /keystore-header tuck - >r + r>  (keystore-crc)	( crc )
;

: keystore-sync ( -- )
   0 keystore-seek					( )
   keystore-crc  keystore-buf tuck >keystore-crc  w!	( adr )
   dup >keystore-len w@  keystore-write			( )
;

: keystore-init ( -- )
   keystore-buf dup /keystore erase			( adr )
   h# cd63           over >keystore-magic  w!		( adr )
   /keystore-header  swap >keystore-len    w!		( )
   keystore-sync					( )
;

: init-keystore-partition ( -- )
   keystore-ihandle if  exit  then				( )

   keystore-open  dup is keystore-ihandle  0=  if		( )
      cmn-error[ " Could not open security keystore device" ]cmn-end 
      -1 throw
   then								( )

   " size" $call-keystore-method  dup is /keystore		( size )
   dup alloc-mem tuck swap erase  is keystore-buf		( )

   0 keystore-seek						( )
   keystore-buf /keystore-header keystore-read			( )
   keystore-buf >keystore-magic w@  h# cd63 <>	if		( )
      cmn-note[ " Initializing security keystore" ]cmn-end
      keystore-init exit						( )
   then								( )

   keydata-start@ keydata-end@ over -				( adr len )
   ['] keystore-read catch 0=  if				( )
      keystore-buf >keystore-crc w@  keystore-crc =  if		( )
         exit							( )
      then							( )
   else								( adr len )
      2drop 							( )
   then								( )
   cmn-error[
      " Security keystore contents corrupt; Reinitializing keystore"
   ]cmn-end
   keystore-init						( )
;

\ Locate the named key in keystore.
: find-security-key ( key$ -- adr | 0 )
   2>r						( ) ( r: key$ )
   keydata-end@  keydata-start@			( end start )
   begin  2dup >  while				( end nxt )
      dup count	 2dup 2r@ $=  if		( end nxt $ )
         2drop nip 2r> 2drop exit		( nxt ) ( r: )
      else					( end nxt $ )
         rot drop  ca+ count ca+		( end nxt' )
      then					( end nxt' )
   repeat  2drop				( )
   2r> 2drop 0					( 0 ) ( r: )
;

\ Add a key record entry.
: add-keyrecord-entry ( name,len data,len -- )
   keydata-end@ >r				( name,len data,len ) ( r: adr )
   2swap  r@ pack count ca+  pack count ca+	( adr' )
   r> -  keystore-len@ +  keystore-len!		( ) ( r: )
;

\ Delete a keyrecord entry
: delete-keyrecord-entry ( adr -- )
   dup keyrecord-len@  dup >r				( adr n ) ( r: n )
   over ca+  keydata-end@  over - rot swap move		( )
   keystore-len@  r> -	keystore-len!			( ) ( r: )
;

\ Check keystore space availability.
: enough-key-room? ( name,len keydata,len -- flag )
   nip over +  2+ >r				( name,len ) ( r: total )
   /keystore  keystore-len@ -  			( name,len nfree )
   -rot  find-security-key ?dup if		( nfree keyrecord-adr )
      count tuck ca+ count nip +  2+  +		( avail )
   then						( avail )
   r> >=					( flag ) ( r: )
;

d# 64  constant  max-keyname-len	\ Keyname can be upto 64 characters
d# 32  constant  max-keydata-len	\ Keydata can be upto 32 bytes

\ Key retrieval. Returns length of the key on success, or one of the 
\ following codes on failure:
\	-1	Invalid argument (Key name too long)
\	-2	Buffer too small to hold key data
\	-3	Key does not exist
\	-4	Could not access keystore

: (get-security-key) ( key$ -- keydata,len )
   find-security-key ?dup  if  count ca+ count	else  0 0  then
;

cif: SUNW,get-security-key ( len buf cname -- keylen | error# )
   >r swap r> cscount				( buf len keyname$ )
   dup max-keyname-len >  if			( buf len keyname$ )
      2drop 2drop -1 exit
   then						( buf len keyname$ )
   keystore-ihandle 0=  if			( buf len keyname$ )
      2drop 2drop -4 exit
   then						( buf len keyname$ )
   (get-security-key) dup 0=  if		( buf len keydata keylen )
      2drop 2drop -3 exit
   then						( buf len keydata keylen )
   rot	over <  if				( buf keydata keylen )
      3drop -2 exit
   then						( buf keydata keylen )
   dup >r  rot swap move  r>			( keylen )
;

\ Store security key in keystore.
: write-security-key ( name,len data,len -- keylen )
   2over find-security-key ?dup if		( name,len data,len adr )
      delete-keyrecord-entry			( name,len data,len )
   then						( name,len data,len )
   dup if					( name,len data,len )
      dup >r  add-keyrecord-entry  r>		( keylen )
   else						( name,len data,len )
      2drop 2drop 0				( 0 )
   then						( keylen )
   keystore-sync				( keylen )
;

\ Key storage/deletion. A key length of zero is used to delete the
\ named key. On success, the length of stored key is returned; a return
\ value of zero indicates successful key deletion. Possible error 
\ return values are
\	-1	Invalid arguments (Key name or value too long)
\	-2	Key to delete does not exist
\	-3	Out of key storage space
\	-4	Could not access keystore
 
: (set-security-key) ( name,len data,len -- len' | error# )
   2 pick max-keyname-len >  over max-keydata-len >  or  if
      2drop 2drop -1 exit
   then						( name,len data,len )
   keystore-ihandle 0=  if
      2drop 2drop -4 exit
   then						( name,len data,len )
   dup 0=  if
      2over find-security-key 0=  if
         2drop 2drop -2 exit
      then
   then						( name,len data,len )
   2over 2over enough-key-room? 0=  if
      2drop 2drop -3 exit
   then						( name,len data,len )
   write-security-key
;

cif: SUNW,set-security-key ( len buf cname -- len' | error# )
   >r swap r> cscount 2swap (set-security-key)
;

max-keydata-len  buffer:  keydata-buf	\ Buffer to hold raw keydata

: convert-key ( keyvalue$ -- [ keydata datalen ] valid? )
   dup 2 mod 0<>  over 2/ max-keydata-len >  or  if	( keyvalue$ )
      2drop false exit					( false )
   then							( keyvalue$ )
   keydata-buf 0  2swap bounds ?do			( keydata,len )
      i 2 $hnumber if					( keydata,len )
         2drop false unloop exit			( false )
      then						( keydata,len n )
      >r  2dup ca+  r> swap c!				( keydata,len )
      1+						( keydata,len' )
   2 +loop  true					( keydata,len' true )
;

headers
also forth definitions

\ Command line interface to store/delete security keys.
: set-security-key  \ keyname keyvalue ( -- )
   safe-parse-word  parse-word  dup if		( name$ value$ )
      2dup convert-key 0=  if			( name$ value$ )
         ." Invalid keyvalue '" type ." '" cr
         2drop exit				( )
      else					( name$ value$ keydata,len )
         2swap 2drop				( name$ keydata,len )
      then					( name$ keydata,len )
   then						( name$ keydata,len )
   2over 2over (set-security-key)		( name$ keydata,len result )
   dup 0<  if					( name$ keydata,len error# )
      case
         -1  of  ." Key name or value too long"    endof
         -2  of  ." Key to delete does not exist"  endof
         -3  of  ." Out of key storage space"      endof
         -4  of  ." Could not update key data"     endof
      endcase					( name$ keydata,len )
      2drop 2drop				( )
   else						( name$ keydata,len len' )
      drop nip 0=  if				( name$ )
         ." Key '"  2dup type ." ' deleted" cr	( name$ )
      then  2drop				( )
   then						( )
;

\ List names of keys stored in the keystore. Key values are not printed. 
: list-security-keys ( -- )
   keydata-end@ keydata-start@ 				( end start )
   begin  2dup >  while					( end nxt )
      dup count type cr  dup keyrecord-len@ ca+		( end nxt' )
   repeat  2drop					( )
;

previous

stand-init: initialize security key structure
   init-keystore-partition
;
