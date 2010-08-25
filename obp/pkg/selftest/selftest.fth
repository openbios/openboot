\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: selftest.fth
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
id: @(#)selftest.fth 1.4 02/12/18
purpose: create the external interfaces to obdiag
copyright: Copyright 2000-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\
\ this is called to ensure that after selftests run the machine is reset
\ before it boots.
: mark-as-no-boot ( -- )  true to already-go?  ;

: "selftest" ( -- $adr,len ) " selftest" ;

: load-selftest-dropin ( phandle -- 0 )
   "selftest" rot find-method dup if		( acf acf )
      2drop mark-as-no-boot  false		( 0 )
   then						( 0 )
;

alias run-obd-scripts  noop

fload ${BP}/pkg/selftest/test.fth

headers

: test ( -- ) \ device-specifier
   false optional-arg$				( silent? path$ )
   ?dup if					( silent? path$ )
      .testing					( silent? path$ )
      (test-dev) drop				( )
   else						( silent? adr )
      2drop					( )
      ??cr ." No device name specified" cr
   then
;

\
\ A silent scriptable way to run tests
\
: test-dev ( name,len -- 0 | error-code )
   diagnostic-mode? if	 .testing   then	( name,len )
   true -rot (test-dev)				( status )
;

headerless

: property-exists? ( prop$ phandle -- flag )
   get-package-property  if  false  else  2drop true  then
;

: run-selftest	 ( -- )
   current-device >r				(  )		( R: phandle )
   " reg"  r@ property-exists?			( exists? )	( R: phandle )
   if						(  )		( R: phandle )
      r@ load-selftest-dropin drop
      "selftest"  r@ (search-wordlist)		( acf true | false ) ( R: ph )
      dup if  nip  then  if			( )
         true r@ phandle>devname		( not-silent? dev$ ) ( R: ph )
         .testing
         0 error-buffer c!
         2dup (save-string)
 	 r@ to tested-device
	 $call-selftest  drop			(  )		( R: phandle )
      then
   then						(  )		( R: phandle )
   r> drop					(  )		( R:  )
;

\ A user interface command
headers

: test-all  ( -- )
   optional-arg-or-/$			( $devname )
   2dup find-device			( $devname )
   run-selftest				( )
   ['] run-selftest  scan-subtree	( )
;

headerless
