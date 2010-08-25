\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: reboot.fth
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
id: @(#)reboot.fth 1.3 99/05/20
purpose: 
copyright: Copyright 1998 Sun Microsystems, Inc.  All Rights Reserved

\ Create the hash storage area.
" reboot-info" create-nvhash create-config-hash		( acf )
headers
create reboot-info token, does> token@ ;
headerless

\ Mark the area as non-volatile so garbage collection won't release
\ its resources by assigning an acf other than 'crash'.
' reboot-info reboot-info >body token!

d# 255 3 wa+ constant /reboot-info-buf
/reboot-info-buf buffer: reboot-info-buf
true value load-reboot-info?

: (get-reboot-info ( -- bootpath,len line# column# )
   options-open?  if
      load-reboot-info?  if				(  )
         reboot-info-buf /reboot-info-buf erase		(  )
         reboot-info dup get				( acf adr len )
         /reboot-info-buf min reboot-info-buf swap	( acf adr dest len )
         move						( acf )
         3 perform-action				(  )
         false to load-reboot-info?			(  )
      then						(  )
   then							(  )
   reboot-info-buf  >r					(  )
   r@  2 wa+ count					( adr len )
   r@       w@						( adr len line# )
   r@  wa1+ w@						( adr len line# column# )
   r> drop						(  )
;

: (save-reboot-info ( bootpath,len line# column# -- )
   reboot-info-buf  >r				( bootpath,len line# column# )

   \ Save the terminal emulator cursor position
   r@ wa1+ w!					( bootpath,len line# )
   r@      w!					( bootpath,len )
   tuck						( len bootpath,len )

   \ Remember the boot path
   d# 255 min  r@ 2 wa+  place  r>		( len buf-addr )
   swap 3 wa+					( buf-addr len' )
   2dup reboot-info-buf swap move		( buf-addr len' )
   options-open?  if				( buf-addr len' )
      reboot-info set				(  )
   else						( buf-addr len' )
      2drop					(  )
   then						(  )
;

' (save-reboot-info is save-reboot-info
' (get-reboot-info is get-reboot-info


