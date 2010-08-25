\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: devpaths.fth
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
id: @(#)devpaths.fth 1.2 02/08/20
purpose: extract paths from device tree
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

: (append-unit) ( phys.. str,len -- )
   " @" 2swap $add 2>r				( )
   current-device >r r@ >parent push-device	( )
   (encode-unit)				( str,len )
   r> push-device				( str,len )
   2r> $add 					( str',len' )
;

: (append-name) ( str,len -- str,len' )
   "name" get-property  if			( str,len )
      " <Unnamed>"				( str,len prop,len )
   else						( str,len prop,len )
      get-encoded-string			( str,len prop,len )
   then 2swap $add 				( str,len' )
;

: (append-name+unit) ( str,len -- str,len' )
   (append-name)				( str,len' )
   get-unit 0= if				( str,len' prop,len )
      2swap 2>r					( prop,len )
      unit-str>phys 2r> (append-unit)		( str,len )
   then						( str,len )
;

: root-device?  ( -- flag )  current-device >parent null =  ;

: (pwd)  ( str,len -- str,len )  recursive
   root-device? 0=  if				( str,len )
      current-device >r  pop-device (pwd)  r> push-device
      " /" 2swap $add (append-name+unit)	( str,len )
   then						( str,len )
;

\ adr len is the full path string.
: pwd$  ( -- adr len )
   root-device?  if				( )
      " /"					( str,len )
   else						( )
      "temp 0 (pwd)				( str,len )
   then						( str,len )
;
