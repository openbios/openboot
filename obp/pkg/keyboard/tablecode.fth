\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tablecode.fth
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
\ id: @(#)tablecode.fth 1.2 99/02/25
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
\

: do-keyboard  does> set-keytable  ;


\ The compiler for creating keymaps

: keyboard:  ( id -- )  \ name
   dup diff-encoding  new-kbd-table c,   diff-encoding  c, 
   do-keyboard
;
: full-keyboard:  ( id -- )  \ name
   dup table-encoding  new-kbd-table c,  table-encoding c, 
   do-keyboard
;
: alias-keyboard: ( id alias-id -- ) \ name
   over alias-encoding new-kbd-table c,  alias-encoding c, 
   do-keyboard
;

\   The next five following words are used to store the positions and their
\ associate keys which are different than the default keyboard (Spain keybd)
\   In front of each position#, there will be stored a flag byte which
\ indicates which of the three keys are to be changed. If bit 0 is high,
\ then the alternate key is being changed, \ if bit 1 is high, then the
\ shifted key is being changed; and if bit 2 is high then the normal key
\ is being changed.

\ allk is used to replace all three normal/shifted/altg keys associate with
\ this postition.
: allk  ( normal-key shifted-key altg-key position -- )
   7 c, c, c, c, c,
;

\ sak is used to replace the shifted and altg keys which are associated with
\ this postition.
: sak  ( shifted-key altg-key position -- )
   3 c, c, c, c,
;

\ nsk is used to replace the normal and shifted keys which are associated with
\ this postition.
: nsk  ( normal-key shifted-key position -- )
   6 c, c, c, c,
;

\ nak is used to replace the normal and altg keys which are associated with
\ this postition.
: nak  ( normal-key altg-key position -- )
   5 c, c, c, c,
;

\ nk is used to replace the normal key which is associated with this postition.
: nk  ( normal-key position -- )
   4 c, c, c,
;

\ ak is used to replace the altg key which is associated with this postition.
: ak  ( altg-key position -- )
   1 c, c, c,
;

\ ak is used to replace the shift key which is associated with this postition.
: sk  ( shifted-key position -- )
   2 c, c, c,
;

\ kend is used to marked the end of the list.
: kend  ( -- ) d# 255 c, build-table ;

: kend-alias  ( -- )  build-alias ;

: 8keys  ( key1 key2 ... key8 -- )  0 7  do  i roll c,  -1 +loop  ;

