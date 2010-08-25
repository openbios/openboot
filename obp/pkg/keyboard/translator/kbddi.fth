\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: kbddi.fth
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
\ id: @(#)kbddi.fth 1.7 99/02/11
\ purpose: 
\ copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved
\
\ Support for drop in keyboard tables
\ 

headers

: current ( -- )
  current-kbd dup c@ if		( addr )
    dup cstrlen			( str,len )
  else				( addr )
    drop " <UNKNOWN>"		( str,len )
    2dup >kbd-name		( str,len )
  then				( str,len )
  ." Keyboard: " type cr	( -- )
;

headerless

h# 20 instance buffer: kbdname

instance variable found?
instance variable install-usa?

: get-dropin-info ( kbd-type$ --  false | magic$ dropin$ true )
  2dup " sun" $=  if  2drop " KBDT" " serialkbds" true exit then 	   
  2dup " usb" $=  if  2drop " UKBD" " usbkbds" true exit then 	   
  2drop false
;

: .unsupported-kbd ( -- ) " No keyboard support found" ;

: find-kbd ( addr len -- more? )
   drop					( addr )
   install-usa? @  if			( addr )
      dup >kbd-country 			( addr str )
      over >kbd-country-len c@ 		( addr str,len )
      " usa" $= 			( addr flag? ) 
   else 				( addr )
      dup >kbd-type c@ keybid @ = 	( addr flag? )
   then					( addr flag? )
   dup found? ! if			( addr )
     dup >kbd-coding c@  		( addr coding )
     alias-encoding =  if 		( addr )
        >kbd-alias c@ keybid !    	( -- ) 
        found? off			( -- )
        restart-scan? on		( -- )
     else				( addr )
        dup >kbd-country		( addr str )
        over >kbd-country-len c@	( addr str,len )
        >kbd-name			( addr )
        >kbd-type			( addr' )
        set-keytable			( -- )
     then				( -- )
   else					( addr )
     drop				( -- )
   then					( -- )
   found? @ 0=				( flag? )
;

: (install-kbd) ( buffer id -- )
  ['] find-kbd is do-kbd-fn	( buffer id )
  keybid !			( buffer )
  >kbd-di-data .scan-kbds	( -- )
;

: install-usa-maybe  ( addr id -- )
  found? @ if 2drop exit then

  install-usa? on
  swap 0		( id addr dummy-id )
  (install-kbd)		( id )
  found? @ if		( id )
    ." Can't find keyboard table for keyboard layout code " .h cr
    ." Using USA keyboard table" cr
  else
    drop
  then
;

headers
: install-kbd  ( keyboard-type$ type -- error? )
  install-usa? off			( magic$ dropin$ type )
  found? off				( magic$ dropin$ type )
  ['] noop is base-key-table		( magic$ dropin$ type )
  -rot find-drop-in  if			( magic$ type addr len )
     2dup >r >r drop			( magic$ type addr )
     2swap 2 pick >kbd-di-magic 4 $=  if ( type addr )
       dup >kbd-di-default c@		( type addr default )
       2dup (install-kbd)		( type addr default )
       rot				( addr default type )
       dup nvram-table? if		( addr default type )
         3drop		 		( -- )
       else				( addr default type )
         tuck <> if			( addr type )
           2dup (install-kbd)		( addr type )
           install-usa-maybe		( -- )
         else				( addr type )
           2drop			( -- )
         then				( -- )
       then				( -- )
     else				( type' addr )
       2drop				( -- )
     then				( -- )
     r> r> free-drop-in			( -- )
  else					( type' )
    drop				( -- )
  then					( -- )
  found? @ if false exit then		( -- false )
  .unsupported-kbd  true		( str,len true )
;
