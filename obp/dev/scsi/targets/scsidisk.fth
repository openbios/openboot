\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: scsidisk.fth
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
id: @(#)scsidisk.fth 1.9 06/04/21
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ SCSI disk package implementing a "block" device-type interface.

" block"     device-type

fload ${BP}/dev/scsi/targets/scsicom.fth	\ Utility routines

hex

\ 0 means no timeout
: set-timeout  ( msecs -- )  " set-timeout" $call-parent  ;

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;


\ Ensures that the disk is spinning, but doesn't wait forever

create sstart-cmd  h# 1b c, 1 c, 0 c, 0 c, 1 c, 0 c,

headers

: timed-spin  ( up? -- error? )
   d# 15000 set-timeout				( up? )
   sstart-cmd 4 + c!				( )
   0 0 true  sstart-cmd 6  d# 60 retry-command  if  ( true | sensebuf false )
      \ true on top of the stack indicates a hardware error.
      \ We don't treat "illegal request" as an error because some drives
      \ don't support the start command.  Everything else other than
      \ success is considered an error.
      if  true  else  2+ c@ 5 <>  then           ( error? )
   else                                          ( )
      false                                      ( false )
   then                                          ( error? )

   0 set-timeout
;

headerless

0 instance value /block         \ Device native block size

create mode-sense-bd          h# 1a c, 0 c, 0 c, 0 c, d# 12 c, 0 c,
create read-capacity-cmd h# 25 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,

: read-block-extent  ( -- true | block-size #blocks false )
   \ First try "read capacity" - data returned in bytes 4,5,6,7
   \ The SCSI-2 standard requires disk devices to implement
   \ the "read capacity" command.

   8  read-capacity-cmd 0a  short-data-command  0=  if
       dup 4 + 4c@  swap 4c@  1+ false  exit
   then

   \ Failing that, try "mode sense" with an allocation length big enough only
   \ for the header and the block descriptor

   d# 12  mode-sense-bd 6  short-data-command  0=  if
       dup 9 + 3c@  swap 4 + 4c@  false  exit
   then

   true
;
: read-block-size  ( -- n )     \ Ask device about its block size
   read-block-extent  if  d# 512  else  drop  then
;

headers

[ifdef] report-geometry
create mode-sense-geometry    h# 1a c, 0 c, 4 c, 0 c, d# 36 c, 0 c,

\ The sector/track value reported below is an average, because modern SCSI
\ disks often have variable geometry - fewer sectors on the inner cylinders
\ and spare sectors and tracks located at various places on the disk.
\ If you multiply the sectors/track number obtained from the format info
\ mode sense code page by the heads and cylinders obtained from the geometry
\ page, the number of blocks thus calculated usually exceeds the number of
\ logical blocks reported in the mode sense block descriptor, often by a
\ factor of about 25%.

\ Return true for error, otherwise disk geometry and false
: geometry  ( -- true | sectors/track #heads #cylinders false )
   d# 36  mode-sense-geometry  6  short-data-command  if  true exit  then  >r
   r@ d# 17 + c@   r@ d# 14 + 3c@   ( heads cylinders )
   2dup *  r> d# 4 + 4c@            ( heads cylinders heads*cylinders #blocks )
   swap /  -rot                     ( sectors/track heads cylinders )
   false
;
[then]

external

: #blocks  ( -- true | n false )
   read-block-extent  if  true  else  nip  then
;

\ Return device block size; cache it the first time we find the information
\ This method is called by the deblocker
: block-size  ( -- n )
   /block  if  /block exit  then        \ Don't ask if we already know

   read-block-size dup to /block
;

headers

\ Read or write "#blks" blocks starting at "block#" into memory at "addr"
\ Input? is true for reading or false for writing.
\ command is  8  for reading or  h# a  for writing
\ We use the 6-byte forms of the disk read and write commands where possible.

: 2c!  ( n addr -- )  >r lbsplit 2drop  r> +c!         c!  ;
: 4c!  ( n addr -- )  >r lbsplit        r> +c! +c! +c! c!  ;

: r/w-blocks  ( addr block# #blks input? command -- actual# )
   cmdbuf d# 10 erase                             ( addr block# #blks dir cmd )
[ifndef] FORCE-READ10?
   2over  h# 100 u>  swap h# 200000 u>=  or  if   ( addr block# #blks dir cmd )
[then]
      \ Use 10-byte form
      h# 20 or  0 cb!  \ 28 (read) or 2a (write)  ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 2 + 4c!                              ( addr dir #blks )
      dup cmdbuf 7 + 2c!                          ( addr dir #blks )
      d# 10                                       ( addr dir #blks cmdlen )
[ifndef] FORCE-READ10?
   else                                           ( addr block# #blks dir cmd )
      \ Use 6-byte form
      0 cb!                                       ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 1+ 3c!                               ( addr dir #blks )
      dup 4 cb!                                   ( addr dir #blks )
      6                                           ( addr dir #blks cmdlen )
   then
[then]
   swap                                           ( addr dir cmdlen #blks )
   dup >r                                         ( addr input? cmdlen #blks )
   /block *  -rot  cmdbuf swap  -1  ( addr #bytes input? cmd cmdlen #retries )
   retry-command  if                              ( [ sensebuf ] hw? )
      0= if  drop  then  r> drop 0
   else
      r>
   then    ( actual# )
;

: set-address ( -- )  my-unit " set-address" $call-parent  ;

headers

: device-present? ( -- condition )
   my-unit " device-present?" $call-parent
;

headerless
create eject-cmd  h# 1b c, 1 c, 0 c, 0 c, 2 c, 0 c,

external
: eject ( -- )
   set-address  device-present? if
      eject-cmd no-data-command  drop
   then
;

\ These three methods are called by the deblocker.

: max-transfer  ( -- n )   parent-max-transfer  ;
: read-blocks   ( addr block# #blocks -- #read )     true  d# 8  r/w-blocks  ;
: write-blocks  ( addr block# #blocks -- #written )  false d# 10 r/w-blocks  ;

\ Methods used by external clients

\ Spun down devices and empty CDROMs return condition 2
\ so we will attempt to spin up the device and then check its
\ condition again.

: retry-device? ( condition -- condition' )
   dup 2 = if
      drop 1 timed-spin if
         device-present?
      else
         true
      then
   then
;

external

: open  ( -- flag )

   set-address  device-present?  retry-device?
   case
      0 of  true  endof		\ missing so bail
      2 of  true  endof		\ Check Condition.. bail
      false swap		\ Everything else looks cool.
   endcase
   if  false exit  then

   block-size to /block

   init-deblocker  0=  if  false exit  then

   init-label-package  0=  if
      deblocker close-package false exit
   then
   true
;

: close  ( -- )
   label-package close-package
   deblocker close-package
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: size  ( -- d.size )  " size" label-package $call-method  ;
headers
