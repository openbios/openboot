\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: install.fth
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
\ id: @(#)install.fth 1.6 99/02/25
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

headerless
\ The default keytable, that deltas are built upon.
instance defer		base-key-table

\ temporary pointer for table building
instance variable	kbd-char-ptr

\ This is the keyboard identify function, return true to continue
\ processing.
instance defer do-kbd-fn ( addr len -- more? )

\ A buffer that holds the current keyboard table
/keytable	instance buffer: key-table

: nextchar  ( -- char )  kbd-char-ptr @ c@ 1 kbd-char-ptr +!   ;

: ?setkey  ( flags adr -- flags' adr' )
   over 1 and  if   nextchar over c!  then  	( flags adr )
   swap u2/  swap keymap-size -                 ( flags adr )
;

: set-diff-keytable  ( difflist-adr -- )
   kbd-char-ptr !				( )
   begin                        		( )
      nextchar  dup d# 255 <>			\ While there are more keys
   while                       			( install-flags flag )
      nextchar					( install-flags index )
      >k-altgmap				( install-flags index' ) 
      key-table +				( install-flags adr )
      ?setkey					( install-flags adr )
      ?setkey					( install-flags adr )
      ?setkey					( install-flags adr )
      2drop
   repeat
   drop
;

: set-keytable  ( table-adr -- )
   1+							\ Skip id byte
   dup c@ case						( adr selector )
      diff-encoding   of  base-key-table 1+ set-diff-keytable endof	( )
      table-encoding  of  1+ key-table  /keytable cmove endof		( )
      alias-encoding  of  drop endof					( )
      ( default: adr selector )
         ." Invalid keymap format byte"  nip			( selector )
   endcase							( )
;

instance variable restart-scan?

: next-kbd-addr ( addr-orig addr len -- addr-orig addr len )
   restart-scan? @  if               ( addr-orig addr len )
      2drop                          ( addr-orig )
      dup dup >kbd-data-size         ( addr-orig addr addr' )
      dup 1+ c@ swap c@              ( addr-orig addr lo hi )
      bwjoin                         ( addr-orig addr len )
      restart-scan? off              ( addr-orig addr len )
   then                              ( addr-orig addr len )
;

: .scan-kbds ( addr )
  restart-scan? off			( addr-orig )
  dup					( addr-orig addr )
  true begin				( addr-orig addr more? )
    over >kbd-data-size			( addr-orig addr more? addr' )
    dup 1+ c@ swap c@			( addr-orig addr more? lo hi )
    bwjoin				( addr-orig addr more? len )
    2dup			( addr-orig addr more? len more? len )
    h# ffff <>			( addr-orig addr more? len more? end? )
    and while				( addr-orig addr more? len )
      nip next-kbd-addr			( addr-orig addr len )
      2dup +				( addr-orig addr len addr' )
      -rot do-kbd-fn			( addr-orig addr' more? )
  repeat 3drop drop			( -- )
;

