\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pd-vd-methods.fth
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
id: @(#)pd-vd-methods.fth 1.2 06/05/22
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

fload ${BP}/dev/sun4v-devices/utilities/mdscan_addition.fth

\ return ptr to the PD node whose cfg-handle = my-space
\ of the current device node
\ return 0 if such PD node is not found
: find-mynode  ( -- pdnode|0 )
   " root" 0 pdfind-node				( pdnode|0 )
   dup 0= if						( 0 )
	exit						( 0 )
   then							( pdnode )
   begin						( pdnode )
      " virtual-device"					( pdnode type$ )
      pdnext-node 					( next-pdnode true | false )
   while						( next-pdnode )
      dup >r " cfg-handle" ascii v r> pdget-prop	( next-pdnode prop' | next-pdnode 0 )
      ?dup if						( next-pdnode prop' )
	pddecode-prop					( next-pdnode prop )
        my-space h# ff.ffff and =			( next-pdnode ? )
        if \ found the node (myself)			( next-pdnode )
           exit						( next-pdnode )
        then						( next-pdnode prop )
      then						( next-pdnode )
   repeat
   0							( 0 )   
;

: required-prop ( prop-name$ -- val )
2dup  -1 my-node pdget-prop		( prop-name$ prop-ptr|0 )
?dup if 				( prop-name$ prop-ptr )
   nip nip 				( prop-ptr )
   pddecode-prop			( prop-val )
else 					( prop-name$ )
   my-node getname			( prop-name$ pdname$ )
   cmn-error[ " Missing ""%s"" property in ""%s"" node of " cmn-append 
              " the Machine Description " 
   ]cmn-end				( )
   abort 				( )
then					( prop-ptr )
;
