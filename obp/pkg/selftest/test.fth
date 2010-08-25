\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: test.fth
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
id: @(#)test.fth 1.11 03/04/04
purpose: test, test-dev, test-all, obdiag definitions 
copyright: Copyright 2000-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\
\ There are no public interfaces in this file.
\
hex
headers

headerless

create has-no-selftest  ( -- p$adr )	\  This location becomes the throw-code
   ,"  device has no selftest method"	\  and will also supply the message

: .testing ( $adr,len -- $adr,len )
   ??cr ." Testing " 2dup type cr
;

[ifnexist] "selftest"
: "selftest" ( -- $adr,len ) " selftest" ;
[then]

0 value tested-device		\ phandle of current device under test.
h# 100  buffer: error-buffer

: abort-selftest-msg ( -- )
   error-buffer count  set-abort-message -2 throw
;

: (save-string) ( str,len -- )  error-buffer $cat  ;

: save-signed ( n -- )
   l->n push-decimal (.) pop-base
   (save-string)
;

: .error-message ( str,len -- )
   ??cr ." Error: " type cr
;

\ This is not exactly the same as execute-device-method because using
\ that routine doesn't permit the catching of a throw from selftest vs
\ a throw from a failed open, resulting in incorrect 'missing selftest'
\ messages.

\  XXX  The  silent?  param is ambiguous and confusing.  See BugId 4788803

: ($call-selftest) ( path$ silent? -- status )
   -rot 					( silent? path$ )
   0 package(  current-device >r         	( silent? path$ )
   ['] open-path catch if			( silent? ??path$ )
      \ failure to open is not a fail.		( silent? path$ )
      3drop 0 0					( status throw? )
   else						( silent? )

      \  XXX  Search for selftest is unnecessary.  See BugId 4788803
      \
      "selftest" my-voc (search-wordlist) 0= if	( silent? )
         drop true has-no-selftest		( status throw-code )
      else					( silent? acf )
         swap 0= if                             ( acf )
            error-buffer count .testing 2drop
         then                                   ( acf )
         catch				      ( ?? throw-code | status throw=0 )
         mark-as-no-boot
      then					( status throw-code? )
      close-chain
      device-end
   then						( status throw-code? )
   r> push-device  )package
   throw					( status )
;

\ We call diag-hook only when selftest returns non-zero
\ error code; in case of erroneous failures of the
\ selftest, like abort, throw or incorrect number
\ of arguments returned by the selftest, diag-hook is
\ not called. In such cases ,however test-dev always
\ returns non-zero status on the stack and prints an 
\ associated message; test stores an associated message
\ in the abort-buffer and the message is printed by OBP;
\ test-all prints an associated messages for every
\ selftest which completes abnormally as well.

: do-diag-hook ( status -- )  tested-device diag-hook  ;

\ a catch on stacked-$call-selftest can only return 0 or -2.
\ -2 for a throw from a selftest, 0 otherwise.

: stacked-$call-selftest ( dev$ not-silent? -- status )
   \ push a few zeroes just in case a bad selftest consumes
   \ the stack (we will throw anyway but this ensures that
   \ the caller's stack remains unharmed)

    >r 2>r  0 0 0 0 0  2r>  r>			( 0 0 0 0 0 $dev not-silent? )
    depth 2- >r 	\  Expected result depth

   \  XXX  Test for no-selftest is unnecessary.  See BugId 4788803
   \
   ['] ($call-selftest) catch ?dup  if		( 0 0 0 0 0 ?? catch? )
      dup has-no-selftest = if			( ?? no-selftest-throw-code )
         count (save-string)	 		( ?? ) 
      else					( ?? catch? )
         "  selftest terminated abnormally"	( ?? catch? str,len )
         (save-string)				( ?? catch? )
         dup -2 = if				( ?? catch? )
            drop " , reason: " (save-string)	( ?? )
            abort-message (save-string)		( ?? )
         else					( ?? catch? ) 
            dup in-dictionary?  if		( ?? catch? )
               " , reason: " (save-string)	( ?? catch? )
               count (save-string) 		( ?? ) 
            else				( ?? catch? )
               " , throw code = " (save-string)	( ?? catch? )
               save-signed 			( ?? )  
            then				( ?? ) 
         then					( ?? )
      then					( ?? )
      abort-selftest-msg			( ?? )
   then						( ?? )
   depth r> - ?dup if				( ?? delta )
      "  selftest resulted in net stack depth change of "
      (save-string)  save-signed			( ?? )
      abort-selftest-msg			( )
   then						( 0 0 0 0 0 status )
   nip nip nip nip nip		        	( status )
;

\ sets or modifies "status" property for the tested device
\ based on results of testing: if selftest passes, and there
\ is no "status" property, declare "status" property and
\ set it to "okay"; if there is already "status" property,
\ do nothing; Note that if the "status" property is set
\ to "fail", subsequent passes will not change "status"
\ to "okay".
\ if selftest fails and there is no "status" property, create
\ "status"="fail"; if "status" property exists but doesn't
\ start with "fail" change "status"="fail".

: "status" ( -- $adr,len ) " status" ;
: "fail"   ( -- $adr,len ) " fail"   ;

: set-fail-property ( -- )  "fail" "status" string-property ;
: set-okay-property ( -- ) " okay" "status" string-property ;

: set-status-property ( status -- )
   my-self current-device 2>r                           ( R: ih ph)
   0 to my-self tested-device to current-device         ( R: ih ph)
   ?dup  if                                             ( R: ih ph)
      do-diag-hook                                      ( R: ih ph)
      "status" tested-device get-package-property  if   ( R: ih ph)
         set-fail-property      \ create status="fail"  ( R: ih ph)
      else                                              ( R: ih ph)
         decode-string drop nip nip "fail" comp  if     ( R: ih ph)
            set-fail-property   \ change status="fail"  ( R: ih ph)
         then                                           ( R: ih ph)
      then                                              ( R: ih ph)
   else                                                 ( R: ih ph)
      "status" tested-device get-package-property  if   ( R: ih ph)
         set-okay-property                              ( R: ih ph)
      else                                              ( R: ih ph)
         2drop                                          ( R: ih ph)
      then                                              ( R: ih ph)
   then                                                 ( R: ih ph)
   2r> push-device to my-self                           ( R: )
;

\ If not-silent? is true then we print the error-message here,
\ if not then we propogate the catch code assuming our caller
\ is catching.

: $call-selftest ( not-silent? dev$ -- status )
   rot >r                                       ( dev$ )      ( R: not-silent? )
   r@ ['] stacked-$call-selftest catch -2 = if  ( ?? )
      r> if                                     ( ?? )        ( R:  )
         3drop abort-message .error-message     ( ?? )
      else                                      ( ?? )
         -2 throw                               ( ?? )      
      then                                      ( ?? )
      true                                      ( fail )
   else                                         ( ?? status ) ( R: not-silent? )
      dup dup set-status-property  if           ( status )
         "  selftest failed, return code = "    ( status $adr,len )
	 (save-string)                          ( status )
         dup save-signed                        ( status )
         r> if                                  ( status )    ( R:  )
            error-buffer count .error-message   ( status ) 
         else                                   ( status )
            abort-selftest-msg                  ( ) 
         then                                   ( status )
      else                                      ( status )    ( R: not-silent? )
         r> drop                                ( status )    ( R:  )
      then                                      ( status )
   then                                         ( status )
;

: (test-dev)  ( not-silent? name,len -- status )
   0 error-buffer c!				( not-silent? dev$ )
   2dup locate-device if			( not-silent? dev$ )
      " Device " (save-string) (save-string)	( not-silent? )
      "  not found" (save-string)		( not-silent? )
      if                                        ( )
         error-buffer count .error-message      ( )
         true exit                              ( status )
      else                                      ( )
         abort-selftest-msg                     ( )
      then                                      ( )
   then						( not-silent? dev$ phandle )
   to tested-device				( not-silent? dev$ )
   2dup (save-string)				( not-silent? dev$ )
   tested-device load-selftest-dropin drop	( not-silent? dev$ )
   $call-selftest				( status )
;

headerless
