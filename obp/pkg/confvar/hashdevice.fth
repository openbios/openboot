\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hashdevice.fth
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
id: @(#)hashdevice.fth 1.14 03/10/28
purpose: 
copyright: Copyright 1998-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ How this works:
\ For any config-variable we create an entry in the options dictionary that
\ contains:
\
\	acf of the hash routine		/token
\	length field (*)		/l)
\	optional default data		??
\
\ the hash entry is in another vocabulary and contains:
\
\	acf of the options routine	/token
\	hash code			/l
\	pointer to user space		/l
\
\ the user space pointer points to a memory buffer in this format:
\
\	alloc-size			/l
\	ref-count			1
\	pad				3
\	data				??
\
\ this makes the model very simple, if the user buffer is 0 then the device
\ is unbacked and has either no default, or is the default.
\ if the pointer is non-zero then it has been backed by data from the real
\ nv device and instead of using the dictionary as the backing (the default
\ case) we use the (user-pointer + (/l + 1 + 3))
\
\ The ref-count field is there for garbage collection.
\ A hash code with bit 31 clear marks that hash as deleted.
\
\ When the code starts it reads from the nvdevice and creates the memory
\ buffer for any hash codes it finds and copies the data from the device
\ into the memory, if more than 1 copy of a hash are in the device then
\ we release the prior allocated resources, reallocate and increment the
\ reference field. If any reference field exceeds some arbitrary value 
\ then we will garbage collect.
\ 
\ Garbage collection is simple:
\	seek to offset 0 in the device
\	rewite the magic number
\	for each word in the hash vocabulary:
\		IF the user pointer is non zero AND
\		the acf of the config-variable isn't 'crash' THEN
\			write the data to the device
\
\		
\ When you set an option the option is just appended onto the end of the
\ nvdevice.
\

headerless

struct
  /token field >option
  /l	 field >hash
  /l	 field >buffer
constant /hash-content

struct
  /l	field >alloc-size
  1	field >ref-count
  3	field >(pad)
  0	field >data
constant /mem-data

0		value nvgarbage-collect?
0		value #deleted-keys
h# 8000.0000	constant valid-hash-mask
h# 20		buffer: nvbuffer

false  value	token-store-disabled?	\ Disable backing store

: valid-hash? ( hash# -- flag )  valid-hash-mask and  ;

create hash-primes d# 2971 w, d# 8747 w, d# 1031 w, d# 1151 w, d# 2861 w,

: create-nvhash ( str,len -- hash )
\nvdebug ." Hashing: " 2dup type ."  = "
   over c@ h# 5f and d# 6 lshift		( str,len mod )
   over h# 1f and or valid-hash-mask or -rot	( mod str,len )
   0 tuck ?do					( mod str hash )
      over i + c@				( mod str hash char )
      hash-primes i 5 mod wa+ w@ * +		( mod str hash' )
      lwsplit +					( mod str hash )
   loop nip					( mod hash' )
   d# 12 lshift n->l				( mod hash' )
   dup valid-hash-mask and if			( mod hash' )
      abort" HASH/Valid Collision"
   then						( mod hash' )
   or						( hash )
\nvdebug dup .x cr
;

\ Compute a magic number.
\ The actual value used at runtime will include the size of the fixed
\ data region, and may include a platform dependant key. 
" NVRAM magic" create-nvhash  constant nvmagic-hash
nvmagic-hash                  value    nvmagic#

: make-hash$ ( hash -- str len )  base @ >r hex <# u#s u#> r> base ! ;

: find-hash? ( hash -- acf,true | str,len, 0 )
   make-hash$ ['] nvhash-keys $vfind	( acf,true | str,len, 0 )
;

: check-nvgarbage-collect ( ref -- )
   4 > nvgarbage-collect? or to nvgarbage-collect?
;

: hash@   ( apf -- hash )	>hash unaligned-l@  ;
: hash!   ( hash apf -- )	>hash unaligned-l!  ;
: buffer@ ( apf -- ptr )	>buffer >user unaligned-l@  ;
: buffer! ( apf body -- )	>buffer >user unaligned-l!  ;

: alloc-buffer ( len ref -- ptr )
   over if					( len ref )
      >r /mem-data + dup alloc-mem		( len' mem )
      tuck >alloc-size l!			( mem )
      r> over >ref-count c!			( mem )
   else						( len ref )
      drop					( 0 )
   then						( ptr )
;

: release-buffer? ( apf -- ref )
   dup buffer@ ?dup if				( apf mem )
      dup >alloc-size l@			( apf ptr len )
      over >ref-count c@			( apf ptr len ref )
      -rot free-mem				( apf ref )
   else						( apf )
      1						( apf ref )
   then						( apf ref )
   0 rot buffer!				( ref )
;

: simple-crc ( adr len seed -- crc )
   wbsplit + -rot bounds ?do			( crc )
      i c@ + wbsplit +				( crc' )
   loop						( crc' )
;

: load-token-data ( apf -- )
\nvdebug ." ----> Loading: " dup hash@ .x
   nvbuffer dup 3 nvoption-read dup c@ >r		( apf adr ) ( r: crc )
   1+ unaligned-w@				( apf nlen )
\nvdebug ." CRC: " nvbuffer c@ .x
\nvdebug ." LEN: " dup .x
   over release-buffer?				( apf nlen ref )
   2dup 1+ alloc-buffer				( apf nlen ref mem )
   swap check-nvgarbage-collect			( apf nlen mem )
   swap >r 					( apf mem ) ( r: crc nlen )
   tuck						( mem apf mem )
   >data r> 2dup nvoption-read			( mem apf adr nlen ) ( r: crc )
\nvdebug ." Data: " 2dup dump
   tuck dup simple-crc r>			( mem apf nlen crc' crc ) ( r: )
\nvdebug 2dup xor if ." BAD CRC" cr then
   xor if					( mem apf nlen )
      rot swap free-mem				( apf )
      cmn-error[ " Invalid token '" cmn-append token@ ( token )
      >name name>string type cmn-append " '" ]cmn-end ( )
      1 throw					( )
   else
      drop buffer!				( )
   then						( )
;

: write-4bytes ( data -- )  nvbuffer tuck l! /l nvoption-write  ;
: write-2bytes ( data -- )  nvbuffer tuck w! /w nvoption-write  ;
: write-1byte  ( data -- )  nvbuffer tuck c! 1 nvoption-write  ;
: write-eof ( -- )
\nvdebug  ." Write-eof"
  nvoption-ftell -1 write-4bytes nvoption-seek 
\nvdebug  ascii ! emit cr
   nvoption-sync
;

: check-space ( len -- )
   dup if 7 + else  drop 4  then		( len' )
   nvoption-size over 4 + - > throw		( )
;

\ A record is at least 7 bytes long; (hash:4, crc:1, len:2, data:len)
\ but to complete a device update you need an EOF marker of 4 bytes
\
: (write-record) ( adr len hash -- )
   over check-space				( str len hash )
   write-4bytes					( str len )
   2dup dup simple-crc write-1byte		( str len )
   dup write-2bytes				( str len )
   ?dup if  nvoption-write  else  drop  then	( )
   write-eof					( )
;

: get-token-data ( apf -- adr,len )
\nvdebug ." getting token data '" dup token@ >name name>string type ." ' "
   dup buffer@ dup if				( adr ptr )
      nip dup >data				( ptr mem )
      swap >alloc-size l@ /mem-data -		( mem len )
   then						( mem len )
;

\ Write the magic number to indicate the nvdevice is valid.
\ We include the size of the fixed-data-region to ensure that changes in
\ the fixed region size will cause a re-init of the device - This makes
\ it safe to upgrade and downgrade OBPs that have different sized fixed
\ regions. This should also be a very rare event!
\
: write-magic ( -- )
   0 nvoption-seek				( )
   nvmagic# write-4bytes			( )
;

headers

: ((garbage-collect)) ( -- )
\nvdebug1 ." garbage collecting" cr
   write-magic					( alf voc-acf )
   0 ['] nvhash-keys				( alf voc-acf )
   begin  another-word? while			( alf voc-acf anf )
      name>					( alf voc-acf acf )
      dup >body >option token@			( alf voc-acf acf acf )
\nvdebug1 dup >name name>string			( alf voc-acf acf str,len )
\nvdebug1 ."   Writing: " type space		( alf voc-acf acf )
      ['] crash <> >r				( alf voc-acf acf )
      dup execute r> over and if		( alf voc-acf acf adr,len )
\nvdebug1 dup .x ." bytes, " 
         rot					( alf voc-acf adr len acf )
\nvdebug1 ." Hash: " dup >body hash@ .x cr
         >body dup >r hash@ (write-record)	( alf voc-acf )
         0 r> buffer@ >ref-count c!		( alf voc-acf )
      else					( alf voc-acf acf adr len )
\nvdebug1 ." No data!" cr
         3drop					( alf voc-acf )
      then					( alf voc-acf )
   repeat					( -- )
   write-eof					( -- )
   0 to nvgarbage-collect?			( -- )
\nvdebug1 ." done - " nvoption-size .x ." bytes available" cr
;

headerless
: (garbage-collect)  ['] ((garbage-collect)) catch drop  ;

: write-record ( adr len hash -- )
   nvoption-ftell nvbuffer /l nvoption-read nvoption-seek
   nvbuffer l@ l->n -1 <> if			( adr len hash )
      \ The device somehow got out of step as the EOF marker isn't at
      \ the right point. About all we can do is garbage collect and
      \ hope for the best.
      (garbage-collect)				( adr len hash )
   then						( adr len hash )
   (write-record)				( )
;

headers

: garbage-collect ( -- )  nvgarbage-collect? if  (garbage-collect)  then  ;

headerless

: (delete-this-token) ( apf -- )
\nvdebug ." deleting token '" dup token@ >name name>string type ." ' "
   dup release-buffer? drop			( apf )
   token-store-disabled? 0=  if			( apf )
      0 check-space				( apf )
      hash@ h# 7fff.ffff and			( hash' )
      write-4bytes  write-eof			( )
   else						( apf )
      drop					( )
   then						( )
;

: delete-this-token ( apf -- )
   dup ['] (delete-this-token) catch if		( apf ?? )
      drop (garbage-collect)			( apf )
      ['] (delete-this-token) catch if drop then ( -- )
   else                                         ( apf )
      drop                                      ( -- )
   then   					( -- )
;

: (set-token-data) ( data len apf -- )
\nvdebug ." setting token data '" dup token@ >name name>string type ." ' "
   dup >r buffer@ ?dup if			( adr len mem )
\nvdebug ." free existing resource, "
      dup >ref-count c@				( adr len mem ref )
      dup check-nvgarbage-collect		( adr len mem ref )
      swap dup >alloc-size l@			( adr len ref mem alloc'd )
      free-mem	1+				( adr len ref )
      0 r@ buffer!				( adr len ref )
   else						( adr len )
      0						( adr len 0 )
   then						( adr len ref )
   -rot						( ref adr len )
   token-store-disabled? 0=  if			( ref adr len )
      2dup r@ hash@ write-record		( ref adr len )
   then						( ref adr len )
   ?dup if					( ref adr len )
\nvdebug ." alloc resource"
      rot over swap				( adr len len ref )
      alloc-buffer				( adr len mem )
      dup r> buffer!				( adr len mem )
      >data swap move				( -- )
   else						( ref adr )
\nvdebug ." 0 len.. using no resources" 
      0 r> buffer! 2drop			( -- )
   then						( -- )
\nvdebug cr
;

variable write-errors? write-errors? on

: set-token-data ( data len apf -- )
\nvdebug ." Wrapper set-token-data: pos " nvoption-ftell .x
\nvdebug ." ,bytes left: " nvoption-size .x cr
   3dup ['] (set-token-data) catch >r 		( data len apf ? ? ? )
   3drop r> if					( ? ? ? )
\nvdebug ." set token failed attempt 1: " cr
      (garbage-collect)				( data len apf )
      nvoption-ftell >r				( data len apf )
      ['] (set-token-data) catch if		( data len apf )
         3drop write-errors? @ if		( -- )
            ." No space left in device" 	( -- )
         then					( -- )
         r@ nvoption-seek				( -- )
      then					( -- )
      r> drop					( -- )
   then 					( -- )
   garbage-collect				( -- )
\nvdebug ." Wrapper set-token-data: completed @ "
\nvdebug nvoption-ftell .x ." , " nvoption-size .x cr
;

: accumulate-dead-keys ( apf -- )
   release-buffer? drop
   #deleted-keys 1+ dup is #deleted-keys
   d# 100 > nvgarbage-collect? or to nvgarbage-collect?
;

5 actions
action:  get-token-data  ;		\ GET
action:  set-token-data  ;		\ SET
action:  load-token-data ;		\ LOAD
action:  delete-this-token  ;		\ DELETE  (updates device)
action:  accumulate-dead-keys ;		\ RELEASE (just release resource)

: create-config-hash ( hash# -- acf )
\nvdebug ." Hash: " dup .x ." = "
   dup find-hash? if			( hash# acf )
\nvdebug ." (exists) "
      nip 				( acf )
   else					( hash# adr,len )
\nvdebug ." (new) "
      also nvhash-keys definitions	( hash# adr,len )
      ['] $header behavior >r		( -- )
      ['] ($header) to $header		( -- )
      $create				( hash# )
      r> to $header			( h2-acf h1-acf )
      lastacf swap			( acf hash# )
      ['] crash token,			( acf hash# )
      l,				( acf ) 
      0 4 user#, unaligned-l!		( acf )
      use-actions			( acf )
      previous definitions		( acf )
   then
\nvdebug dup .x cr
;

: scan-nvtokens ( -- )
   false 0					( flag 0 )
   0 is #deleted-keys				( flag 0 )
   begin					( flag )
      drop nvoption-ftell				( flag pos )
      nvbuffer dup 4 nvoption-read 		( flag pos buffer )
      l@ dup -1 n->l <> if			( flag pos hash# )
\nvdebug ." Read Hash Key: " dup .x 
         dup valid-hash? if			( flag pos hash# )
            nip create-config-hash		( flag acf )
            2 perform-action			( flag )
         else					( flag pos hash# )
\nvdebug ." [Deleted] "
            valid-hash-mask or			( flag pos hash# )
            find-hash? if			( flag pos )
               4 perform-action			( flag pos )
            else				( flag pos str,len )
               2drop				( flag pos )
            then				( flag pos )
            4 + nvoption-seek			( flag )
\nvdebug cr
         then					( flag )
         nvoption-ftell false			( flag pos false )
      then					( flag pos end? )
   until					( flag pos )
   nvoption-seek					( flag )
   garbage-collect				( flag )
   throw					( -- )
;

exported-headerless

false value options-open?

: open-nvtoken-region ( dev$ -- ok? )
   nvoption-open dup if  true to options-open?  then
;

: nvtoken-region-ok? ( -- flag )
   0 nvoption-seek  nvbuffer 4 nvoption-read  nvbuffer l@ nvmagic# = 
;

: init-nvtoken-region ( -- )
   0 ['] nvhash-keys  begin  another-word?  while
     name> >body release-buffer? drop 
   repeat
   write-magic write-eof
;

: load-nvtoken-data ( -- )
   4 nvoption-seek  scan-nvtokens
;
   
unexported-words

: config-create  \ name  ( len -- )
   ['] $header behavior >r		( len -- )
   ['] ($header) to $header		( len -- )
   parse-word				( len adr,len )
   2dup create-nvhash	 		( len adr,len hash )
   create-config-hash -rot		( len adr,len )
   also options definitions		( len acf adr,len )
   $create				( len acf )
   r> to $header			( len acf )
   previous definitions			( len acf )
   tuck token,				( acf len )
   l,					( acf )
   lastacf swap >body token!		( -- )
;

: nodefault-create \ name ( len -- )
   h# 8000.0000 or config-create
;

: >config-len ( apf -- len )  /token + unaligned-l@ h# 8000.0000 invert and ; 
: nodefault?  ( apf -- flag ) /token + unaligned-l@ h# 8000.0000 and ;

: <no-default> ( -- addr )  p" <no default>"  ;
: >config-default ( apf -- adr )  /token /l + + ;

: get-config-buffer ( apf -- adr,len )
   options-open? if
      token@ execute exit			( adr, len )
   then						( apf )
   >config-default 0				( adr 0 )
;

: config-adr ( apf -- adr )
   dup get-config-buffer if  nip  exit  then
   drop dup nodefault?  if  drop <no-default>  else  >config-default  then
;
