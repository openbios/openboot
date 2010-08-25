\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: inet.fth
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
id: @(#)inet.fth 1.1 04/09/07
purpose: IPV4 address manipulation functions
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: decimal-byte? ( adr,len -- byte true | false )
   $dnumber 0=  dup  if
      over  0 d# 255 between 0=  if  2drop false  then
   then
;

\ Interpret IPV4 dotted-decimal string and return IP address as a number.
: inet-addr ( ip$ -- ip# false | true )
   0 /ip-addr 0  do					( $ n )
      >r						( $ ) ( r: n )
      ascii . left-parse-string decimal-byte? 0=  if	( $' )
         2drop r> drop true unloop exit
      then						( $' byte )
      r> d# 8 lshift or					( $' n' ) ( r: )
   loop							( $' n' )
   over if  3drop true  else  nip nip false  then	( ip# false | true )
;

\ Convert network byte ordered IPV4 address to its string representation,
\ returning a pointer to the dotted-decimal string.
: inet-ntoa ( ipaddr -- str len )
   base @ >r  decimal
   <# 1 /ip-addr 1- do dup i ca+ c@ u#s ascii . hold drop -1 +loop c@ u#s u#>
   r> base !
;

\ Convert IPV4 dotted-decimal string to its numeric form. The 'adr'
\ argument points to a buffer where the numeric address is stored.
\ Return true on successful conversion; false otherwise.
: inet-aton ( ip$ adr -- ok? )
   /ip-addr bounds do
      ascii . left-parse-string decimal-byte? 0=  if
         2drop false unloop exit
      then  i c!
   loop  0= nip 
;

headers
