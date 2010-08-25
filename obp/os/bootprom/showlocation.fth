\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: showlocation.fth
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
id: @(#)showlocation.fth 1.1 01/10/12
purpose: show-fru-location command
copyright: Copyright 2001 Sun Microsystems, Inc.  All Rights Reserved

headerless

: (.location) ( -- )
   " sunw,location" get-property  0=  if	( encoded-str,len) 
      get-encoded-string 2dup " ." $=  if	( prop-str,len)		
         2drop ." /" .node-name			( )
      else					( prop-str,len)
         over c@ ascii / <>  if  ." /"  then	( prop-str,len)  
         type					( )
      then  
   then  
;

: ?terminate ( -- flag )
   " sunw,location" get-property 0=  if		( encoded-str,len) 
      get-encoded-string drop c@ ascii / =	( flag)  
   else							
      false					( false)
   then						( flag) 
;     

: .location  ( -- )  recursive
   root-device? ?terminate or 0=  if			( )
      current-device pop-device .location push-device	( )
   then							( )
   (.location) 
;

headers

\ The command is specified by fwarc cases 2001/327 and 2001/353.
\ This implementation is based on "sunw,location" property.
\ The command takes a device-specifier and prints the
\ location path corresponding to the device specifier 
\ according to the informative algorithm described in 2001/353.

: show-fru-location  ( -- )
   optional-arg$ ?dup  if			( dev-path,len) 
      locate-device  if  ." ?" cr exit  then	( )
   else						( phandle )
      drop ." Usage: show-fru-location <device-specifier>" cr exit 
   then 					( phandle )
   also push-device .location previous definitions 
   #out @ 0=  if ." ?" then  cr 
;
