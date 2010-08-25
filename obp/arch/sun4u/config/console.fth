\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: console.fth
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
id: @(#)console.fth 1.5 01/04/06
purpose: 
copyright: Copyright 1999-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless

defer finish-device-hook ( -- )		' noop	is finish-device-hook

headers

overload: finish-device ( -- )  finish-device-hook  finish-device  ;
' finish-device 0 h# 127 set-token

headerless

vocabulary console-claimer
also console-claimer definitions

: make-my-alias ( name$ -- )
   ['] aliases $vfind if  drop  exit  then	( -- )
   my-self ihandle>phandle			( name$ phandle )
   dup " reg" rot get-package-property if	( name$ phandle )
      3drop					( -- )
   else						( name$ phandle xdr,len )
      2drop					( name$ phandle )
      phandle>devname				( name$ path$ )
      $devalias					( -- )
   then
;

: keyboard$	" keyboard" ;
: mouse$	" mouse" ;

0 value kbd-tmp
0 value mouse-tmp

: install-device-hook ( acf acf -- )
   ['] finish-device-hook behavior swap do-is
   to finish-device-hook
;
: reset-device-hook ( acf -- )
   to  finish-device-hook
   finish-device-hook
;

: install-keyboard-alias ( -- )
   kbd-tmp  reset-device-hook
   keyboard$ make-my-alias
;
: install-mouse-alias ( -- )
   mouse-tmp  reset-device-hook
   mouse$ make-my-alias
;

also magic-properties definitions
headers

overload: name ( xdr,len name$ -- )
   \ This is horrible, and is here only because using the keyboard and mouse
   \ properties was considered to be SUN centric as USB code could be written
   \ by a 3rd party and used as a console on SUN machines, and unless the
   \ keyboard/mouse properties were formally defined their use was ambiguous.
   2over decode-string 2swap 2drop
   2dup keyboard$ $= if
      2drop ['] install-keyboard-alias ['] kbd-tmp install-device-hook
   else
      mouse$ $= if
         ['] install-mouse-alias ['] mouse-tmp install-device-hook
      then
   then
   name
;

: keyboard ( 0 0 str$ -- 0 0 )
   2 pick 0= if
      keyboard$ make-my-alias
   then
;

: mouse ( 0 0 str$ -- 0 0 )
   2 pick 0= if
      mouse$ make-my-alias
   then
;

previous previous definitions

headerless
