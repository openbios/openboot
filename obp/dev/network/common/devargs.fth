\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: devargs.fth
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
id: @(#) devargs.fth 1.2 03/08/23
purpose: Process device arguments.
copyright: Copyright 2001-2003 Sun Microsystems, Inc. All Rights Reserved.
copyright: Use is subject to license terms.

headerless

: $=  ( adr1 len1 adr2 len2 -- same? )
   rot tuck  <>  if  3drop false exit  then   ( adr1 adr2 len1 )
   comp 0=
;

: device-argument? ( arg$ -- flag )
   ascii = left-parse-string  2swap 2drop  	( key$ )
   2dup " speed"       $=  -rot
   2dup " duplex"      $=  -rot
   2dup " link-clock"  $=  -rot
   2dup " promiscuous" $=  -rot
   2drop  or or or				( flag )
;

: set-device-parameter ( arg$ -- )
   2dup " speed=10"          $=  if  2drop speed=10          exit  then
   2dup " speed=100"         $=  if  2drop speed=100         exit  then
   2dup " speed=1000"        $=  if  2drop speed=1000        exit  then
   2dup " speed=auto"        $=  if  2drop speed=auto        exit  then
   2dup " duplex=half"       $=  if  2drop duplex=half       exit  then
   2dup " duplex=full"       $=  if  2drop duplex=full       exit  then
   2dup " duplex=auto"       $=  if  2drop duplex=auto       exit  then
   2dup " link-clock=master" $=  if  2drop link-clock=master exit  then
   2dup " link-clock=slave"  $=  if  2drop link-clock=slave  exit  then
   2dup " link-clock=auto"   $=  if  2drop link-clock=auto   exit  then
   2dup " promiscuous"       $=  if  2drop mode=promiscuous  exit  then
   type ."  not supported" cr
;

: parse-devargs ( args$ -- obptftp-args$ )
   begin
      2dup  ascii , left-parse-string  2dup device-argument?  if
         set-device-parameter  2swap 2drop
      else
         2drop 2drop exit
      then
   again
;

: publish-properties ( -- )
   user-speed  case
      auto-speed  of  " auto"  endof
      10Mbps      of  " 10"    endof
      100Mbps     of  " 100"   endof
      1000Mbps    of  " 1000"  endof
   endcase  encode-string " speed" property

   user-duplex  case
      auto-duplex  of  " auto"  endof
      half-duplex  of  " half"  endof
      full-duplex  of  " full"  endof
   endcase  encode-string " duplex" property

   gmii-phy?  if
      user-link-clock  case
         auto-link-clock    of  " auto"  endof
         master-link-clock  of  " master"  endof
         slave-link-clock   of  " slave"  endof
      endcase  encode-string " link-clock" property
   then
;

headers
