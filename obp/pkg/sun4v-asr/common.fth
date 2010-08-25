\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
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
id: @(#)common.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

: unaligned-w@ ( adr -- val )  dup c@ swap 1+ c@ swap bwjoin  ;

struct
   /w field >send-size
   /c field >command
constant /send-hdr

struct
   /w field >reply-size
   /c field >status
constant /reply-hdr

\ 512 max mtu minus 8 byte queue ptk minus header
h# 200 8 - /send-hdr - constant blocksize

: setup-pkt ( len cmd -- tx-bytes )
   outbuf >command c!				( len )
   blocksize min dup outbuf >send-size w!	( len' )
   /send-hdr +					( tx-bytes )
;

: poll ( acf -- )
   >r d# 100 begin r@ execute 0= over 0<> and while 1 - 10 ms repeat
   r> drop 0= if
      cmn-error[ " ASR transfer timed out" ]cmn-end
      -1 throw
   then
;

: svc-enable ( adr len -- status )
   enable-cmd setup-pkt					( adr bytes )
   swap outbuf /send-hdr +				( bytes adr dest )
   outbuf >send-size unaligned-w@ move			( bytes )
   ['] send? poll send					( )
   ['] recv? poll recv if				( )
      inbuf >status c@ 			 		( status )
   else							( )
      asr-rx-error throw				( err )
   then
;

: svc-disable ( adr len -- status )
   disable-cmd setup-pkt				( adr bytes )
   swap outbuf /send-hdr +				( bytes adr dest )
   outbuf >send-size unaligned-w@ move			( bytes )
   ['] send? poll send					( )
   ['] recv? poll recv if				( )
      inbuf >status c@ 			 		( status )
   else							( )
      asr-rx-error throw				( err )
   then
;

: svc-state ( adr -- buflen|0 status )
   0 state-cmd setup-pkt				( adr bytes )
   ['] send? poll send					( adr )
   ['] recv? poll recv if				( adr )
      inbuf >status c@ ?dup if		 		( adr status )
         nip 0 swap 					( 0 status )
      else						( adr )
         inbuf /reply-hdr + swap			( state adr )
         inbuf >reply-size unaligned-w@ dup >r move	( len status )
         r> asr-cmd-ok					( len status )
      then						( len status )
   else							( adr )
      drop asr-rx-error throw				( err )
   then
;

: svc-statelen ( -- len|0 status )
   0 statelen-cmd setup-pkt				( bytes )
   ['] send? poll send					( )
   ['] recv? poll recv if				( )
      inbuf >status c@ ?dup if		 		( status )
         0 swap 					( 0 status )
      else						( )
         inbuf /reply-hdr + unaligned-w@ asr-cmd-ok	( len status )
      then						( len status )
   else							( )
      asr-rx-error throw				( err )
   then
;

: svc-query ( buf len -- flags )
   query-cmd setup-pkt					( adr bytes )
   swap outbuf /send-hdr +				( bytes adr dest )
   outbuf >send-size unaligned-w@ move			( bytes )
   ['] send? poll send					( )
   ['] recv? poll recv if				( )
      inbuf >status c@ ?dup if		 		( error )
         throw						( error )
      else						( )
         inbuf /reply-hdr + c@				( flags )
      then						( flags )
   else							( )
      asr-rx-error throw				( error )
   then
;

0 value svc-opened?

: svc-open ( -- )
   svc-opened? if exit then
   asr-sid /send-hdr blocksize + init-svc
   -1 to svc-opened?
;

: svc-close finish-svc ;
