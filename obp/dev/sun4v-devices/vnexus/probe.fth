\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probe.fth
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
id: @(#)probe.fth 1.2 06/05/22
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

fload ${BP}/dev/sun4v-devices/utilities/mdscan_addition.fth

: builtin-drivers	( -- str$ )
   " /packages/SUNW,builtin-drivers"
;

: builtin-phandle@  	( -- phandle true | false ) 
   builtin-drivers find-package
;

\ Creates a child device node that corresponds to PD node.
\ pdnode has to point at the NODE field
: create-device-node ( pdnode phandle -- flag )
   >r >r					(  )( R: phandle pdnode )
   \ get property
   " cfg-handle" ascii v r@ pdget-prop 		( pdentry|0 )( R: phandle pdnode )
   r> r> rot					( pdnode pdhandle pdentry|0 ) ( R: )
   dup 0= if 					( pdnode pdhandle 0 )
      rot getname				( pdhandle 0 name$) 
      cmn-error[ " Failed to find ""cfg-handle"" property "n"r"t " cmn-append
                 " Device node ""%s"" was not created "
      ]cmn-end					( pdhandle 0 )
      nip exit					( 0 )( R:  )
   then						( pdnode pdhandle pdentry )
   pddecode-prop				( pdnode pdhandle hi )

   -rot swap					( hi  pdhandle pdnode )  

   \ get property
   >r						( hi pdhandle ) ( R: pdnode )
   " fcode-driver-name" ascii s r@ pdget-prop  	( hi pdhandle pdentry|0 ) ( R: pdnode )
   r> swap					( hi pdhandle pdnode pdentry|0 ) ( R: )
   dup 0= if					( hi pdhandle pdnode 0 )
      swap getname				( hi pdhandle 0 name$ )
      cmn-error[ " Failed to find ""fcode-driver-name"" property "n"r"t " cmn-append
                 " device node ""%s"" was not created" 
      ]cmn-end					( hi pdhandle 0 )
      nip nip exit 				( 0 )( R:  )
   then						( hi pdhandle pdnode pdentry ) ( R: )
   swap >r					( hi pdhandle pdentry ) ( R: pdnode )
   pddecode-prop				( hi pdhandle dropname$ )
   rot find-method 				\ ( hi (dropacf true)|false ) ( R: )
   r> swap					\ ( hi (dropacf pdnode true)| pdnode false ) ( R: )
   0= if 					( hi pdnode ) ( R: )
      getname					( hi name$ ) ( R: )
      cmn-error[ " Failed to find dropin method "n"r"t " cmn-append
                 " device node ""%s"" was not created" 
      ]cmn-end					( hi )
      drop false exit				( false ) ( R: )
   then						( hi dropacf pdnode )
   >r						( hi dropacf ) ( R: pdnode )
   swap 					( dropacf hi )
   " encode-unit" my-self $call-method		( dropacf reg$ )
   0 0 2swap					( dropacf 0 0 reg$ )

   new-device set-args				( dropacf )
   r> swap					( pdnode dropacf ) ( R: )
   catch if					( pdnode )
      getname					( name$ ) ( R: )
      cmn-warn[ " Failed to attach driver "n"r"t " cmn-append
                " properties for device node ""%s"" were not created" 
      ]cmn-end 					( )
   then						( pdnode )
   drop finish-device true			( true )
;

\ --- interrupts words: ---------
: en+ encode-int encode+ ;

: pd-get-property ( prop$ type pdnode -- ?? true | false )
   pdget-prop dup if                            ( prop )
      pddecode-prop true                        ( ?? true )
   then                                         ( ?? true | false )
;

: pd-required-property ( prop$ type pdnode -- ?? )
   nip 3dup -1 swap pdget-prop ?dup if          ( prop$ pdnode prop )
      >r 3drop r> pddecode-prop                 ( ?? )
   else                                         ( prop$ pdnode )
      getname                                  ( prop$ node$ )
      cmn-error[ " Missing ""%s"" property in ""%s"" node of " cmn-append
                 " the Machine Description "
      ]cmn-end
      abort
   then
;

: build-intr-map ( xdr,len pdnode -- xdr,len' )
   >r							( xdr,len )( r:pdnode )
   " fwd" ascii a r@ pd-get-property if			( xdr,len svcnode )
      >r " ino" -1 r> pd-get-property if		( xdr,len ino )
         -rot                                           ( ino xdr,len  )
         " cfg-handle" ascii v r@ pd-required-property  en+
         1  en+
         my-interrupt-parent en+
         rot  en+
      then
   then							( xdr,len' )
   r> drop						( xdr,len' ) ( r: )
;


headers

: pd-dev-nodes ( -- )
   " root" 0 pdfind-node				( pdnode|0 )
   begin
      " virtual-device"					( pdnode type$ )
      pdnext-node 					( next-pdnode true | false )
   while						( next-pdnode )
      builtin-phandle@ 0=			\	( next-pdnode (phandle false)|true ) 
      if						( next-pdnode )
	builtin-drivers					( next-pdnode str$ )
        cmn-error[ " "tCan't find package: %s" ]cmn-end
        abort
      then						( next-pdnode phandle )
      over swap create-device-node 0=			( next-pdnode flag )
      if						( next-pdnode )
        cmn-error[ " Failed to create device node" ]cmn-end
      then						( next-pdnode )
   repeat						( next-pdnode )
;

: pd-int-map ( -- )
   " root" 0 pdfind-node			( pdnode|0 )
   dup 0= if					( 0 )
     drop					( )
     cmn-error[ " Can't find ""root"" node in Machine " cmn-append
                " Description"n"r"t ""interrupt-map"" property was not created " 
     ]cmn-end 					( )
   else						( pdnode )
     0 0 encode-bytes rot				( xdr,len pdnode )
     begin
        " virtual-device"			( xdr,len pdnode type$ )
        pdnext-node 				( xdr,len next-pdnode true | xdr,len false )
     while					( xdr,len next-pdnode )
        dup >r -rot r> build-intr-map 		( next-pdnode xdr',len' )
        rot					( xdr,len' next-pdnode )
     repeat					( xdr,len' next-pdnode )
	  					( xdr,len )
     ?dup if 					( xdr, len )
       " interrupt-map" property		( )
     else					( xdr )
       drop					( )
     then					( )
   then						( )
;
