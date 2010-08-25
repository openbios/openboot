\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tableutil.fth
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
\ id: @(#)tableutil.fth 1.2 99/12/01
\ purpose: 
\ copyright: Copyright 1999 Sun Microsystems, Inc.  All Rights Reserved
\

d# 8192 constant /dropin-buffer
[ifdef] debugging?
  [ifdef] complete-tables?
    h# 4000 constant /dropin-buffer
  [then]
[then]

/dropin-buffer alloc-mem constant dropin-buffer
variable dropin-insert-ptr

false value writing-tables?

d# 2048 constant /kbddata-buffer
/kbddata-buffer buffer: kbddata-buffer
d# 1024 buffer: base-table

variable insert-ptr

h# 20 buffer: tablename
2variable current-table tablename 0 current-table 2!

: >current-table ( adr,len -- )
  tablename tuck			( adr buf len buf )
  over					( adr buf len buf len )
  current-table	2!			( adr buf len )
  cmove					( -- )
;

: current-table$ ( -- adr,len ) current-table 2@ ;

: new-kbd-table ( [alias-id] id encoding -- )
  safe-parse-word				( [alias] id encoding adr,len )

  2dup >current-table				( [alias] id encoding adr,len )
  $create					( [alias] id encoding )

[ifdef] verbose?
  ." > Loading "				( [alias] id encoding )
  dup case 
     table-encoding of  ." full " endof	        ( [alias] id encoding )
     diff-encoding of   ." delta " endof	( [alias] id encoding )
     alias-encoding of  ." alias " endof	( [alias] id encoding )
     ." Invalid encoding format of " drop	( [alias] id encoding ) 
  endcase					( [alias] id encoding )
    
  ." table: "					( [alias] id encoding )
  current-table$ type space			( [alias] id encoding )
  ascii ( emit					( [alias] id encoding )
  base @ >r hex					( [alias] id encoding )
  over 2 .r					( [alias] id encoding )
  r> base ! ascii ) emit space			( [alias] id encoding )
  dup alias-encoding =  if			( [alias] id encoding ) 
     ." alias"  				( [alias] id encoding )
     ascii ( emit				( [alias] id encoding )
     base @ >r hex				( [alias] id encoding )
     2 pick 2 .r				( [alias] id encoding )
     r> base ! ascii ) emit space		( [alias] id encoding )
     cr						( [alias] id encoding )
  then						( [alias] id encoding )
[then]

  \ erase the header
  kbddata-buffer 0 /kbd-table-header fill	( [alias] id encoding )

  \ Now fill it.
  current-table$ 				( [alias] id encoding adr,len )
  dup kbddata-buffer >kbd-country-len c!	( [alias] id encoding adr len )
  kbddata-buffer >kbd-country swap move		( [alias] id encoding )
  dup alias-encoding =  if 			( alias id encoding )
     rot 					( id encoding alias )
     kbddata-buffer tuck		     ( id encoding buffer alias buffer )
     >kbd-alias c! 				( id encoding buffer )
     dup >kbd-alias-data insert-ptr ! 		( id encoding buffer )
  else 						( id encoding )
     kbddata-buffer				( id encoding buffer )
     dup >kbd-data insert-ptr !			( id encoding buffer )
  then						( id encoding buffer )
  tuck >kbd-coding c!				( id buffer )
  >kbd-type c!					( -- )
;

: add-kbd-table ( bytes -- )
  dup wbsplit				( bytes lo hi )
  kbddata-buffer >kbd-data-size tuck	( bytes lo addr hi addr )
  c! 1+ c!				( bytes )
  kbddata-buffer over 			( bytes addr bytes )
  dropin-insert-ptr @			( bytes addr bytes dest )
  swap cmove				( bytes )
  dropin-insert-ptr +!			( -- )

  writing-tables?			( writing? )
  kbddata-buffer >kbd-coding c@		( writing? encoding )
  table-encoding = and if		( -- )
    dropin-buffer >kbd-di-default c@ h# ff if	
      \ We haven't assigned a default keybd yet
      kbddata-buffer >kbd-type c@
      dropin-buffer >kbd-di-default c!
    then
  then					( -- )
;

: list-kbd ( addr len -- true )
   over					( addr len addr )
   dup >kbd-country			( addr len addr adr )
   swap >kbd-country-len c@		( addr len adr,len )
   ." Name: " type			( addr len )
   over >kbd-type c@ ." , id: " .x	( addr len )
   over >kbd-coding c@			( addr len encoding )
   dup table-encoding = if		( addr len )
     drop ." table"			( addr len )
   else					( addr len )
     diff-encoding = if 		( addr len )
        ." delta"			( addr len )
     else				( addr len )
        ." alias"			( addr len )
     then				( addr len )
   then					( addr len )
   cr 2drop true			( -- )
;

: list-kbds ( -- )
  ['] list-kbd is do-kbd-fn		( -- )
  dropin-buffer 5 +			( addr )
  .scan-kbds
;

: find-default-kbd ( adr len -- ok? )
  over >kbd-type c@			( adr len id )
  dropin-buffer >kbd-di-default c@ <>	( adr len flag? )
  dup if				( adr len flag? )
    nip nip				( flag? )
  else					( adr len flag? )
    nip swap				( flag? adr )
    ." Default Keyboard is: "		( flag? adr )
    dup >kbd-country			( flag? adr str )
    over >kbd-country-len c@		( flag? adr str len )
    type cr				( flag? adr )
    drop				( flag? )
  then					( flag? )
;

: write-kbd-dropin ( -- )
  dropin-buffer				( adr )
  dropin-insert-ptr @			( adr ptr )
  h# ff over c!				( adr ptr )
  1+ h# ff over c!			( adr ptr' )
  over >kbd-di-default c@ h# ff = if	( adr ptr' )
    2drop				( -- )
    ." No Default keyboard found" cr
    ." This probably means that there isn't a full table defined" cr
    abort
  else					( adr ptr' )
    ['] find-default-kbd is do-kbd-fn	( adr ptr' )
    over >kbd-di-data .scan-kbds	( adr ptr' )
  then					( adr ptr' )
[ifdef] list-kbds?			( adr ptr' )
  list-kbds				( adr ptr' )
[then]					( adr ptr' )
  1+ over -				( adr len )
  ofd @ fputs				( -- )
;

: savechar ( char -- ) kbd-char-ptr @ c! 1  kbd-char-ptr +! ;

variable num-deltas
defer delta-debug ' drop is delta-debug
defer table-debug ' noop is table-debug
defer build-table [ifdef] verbose? ' cr [else] ' noop [then] is build-table
[ifdef] debugging?
 fload ${BP}/pkg/keyboard/debug.fth
[then]

variable total-bytes total-bytes off
variable holding-ptr

: build-dropin-table ( -- )
  current-table 2@ $find if
    execute
  else
    ." Table Constructed improperly!" abort
  then
  0  num-deltas !
  \ FORCE a diffencoding
  diff-encoding kbddata-buffer >kbd-coding c!	( -- )
  insert-ptr @ holding-ptr !			( -- )

  0 delta-debug					( -- )
  keymap-size 0 do				( -- )
    \ save current ptr
    insert-ptr @ kbd-char-ptr !			( -- )

    \ temp place holders
    0 savechar					( -- )
    i savechar 0				( 0 )
    key-table  >k-altgmap i + c@		( 0 keycode )
    base-table >k-altgmap i + c@   over <> if	( 0 keycode )
      savechar 1 or				( flag )
    else					( keycode )
      drop  					( flag )
    then					( flag )
    key-table  >k-shiftmap i + c@		( flag keycode )
    base-table >k-shiftmap i + c@  over <> if	( flag keycode )
      savechar 2 or				( flag' )
    else					( flag keycode )
      drop 					( flag )
    then					( flag )
    key-table  >k-normalmap i + c@		( keycode )
    base-table >k-normalmap i + c@ over <> if	( keycode )
      savechar 4 or				( flag )
    else					( keycode )
      drop 					( flag )
    then					( flag )
    ?dup if					( flag )
      insert-ptr @ c!				( -- )
      1 delta-debug				( -- )
      kbd-char-ptr @ insert-ptr !		( -- )
      num-deltas dup @ 1+ swap !		( -- )
    then					( -- )
  loop						( -- )
  2 delta-debug					( -- )
  insert-ptr @ kbd-char-ptr !			( -- )
  h# ff savechar kbd-char-ptr @ insert-ptr !	( -- )
  num-deltas @					( diffs )
[ifdef] verbose? dup if ." , " dup .d ." diffs" then [then]
  dup 0= swap d# 96 > or if			( -- )
    \ If we have more than 96 diffs then it is more
    \ space efficient to change the table back to a
    \ table-encoding.
[ifdef] verbose? ." , table-encoding" [then]
    table-encoding kbddata-buffer >kbd-coding c! ( -- )
    key-table holding-ptr @ /keytable move	( -- )
    table-debug					( -- )
    holding-ptr @ /keytable + insert-ptr !	( -- )
  then						( -- )
  insert-ptr @ kbddata-buffer -			( bytes )
[ifdef] verbose? ." , " dup .d ." bytes" cr [then]	( bytes )
  total-bytes @ over + total-bytes !		( bytes )
  add-kbd-table					( -- )
;

: build-alias ( -- )
  current-table 2@ $find if
    execute
  else
    ." Table Constructed improperly!" abort
  then
  insert-ptr @ kbd-char-ptr !			( -- )
  h# ff savechar kbd-char-ptr @ insert-ptr !	( -- )
  insert-ptr @ kbddata-buffer -			( bytes )
  total-bytes @ over + total-bytes !		( bytes )
  add-kbd-table					( -- )
;

: all-done ( -- )
  write-kbd-dropin				( -- )
  ofd @ fclose
  ." Keyboard data = " total-bytes @ .d ." bytes" cr
;

fload ${BP}/pkg/keyboard/tablecode.fth

: >base-table ( addr -- ) base-table /keytable move ;
[ifdef] debugging?
  [ifdef] complete-tables?
    : >base-table ( addr -- ) drop ;
  [then]
[then]

: build-empty-table ( -- ) base-table 0 /keytable fill ;

