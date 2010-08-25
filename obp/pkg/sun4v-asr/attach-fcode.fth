\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: attach-fcode.fth
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
id: @(#)attach-fcode.fth 1.2 06/06/02
purpose: attach fcode - dropin side
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

0 value asr-fatal-state

: cstrlen ( cstr -- length )
   dup  begin  dup c@  while  ca1+  repeat  swap -
;

: cscount ( cstr -- adr len )  dup cstrlen ;

\ returns ptr to the next byte after the cstring
: cmn-cstr ( ptr -- ptr' )  cscount 2dup cmn-append + 1+ ;

\ state   [key1][0][key2][0][keyn][0]
: list-disabled-keys  ( -- )
   (statelen) dup 0= if			( len )
      drop exit				( )
   then					( len )
   dup alloc-mem			( len buf )
   dup (asr-state) over			( len buf len buf )
   cmn-error[ " The following devices are disabled:"r"n" cmn-append
   tuck + swap				( len buf end buf )
   begin				( len buf end buf )
      2dup > while			( len buf end buf )
      "     " cmn-append		( len buf end buf' )
      cmn-cstr				( len buf end buf' )
      " "r"n" cmn-append		( len buf end buf' )
   repeat 2drop				( len buf )
   " " ]cmn-end				( len buf )
   swap free-mem			( )
;

: asr-dis-ovr-msg$  ( -- $ )  " Disabled device is in use" ;

: (check-asr-state)  ( -- )
   asr-fatal-state case
       0 of  endof
      -2 of  cmn-fatal[  asr-dis-ovr-msg$ ]cmn-end  endof
   endcase

   list-disabled-keys
;

: (asr-attach)  ( -- )
   " asr-attach"			( meth$ )
   " builtin-drivers" find-package if	( meth$ )
      find-method if
         >r				( )  ( r: attach-xt )
         ['] (check-asr-state)
         ['] noop			( cas-acf dh-xt )
         r> execute			( ) ( r: )
      else				( )
         cmn-fatal[ " unable to locate asr-attach routine" ]cmn-end
      then				( )
   else					( meth$ )
      2drop				( )
      cmn-fatal[ " asr-attach: unable to find builtins package" ]cmn-end
   then
;
