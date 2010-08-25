\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: builddi.fth
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
\ id: @(#)builddi.fth 1.15 01/10/17
\ purpose: 
\ copyright: Copyright 1997-1999, 2001 Sun Microsystems, Inc.  All Rights Reserved
\

fload ${BP}/pkg/keyboard/tables/usb/options.fth

." Building the USB Keyboard dropin table." cr

\ Ensure that any instance data is removed
: instance ;

fload ${BP}/pkg/keyboard/headers.fth
fload ${BP}/pkg/keyboard/keytable.fth
fload ${BP}/pkg/keyboard/keycodes.fth
fload ${BP}/pkg/keyboard/tables/usb/keycodes.fth
fload ${BP}/pkg/keyboard/install.fth

fload ${BP}/pkg/keyboard/tableutil.fth

decimal
showstack

\ write the magic number and update the ptr
" UKBD" dropin-buffer >kbd-di-magic swap cmove
  h# ff dropin-buffer >kbd-di-default c!
        dropin-buffer >kbd-di-data dropin-insert-ptr !

." Loading master USB table." cr
fload ${BP}/pkg/keyboard/tables/usb/usb-us.fth
' usa is base-key-table

build-empty-table


[ifdef] usa-relative-default

." Keyboard definitions based upon USA" cr

: build-delta-table ( acf -- ) usa key-table >base-table ;

' build-delta-table is base-key-table

[else]

." Converting Keyboard Tables to *Spain* relative" cr

spain key-table >base-table

fload ${BP}/pkg/keyboard/tables/usb/usb-spanish.fth

d# 1024 buffer: spain-base
spain key-table spain-base /keytable move

: new-delta-code
  \ All of our diff files are built relative to USA, so we
  \ need to setup key-table with USA first
  usa

  \ However, in this case we want diffs relative to Spain so we'll copy
  \ the already compiled Spain table into the base-table, which will be
  \ used for diff generation.
  spain-base >base-table
;

' new-delta-code is base-key-table

[then]

\ Prior to this point we have just been loading the master tables, and haven't
\ written any dropin data yet.
\
' build-dropin-table is build-table
." Loading USB Keyboard tables" cr

\ Finally the keyboard data starts
writing usbkbds.dat
true to writing-tables?

fload ${BP}/pkg/keyboard/tables/usb/usb-us.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-spanish.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-arabic.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-belgium.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-danish.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-finnish.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-french.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-german.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-italian.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-netherlands.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-norwegian.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-portuguese.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-swedish.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-swiss-french.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-swiss-german.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-turkeyf.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-turkeyq.fth
fload ${BP}/pkg/keyboard/tables/usb/usb-uk.fth
fload ${BP}/pkg/keyboard/tables/usb/aliases.fth

all-done


