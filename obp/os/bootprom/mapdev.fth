\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mapdev.fth
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
id: @(#)mapdev.fth 2.15 00/08/30
purpose:
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

\ Map the "reg" property of the named device.

headerless
: get-#addr-cells ( -- n )
   2 my-parent ?dup if					( 2 ihandle )
      my-self -rot to my-self				( my-self 2 )
      " #address-cells" get-inherited-property 0= if	( my-self 2 )
         get-encoded-int nip				( my-self n )
      then						( my-self n )
      swap to my-self  					( n )
   then							( n )
;

: num-decoded-cells ( -- n ) get-#addr-cells  parent-#size-cells +  ;

: map-reg ( reg$ -- reg$' virt )
   parent-#size-cells 0= throw			( reg$ )
   num-decoded-cells  decode-ints		( xdr,len <size> <addr> )
   parent-#size-cells 0 ?do			( xdr,len <addr> <??> )
       num-decoded-cells 1- roll		( xdr,len <addr> <??> )
   loop						( xdr,len <addr> <size> )
   parent-#size-cells ?dup if			( xdr,len <addr> size.lo )
      1- 0 ?do drop loop			( xdr,len <addr> size.lo )
   then						( xdr,len <addr> size.lo )
   1 max " map-in"  $call-parent		( reg$' virt )
   dup 0=  throw                                ( reg$' virt )
;

: (map-device)  ( -- vaddr )
   " reg" get-my-property  throw            ( reg$ )

   map-reg  -rot                            ( virt reg$' )

   2 pick  encode-int 2swap                 ( virt encode-virt$ reg$ )

   begin  dup  while                        ( virt encode-virt$ reg$ )
      map-reg                               ( virt encode-virt$ reg$' virt' )
      >r 2swap r> encode-int encode+ 2swap  ( virt encode-virt$' reg$' )
   repeat                                   ( virt encode-virt$ reg$ )

   2drop                                    ( virt encode-virt$ )
   " address" property                      ( virt )
;

headers

: map-device  ( dev-adr,len -- vaddr | 0 )
   begin-select-dev                             ( )
   ['] (map-device)  catch  if  ." Can't map device " pwd cr  0  then
   end-select-dev
;
