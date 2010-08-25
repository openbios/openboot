\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: debug.fth
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
\ id: @(#)debug.fth 1.3 99/02/25
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
\

: .line-dump ( -- ) ." DUMP: " kbd-char-ptr @ insert-ptr @ do i c@ . loop cr ;
: .rbase ( base -- ) .r base ! space ;
: .pdec ( xx -- ) base @ swap decimal 2 .rbase ;
: .poct ( xx -- ) base @ swap 8 base ! 3 .rbase ;
: .phex ( xx -- ) base @ swap hex 2 .rbase ;

: .decode-key ( code -- )
  case
    h#  8 of ." bs      " endof
    h#  9 of ." tab     " endof
    h#  a of ." linefeed" endof
    h#  d of ." carret  " endof
    h# 1b of ." esc     " endof
    h# 20 of ." bl      " endof

    h# 82 of ." shift   " endof
    h# 83 of ." power   " endof
    h# 84 of ." ctrl    " endof
    h# 85 of ." altg    " endof
    h# 86 of ." nop     " endof
    h# 87 of ." oops    " endof
    h# 88 of ." hole    " endof

    h# 90 of ." error   " endof
    h# 91 of ." idle    " endof
    h# 92 of ." mon-off/on" endof

    h# 7e of ." error   " endof
    h# 7f of ." del     " endof

    dup h# 0 h# 20 between if		( char )
      ." h# " dup .phex 2 spaces	( -- )
    else				( char )
      dup h# 90 > if			( char )
        ." o# " dup .poct space		( char )
      else				( char )
        ." ascii " dup emit space	( char )
      then				( char )
    then				( char )
  endcase  space			( -- )
;

\ interact

: .empty ( -- )		d# 9 spaces ;
: insert@ ( n -- )	insert-ptr @ + c@ ;
: .entry ( str,len -- )	1 insert@ ." d# " .pdec type space ;
: 1st@ ( -- )		2 insert@ .decode-key ;
: 2nd@ ( -- )		3 insert@ .decode-key ;
: 3rd@ ( -- )		4 insert@ .decode-key ;

: .delta-debug ( type -- )
  case
    0 of
      cr
      ." >> decimal" cr ." >>" cr
      ." >> d# " kbddata-buffer >kbd-type c@ .d ." keyboard: "
       current-table$ type cr
      ." >> \ Normal Shift    Alt      Key#"
    endof
    2 of
      cr ." >> kend" cr
    endof
  endcase
  insert-ptr @ c@			( bits )
  ?dup if				( bits )
    cr ." >> "				( bits )
    case
      \       Normal	Shifted	Alt	Code
      d# 0 of .empty	.empty	.empty	" none???"	.entry	endof
      d# 1 of .empty	.empty	1st@	" ak"		.entry	endof
      d# 2 of .empty	1st@	.empty	" sk"		.entry	endof
      d# 3 of .empty	2nd@	1st@	" sak"		.entry	endof
      d# 4 of .empty	.empty	.empty	" normal?"	.entry	endof
      d# 5 of 2nd@	.empty	1st@	" nak"		.entry	endof
      d# 6 of 2nd@	1st@	.empty	" nsk"		.entry	endof
      d# 7 of 3rd@	2nd@	1st@	" allk"		.entry	endof
    endcase	 			( -- )
  then					( -- )
;

: .table-debug ( -- )
  cr ." >> : do8 8keys ;" cr
  ." >> d# " kbddata-buffer >kbd-coding c@ .d
  ." full-keyboard: " current-table$ type cr
  key-table 3 0 do		( addr )
    i case
      0 of ." >> \ Normal Keys" endof
      1 of ." >> \ Shifted Keys" endof
      2 of ." >> \ Alt Keys" endof
    endcase cr
    keymap-size 0 do		( addr )
      ." >> "			( addr )
      d# 8 0 do			( addr )
        dup i + c@ .decode-key	( addr )
      loop ." do8" cr		( addr )
      d# 8 +			( addr' )
    8 +loop			( addr' )
  loop drop			( -- )
;

: show3 ( addr -- )
  dup >k-altgmap   c@ .decode-key
  dup >k-shiftmap  c@ .decode-key
      >k-normalmap c@ .decode-key
;

: show-index ( index -- )
  dup
  ."             Alt      Shift    Normal" cr
  ." Keytable  : " key-table + show3 cr
  ." Basetable : " base-table + show3 cr
;
: si show-index ;

[ifndef] complete-tables?
' .delta-debug is delta-debug
[else]
' .table-debug is table-debug
[then]
