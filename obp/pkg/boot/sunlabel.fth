\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sunlabel.fth
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
id: @(#)sunlabel.fth 2.24 97/01/28
purpose: Sun disk label (disk-label) package
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ Sun Label package.  Runs on top of a disk device, dividing that disk
\ into logical partitions as described in a "label" stored in the first
\ 512-byte block.  Implements the "load" operation by reading a 7.5 Kbyte
\ "bootblk" starting 512 bytes from the beginning of a partition.
\
\ The complete contents of the label block is described in
\ /usr/include/sun/dklabel.h

" /packages" find-device
new-device
" disk-label" device-name
headerless

d# 512 constant ublock		\ Logical block size.  Also size of label.
ublock d# 15 *  constant /bootblk \ Size of "bootblk" code stored after label

0 instance value dklabel	\ Label buffer; used temporarily during open
instance variable partition#
instance variable dkl_ncyl	\ # of data cylinders
instance variable dkl_acyl	\ # of alternate cylinders
instance variable dkl_nhead	\ # of heads
instance variable dkl_nsect	\ # of sectors per track

: label@  ( offset -- short )  dklabel + w@  ;

: label-valid?  ( -- flag )
   d# 508 label@  h# dabe <>  if
      ." Bad magic number in disk label" cr  false exit
   then

   0   dklabel  ublock  bounds  ?do  i w@ xor  /w +loop  ( checksum )

   0<>  if  ." Bad checksum in disk label" cr  false exit  then

   true
;

: set-start-block  ( partition# -- error?? )
   8 *  d# 444 dklabel +  +  unaligned-l@    ( start-cyl )
   d# 436 label@  ( .. #heads )  *           ( start-trk )
   d# 438 label@  ( .. sectors/trk )  *      ( start-block )
   ublock *                                  ( byte-offset )
   partition# !
   d# 432 label@ dkl_ncyl !
   d# 434 label@ dkl_acyl !
   d# 436 label@ dkl_nhead !
   d# 438 label@ dkl_nsect !
;
: get-dkl-info  ( -- ncyl acyl nhead nsect )
   dkl_ncyl @
   dkl_acyl @
   dkl_nhead @
   dkl_nsect @
;

headers
: read   ( len buf -- actual-len )  " read"  $call-parent  ;
: write  ( len buf -- actual-len )  " write" $call-parent  ;
: seek   ( offset-low offset-high -- okay? )  " seek" $call-parent  ;

: offset  ( offset-low offset-high -- offset-low' offset-high' )
   partition# @ 0  d+           ( low high )  \ Add start of partition
;
headerless
: open-part  ( file$ part$ -- file$ okay? )
   \ The "nolabel" partition maps the entire disk, and does not look at the label
   2dup  " nolabel"  $=  if  2drop true exit  then

   \ Accept partition letters a, b, c, ... or A, B, C, ...
   if							( file$ adr )
      c@ upc ascii A -					( file$ part# )
   else
      \ No partition specified : default to "a"
      \ Rewrite "my-args" and insert the partition label.
      drop dup  if					( file$ )
         \ File argument--need to allocate space for that
         dup 2+ ( <part><,><file$> ) dup alloc-mem	( file$ len adr )
         ascii a over c!  ascii , over 1+ c!		( file$ len adr )
         2over 2 pick 2+ swap  move  swap		( file$ adr len )
      else
         ascii a  1 alloc-mem tuck c!  1		( file$ adr len )
      then
      my-parent package(  to my-args-len to my-args-adr  )package
      0
   then							( file$ part# )

   \ Initially set partition to 0 so that we can
   \ read the label which is in the first partition
   0 partition# !					( file$ part# )

   ublock alloc-mem is dklabel				( file$ part# )
   dklabel 0=  if					( file$ part# )
      ." Can't allocate memory for disk label"		( file$ part# )
      drop false exit					( file$ false )
   then							( file$ part# )

   0 0 seek drop					( file$ part# )
   dklabel  ublock  read  ublock <>  if			( file$ part# )
      ." Can't read disk label." cr  drop false		( file$ false )
   else							( file$ part# )
      set-start-block  label-valid?			( file$ okay? )
   then							( file$ okay? )

   dklabel ublock free-mem				( file$ okay? )
;

headers
: open  ( -- okay? )
   \ Arg string is <part>[,<filespec>]
   \ Split off partition, and handle via open-part
   my-args  ascii , left-parse-string			( file$ part$ )

   open-part 0=  if  2drop  false exit  then		( file$ )

   ?dup  if
      " ufs-file-system" find-package  if
	interpose
      else
        2drop false exit
      then
   else
      drop
   then
   true
;


: close  ( -- )  ;	\ Nothing to do, since we only use 1 cell of data

: load  ( adr -- size )		\ Pass in load-base
   ublock 0 seek  drop		( adr )  \ Should check for errors
   ublock d# 15 *  tuck         ( len adr len )
   read                         ( len actual-len )
   tuck <>  if  ." Short disk read" cr   then  ( actual-len )
;

: size ( -- d.size )  /bootblk s>d  ;
headers
finish-device
device-end

