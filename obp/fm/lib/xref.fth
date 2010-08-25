\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: xref.fth
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
id: @(#)xref.fth 1.2 03/12/08 13:22:28
purpose: 
copyright: Copyright 2001-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.
 
\ XREF enables the whole thing.
[ifdef] XREF

\ We can't use the d# operators because they don't always exist
\ when we load this..

defer xref-prev-include-hook ' noop is xref-prev-include-hook
defer xref-prev-include-exit-hook ' noop is xref-prev-include-exit-hook
decimal

: xref-push-file ( str,len -- str,len )
   true  50 45 fsyscall
   xref-prev-include-hook
;

: xref-pop-file ( -- )
   false 50 45 fsyscall
   xref-prev-include-exit-hook
;

: (xref-notify) ( str,len ref? -- str,len )   49 45 fsyscall  ;

: xref-state ( n -- ) 51 45 fsyscall  ;

\  If  source-id  has been set to  0  or  -1
\  (as by  evaluate  or in user-interpretation state)
\  an attempt to get a line # will crash. 
: xref-line#? ( -- n true | false )                                              
   source-id dup 0= over -1 = or if
      drop false
   exit then 
   file-line true 
; 

: (xref-definition) ( str,len -- str,len ) xref-line#? if 1 (xref-notify) then ;
: (xref-reference)  ( str,len -- str,len ) xref-line#? if 0 (xref-notify) then ;
: (xref-hide) ( str,len --  str,len ) 2 (xref-notify) ;
: (xref-reveal) ( str,len -- str,len ) 3 (xref-notify) ;
: (xref-string) ( str,len -- str,len )  xref-line#? if 4 (xref-notify) then ;

: xref-init ( -- ok? ) -1 xref-state  ;

\  Defined in the host; needed in meta-compilation-target
\  so "IS" won't get confused
[ifnexist] include-hook
   headers
   defer include-hook       ' noop is include-hook
   defer include-exit-hook  ' noop is include-exit-hook
   headerless
[then]

: (xref-on) ( -- )
   ['] include-hook behavior is xref-prev-include-hook
   ['] include-exit-hook behavior is xref-prev-include-exit-hook
   ['] xref-push-file		is include-hook
   ['] xref-pop-file		is include-exit-hook
   ['] (xref-definition)	is xref-header-hook
   ['] (xref-reference)		is xref-find-hook
   ['] (xref-hide)		is xref-hide-hook
   ['] (xref-reveal)		is xref-reveal-hook
   ['] (xref-string)		is xref-string-hook
   ['] noop  is xref-on
   1 xref-state
;

: (xref-off) ( -- )
   ['] (xref-on) is xref-on
   ['] xref-prev-include-hook behavior  is include-hook
   ['] xref-prev-include-exit-hook behavior is include-exit-hook
   ['] noop						( acf )
   dup				is xref-header-hook	( acf )
   dup				is xref-find-hook	( acf )
   dup				is xref-hide-hook	( acf )
   dup				is xref-reveal-hook	( acf )
   dup				is xref-string-hook	( acf )
   drop							( )
   0 xref-state						( )
;
hex

' (xref-off) is xref-off
' (xref-on)  is xref-on
[then]
