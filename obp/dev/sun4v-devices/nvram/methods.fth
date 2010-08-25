\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: methods.fth
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
id: @(#)methods.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

h#    0           constant  fixbase
h#   40           constant  fixsize
fixbase fixsize + constant  nvbase
h# 16c0           constant  nvsize

nvbase nvsize +  constant  keystore-base
h# 100           constant  keystore-size

h#    0           constant  rawbase
h# 2000           constant  rawsize

0  instance 	value basepos		\ Absolute offset of this partition 
0  instance 	value filepos		\ Current position in partition
0  instance 	value psize		\ Partition size

: clip-range ( len -- len' )  psize filepos - min  ;
: bump-pos   ( n -- )         filepos + psize min to filepos  ;
: range-bad? ( offset -- offset flag )  dup 0 psize within  invert  ;

struct
   /w field >offset
   /c field >command
   /c field >send-size
constant /send-hdr

struct
   /c field >status
   /c field >reply-size
constant /reply-hdr

d# 32 constant blocksize

: setup-pkt ( len cmd -- tx-bytes )
   dup >r outbuf >command c!			( len )
   basepos filepos + outbuf >offset w!		( )
   blocksize min dup outbuf >send-size c!	( len' )
   r> 0= if drop 0 then /send-hdr +		( tx-bytes )
;

: recv ( -- len )
   recv if
      inbuf >status c@ if
         0
      else
         inbuf >reply-size c@ dup filepos + is filepos
      then
   else
      0
   then
;

: poll ( acf -- )
   >r d# 100 begin r@ execute 0= over 0<> and while 1 - 10 ms repeat
   r> drop 0= if
      cmn-error[ " NVRAM transfer timed out." ]cmn-end -1 throw
   then
;

: (read) ( adr len -- actual-len )
   0 setup-pkt	   					( adr bytes )
   ['] send? poll send					( adr )
   ['] recv? poll recv ?dup if				( adr len )
      tuck inbuf /reply-hdr + -rot move 		( len true )
   else							( adr )
      drop 0 						( 0 )
   then
;

: (write) ( adr len -- actual-len )
   1 setup-pkt			   			( adr bytes )
   swap outbuf /send-hdr + outbuf >send-size c@ move	( bytes )
   ['] send? poll send					( )
   ['] recv? poll recv					( len )
;

0 instance value action

: xfer ( buf len acf -- len )
   is action
   clip-range
   0 -rot begin						( bytes buf len )
      ?dup while					( bytes buf len )
      2dup blocksize min 				( bytes buf len buf n )
      action catch if					( bytes buf len buf n )
         3drop 0					( bytes buf 0 )
      else						( bytes buf len n )
         tuck - >r					( bytes buf n )
	 tuck + >r					( bytes n )
	 + r> r>					( bytes buf' len' )
      then						( bytes buf' len' )
   repeat drop						( bytes )
;

: $=  ( adr,len adr2,len -- same? )
   rot tuck <> if  3drop false exit  then  comp 0=
;  

external

: read ( buf len -- len' ) ['] (read) xfer  ;

: write ( buf len -- len' ) ['] (write) xfer ;

: open ( -- true )
   nvbase nvsize
   my-args " keys"  $= if 2drop keystore-base keystore-size then 
   my-args " fixed" $= if 2drop fixbase fixsize then
   my-args " raw"   $= if 2drop rawbase rawsize then
   to psize  to basepos				( )
   0 to filepos					( )
   1 /send-hdr blocksize + init-svc
   true
;

: close ( -- ) finish-svc ;

: seek ( lo hi -- error )
   drop	 dup 0<	 if  psize +  then
   range-bad? tuck if  drop  else  to filepos  then	( fail? )
;

: size ( -- n )  psize filepos - ;

: sync  ( -- )  ;

headers
