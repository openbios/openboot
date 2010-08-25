\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: bootparm.fth
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
id: @(#)bootparm.fth 3.39 06/04/25
purpose: Implements the boot command - parses arguments, etc.
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved.
copyright: Use is subject to license terms.

\ Forth support for the booting process

\ Booting entries:
\ a) User types  "boot ....."
\ b) The client program invokes the "reboot" client interface service
\
\ We need a flag indicating whether or not to reset the machine.
\

headers

headerless
true	value		init-incomplete? \ TRUE until probe/init complete
defer config-load-base ' load-base to config-load-base
headers
default-load-base value load-base
warning @ warning off
\ duplicate definition in fm/kernel/readline.fth
variable file-size
warning !
headerless
: init-load-base ( -- )  config-load-base to load-base  ;

headers
d# 256 buffer: path-buf   ' path-buf  " bootpath" chosen-string
d# 128 buffer: args-buf   ' args-buf  " bootargs" chosen-string
headerless

\ test the status property of the device ihandle passed in.
\ if status property does not exist, it is assumed to be "okay"
\ if status property exists, and is "okay", return true.
\ if status property exists and is not "okay", return false.

: device-status-ok? ( phandle -- flag )
   " status" rot get-package-property 0= if     \ if property exists
      decode-string 2swap 2drop                 ( str len )
      " okay" $= 0= if                          \ status property is not "okay"
         false exit                             ( flag )
      then                                      \ status property is "okay"
   then                                         ( )
   true                                         ( flag )
;

\ A defer word is used in case a platform wants to take some
\ action (like updating signature) after certain boot failures.

\ Hook executed if there is trouble accessing the device
defer boot-read-fail-hook   ( -- ) ' noop is boot-read-fail-hook

\ Hook executed if device node for specified path is not found
defer boot-locate-fail-hook ( -- )

\ Platforms may handle boot-locate-fail-hook in the same way as
\ boot-read-fail-hook. This is the default behaviour assigned to
\ boot-locate-fail-hook. Other platforms can assign platform specific
\ action to boot-locate-fail-hook in platform specific code.
' boot-read-fail-hook is boot-locate-fail-hook

\ Hook executed at the entry of boot-read
defer boot-read-hook        ( -- ) ' noop is boot-read-hook

\ Hook executed if the device specified in default device list
\ (boot-device or diag-device) cannot be opened for operation
defer default-device-hook   ( -- ) ' noop is default-device-hook

: boot-read  ( adr len -- )
   boot-read-hook                               ( adr len )
   2dup locate-device                           ( adr,len phandle false | adr,len true )
   if                                           ( adr,len phandle | adr,len )
      boot-locate-fail-hook                     ( adr,len )
      true abort" "r"nCan't locate boot device"r"n"
   then                                         ( adr,len phandle )
   device-status-ok? 0=                         ( adr,len flag )
   if                                           ( adr,len )
      boot-read-fail-hook                        ( adr,len )
      true abort" "r"nCan't boot from device: 'status' property NOT ""okay"""r"n"
   then                                         ( adr,len )
   open-dev  ( fileid | 0 )  ?dup  0=  if
      boot-read-fail-hook
      ( print-probe-list )
      true abort" "r"nCan't open boot device"r"n"
   then                                         ( fileid )
   true to already-go?
   dup ihandle>devname path-buf place-cstr drop ( fileid )

   >r                                           ( )
   file-size off  load-base                     ( load-adr )
   " load" r@  ['] $call-method  catch  if      ( load-adr adr len fid )
      boot-read-fail-hook                       ( load-adr adr len fid )
      2drop 2drop  r> close-dev                 ( )
      true abort" "r"nBoot load failed"r"n"     ( )
   then                                         ( file-size )
   file-size !                                  ( )
   r> close-dev                                 ( )
;

: default-device  ( -- $devname )
[ifndef] SUN4V
   diagnostic-mode?  if  diag-device  else  boot-device  then
[else]
   boot-device
[then]

   strip-blanks                       ( devnames$ )
   begin                              ( devnames$ )
      bl left-parse-string            ( right$ left$ )
      2swap strip-blanks  dup >r      ( left$ right$ ) ( r: right-len )
      2swap strip-blanks              ( right$ left$ )
      r>                              ( right$ left$ right-len )
   while                              ( right$ left$ )
      2dup locate-device 0= if        ( right$ left$ phandle )
         device-status-ok? if         ( right$ left$ )
            2dup open-dev ?dup  if    ( right$ left$ ihandle )
               close-dev 2swap 2drop exit ( left$ )
            else
	       default-device-hook    ( right$ left$ )
            then                      ( right$ left$ )
         then                         ( right$ left$ )
      then                            ( right$ left$ )
      2drop                           ( right$ )
   repeat                             ( right$ )
   2swap 2drop                        ( devname$ )
   strip-blanks                       ( devname$ )
;
: default-file  ( -- file&args$ )
[ifndef] SUN4V
   diagnostic-mode?  if  diag-file  else  boot-file  then
[else]
   boot-file
[then]
   strip-blanks
;

\ Gets the boot command line, either user-specified or default.
: parse-boot-command  ( cmd-str -- file-str device-str )
   -leading            \ Skip leading blanks   ( cmd-str )

   ?dup 0=  if
      \ Whole thing is null; use default file and default device
      drop  default-file  default-device  exit
   then					( cmd-str )

   2dup  bl left-parse-string           ( cmd-str rem-str 1st-str )

   \ We know that 1st-str is not null because we have already checked
   \ for the entire string = null

   over c@  ascii /  =  if              ( cmd-str rem-str 1st-str )
      \ Explicit pathname in first word; use it as the device and the
      \ rest of the command line as the file
      2rot 2drop                        ( file-str device-str )
   else                                 ( cmd-str rem-str 1st-str )
      aliased?  if                      ( cmd-str rem-str alias$ )
         \ First word is alias; expand it as the device and use the
	 \ rest of the command line as the file.
         2rot 2drop                     ( file-str device-str )
      else                              ( cmd-str rem-str 1st-str )
         \ First word is neither a path nor an alias; use the default
	 \ device as the device and the entire command line as the file.
         2drop 2drop                    ( file-str )
         default-device  ?expand-alias  ( file-str device-str )
      then
   then                                 ( file-str device-str )

   2 pick  0=  if
      \ No file name given; use the default file instead
      2swap 2drop  default-file 2swap
   then                                 ( file-str device-str )

   2swap -leading  2swap -leading       ( file-str device-str )
;


headerless
create boot-file-not-found ," The attempt to a load a boot image failed."

headerless
\ Loads the file specified by the boot command line string at adr,len
: $boot-read  ( cmd-str -- )
   parse-boot-command                         ( file-str device-str )

   min+mode? if                               ( file-str device-str )
      ." Boot device: "  2dup type            ( file-str device-str )
      ."   File and args: " 2over type cr     ( file-str device-str )
   then

   2swap args-buf  place-cstr drop	      ( device-str )

   boot-read                                  ( )
;

: boot-getline  \ command line  ( -- adr len )
   -1 parse  -trailing  ( adr len )
;

: $append  ( adr len buf -- )
   \ Insert a space to separate the strings if both are non-empty
   >r dup 0<>					( adr len 0? )
   r@  c@ 0<> and  if  "  " r@ $cat  then	( adr len )
   r>  $cat					( sdr len )
;

\ $restart never returns to its caller.  It resets the machine, leaving
\ hints in a system-dependent "safe" location so that the system will reboot
\ itself with the specified string.

: $restart  ( tail$ mid$ head$ -- )
   "temp >r				( tail$ mid$ head$ )
   r@ place				( mid$ tail$ )
   r@ $append				( mid$ )
   r@ $append				( -- )
   r> count				( adr len )

   stdout-line# stdout-column#
   save-reboot-info                         (  )
   reset-all
;

\ The defer word can be used by platforms to take some action
\ such as updating the domain signature.
defer $reboot-hook ( -- ) ' noop is $reboot-hook 
: $reboot  ( arg$ dev$ -- )  $reboot-hook " boot"  $restart  ;

: reboot-same  ( -- )  args-buf cscount  path-buf cscount  $reboot  ;

: ?boot-password  ( adr len -- adr len )
   ?secure  security-mode  case                  ( adr len )
      1  of  dup 0<>    endof   \ Need password only for non-default boot
      2  of  true       endof   \ Always need password
      ( default ) false  swap   \ Don't need password
   endcase                                       ( adr len password-needed? )
   if  password-okay?  0=  if  quit  then  then  ( adr len )
;

\ The defer word can be used by platforms to take some action
\ such as updating the domain signature.
defer $boot-load-hook  ( -- )  ' noop is $boot-load-hook
: $boot-load  ( cmd-str -- )
   ?boot-password                     ( cmd-str )
   state-valid off  restartable? off  ( cmd-str )
   cleanup                            ( cmd-str )
   $boot-load-hook
   init-load-base $boot-read          (  )
;

create not-executable ," The file just loaded does not appear to be executable."

headers
: $load  ( adr len -- )
   already-go? if  null$ $reboot  then  $boot-load
;
: ?go  ( -- )
   ?secure  restartable? @  if  go exit  then
   load-base  file-size @ ?dup  if  'execute-buffer  execute  else  drop  then
;

\ Defer words are used in case a platform wants to take some action
\ (like updating signature) at certain points in the boot process.
defer $boot-hook  ( -- )  ' noop is $boot-hook
defer $boot-failed-hook  ( -- )  ' noop is $boot-failed-hook
: $boot ( adr,len -- )
   $load $boot-hook ?go $boot-failed-hook not-executable throw
;

\ Reads the first level boot file, but doesn't jump to it.
: load  \ boot-spec  ( -- )
   boot-getline  $boot-load
;

headerless
: (bootable?) ( comment$ -- )
   init-incomplete? if			\ Did probe/init run to completion?
      cmn-fatal[
      " OpenBoot initialization sequence prematurely terminated."
      ]cmn-end				\ Tell user bad news
      false to init-incomplete?		\ Only issue this message once
   then
   system-fatal-state? if
      " FATAL: system is not bootable" "temp >r r@ pack ( pstr )
      $cat  r> count set-abort-message			( )
      -2 throw						( )
   else
      2drop
   then
;
headers

\ Reads and executes the first level boot file; executed by the user
: boot  \ boot-spec  ( -- )
   " , boot command is disabled" (bootable?)
   boot-getline  $boot
;

warning @ warning off
alias go ?go
warning !

headerless

: safe-evaluate  ( adr len -- )
   ['] evaluate  catch  ?dup  if  nip nip .error  then
;
: do-auto-boot ( -- )
   auto-boot?  if
      " , auto-boot is disabled" (bootable?)
      interrupt-auto-boot? if
         ." Aborting auto-boot sequence." cr
      else
         boot-command  safe-evaluate             \ Go ahead and try to auto-boot
      then
   then
;

\ do-reboot attempts to boot using the parameters that were saved in 
\ reboot info area
: do-reboot ( -- )
   " , reboot is disabled" (bootable?)

   get-reboot-info    ( bootcmd$ line# column# )

   \  Cursor position is restored in fwritestr.fth
   2drop                                    ( bootcmd$ )

   min+mode? if                             ( bootcmd$ )
      ." Rebooting with command: " 2dup type cr  ( bootcmd$ )
   then                                     ( bootcmd$ )

   safe-evaluate  exit
;

\ if auto-boot executes after a reset resulting from a reboot, do-reboot
\ is executed, otherwise, do-auto-boot is executed.
: auto-boot  ( -- )
   reboot? if
      do-reboot			(  )
   else
      " boot-" do-drop-in	(  )
      do-auto-boot		(  )
      " boot+" do-drop-in	(  )
   then
;

headers
cif: boot     ( cstr -- )  cscount  null$ reclaim-machine $reboot  ;
cif: restart  ( cstr -- )  cscount  null$ null$  reclaim-machine $restart  ;
