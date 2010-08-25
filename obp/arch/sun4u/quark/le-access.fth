\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: le-access.fth
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
id: @(#)le-access.fth 1.5 02/05/02
purpose: 
copyright: Copyright 1994-1995,2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
alias le-rb@ rb@
alias le-rb! rb!

: le-rx@ ( vadr -- x )  x@   xbflip  ;
: le-rl@ ( vadr -- l )  ll@  lbflip  ;
: le-rw@ ( vadr -- w )  lw@  wbflip  ;

: le-rx! ( x vadr -- )  >r xbflip r> x!  ;
: le-rl! ( l vadr -- )  >r lbflip r> ll!  ;
: le-rw! ( l vadr -- )  >r wbflip r> lw!  ;

also hidden also forth
: le-xpeek ( adr -- false | value true )  xpeek xbflip  ;
: le-lpeek ( adr -- false | value true )  lpeek lbflip  ;
: le-wpeek ( adr -- false | value true )  wpeek wbflip  ;

: le-xpoke ( value adr -- flag )  swap xbflip swap xpoke  ;
: le-lpoke ( value adr -- flag )  swap lbflip swap lpoke  ;
: le-wpoke ( value adr -- flag )  swap wbflip swap wpoke  ;
previous previous

: setup-le-fcodes ( -- )
   ['] le-rw@ false h# 232 set-token
   ['] le-rw! false h# 233 set-token
   ['] le-rl@ false h# 234 set-token
   ['] le-rl! false h# 235 set-token
   ['] le-wpeek false h# 221 set-token
   ['] le-lpeek false h# 222 set-token
   ['] le-wpoke false h# 224 set-token
   ['] le-lpoke false h# 225 set-token
;

: restore-fcodes ( -- )
   ['] rw@ false h# 232 set-token
   ['] rw! false h# 233 set-token
   ['] rl@ false h# 234 set-token
   ['] rl! false h# 235 set-token
   ['] wpeek false h# 221 set-token
   ['] lpeek false h# 222 set-token
   ['] wpoke false h# 224 set-token
   ['] lpoke false h# 225 set-token
;

headers
