\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: banner.fth
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
id: @(#)banner.fth 3.17 04/05/26
purpose: Displays banner describing system configuration
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

d# 128 constant max-logo-width

variable logo?
: ?spaces  ( -- )
   logo? @  if  max-logo-width  stdout-char-width  / 2+  spaces  then
;

variable banner-start
: .logo  ( -- )
   logo? @  if
      banner-start @
      #line @ - stdout-line# +
      oem-logo?  if  oem-logo drop  else  sun-logo  then   ( line# adr )
      logo-width logo-height  stdout-draw-logo
   then
;

: test-logo  ( -- )
   \ Decide in advance whether or not to display a logo so that the
   \ text information may be located correctly.

   false logo? !

   stdout @  0=  if  exit  then

   " device_type"  stdout @  ihandle>phandle  get-package-property  0= if
      ( adr len )  get-encoded-string  " display"  $=  logo? !
   then
;

\ If wrap mode is enabled, and there arent enough lines to display the
\ banner (the banner occupies 6 lines) without wrapping, reposition 
\ banner to line 0
: test-wrap ( -- )
   logo? @ if
      stdout @ package(
      #scroll-lines 0=  if
         screen-#rows stdout-line# - 6 <  if
            toggle-cursor
            0 set-line
         then
      then
      )package
   then
;

headers

true value auto-banner?
: suppress-banner  ( -- )  false to auto-banner?  ;

: banner  ( -- )
   cr
 
   auto-banner?  if  " banner-" do-drop-in  then

   test-logo

   test-wrap

   #line @ banner-start !
   oem-banner?  if
      cr ?spaces oem-banner type  cr cr
   else
      ?spaces  cpu-model type      ." , "  .keyboard-type                   cr
      ?spaces .copyrights
      ?spaces  .rom                ." , "  .memory         ." , "  .serial  cr
[ifndef] RELEASE
      ?spaces  sub-release ". cr
[then]
      ?spaces  .ether              ." , "  .hostid         ." ."            cr
   then

   cr  cr

   idprom-valid? 0=  if  ." The IDPROM contents are invalid" cr  then

   .logo  cr

   auto-banner?  if  " banner+" do-drop-in   then

   \ If "banner" is executed inside nvramrc, we may assume that the
   \ "probe-all install-console banner" sequence has been taken care of,
   \ so it isn't necessary to execute it again after nvramrc is finished.

   suppress-banner
;

: ?banner ( -- )  min+mode?  if  banner  else  suppress-banner  then  ;
