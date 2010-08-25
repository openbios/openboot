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
id: @(#)probe.fth 1.6 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ In order to use this file you need to:
\ 
\ Define
\	a nexus specific address to string converter and set the defer
\	make-probe-device$ to point to it.
\	The stack diagram is:
\ 
\		my-bus-encoder ( pa.lo pa.hi -- str,len )
\ 
\	You should use the name of your nexus and typically your encode 
\	method to make strings of the form:
\ 
\		foo-pa,hi,pa-lo
\ 
\ These strings correspond to the names of the methods that load
\ the built-in drivers.
\
\	You may also need to modify:	my-interrupt-parent
\		if interrupts from your children do not go to your parent.
\		If this is true and your children generate interrupts in
\		different parent nodes then this code will need to change.
\
\
\ External interfaces for you to use:
\ 
\	build-probed-nodes ( -- )
\		This will probe the nodes and create location and interrupt
\		map properties appropriately.
\ 
\	probe-table! ( my-space my-address acf intr ino location,len -- )
\		Call this routine to append nodes to the probe list that
\		will be used by the build-probed-nodes method.
\
\		my-space,my-address	are obvious and will form
\					the reg entry in your node
\		acf			This is a probe rooutine.
\					-1 means dont probe just create,
\					otherwise it must point to a 
\					routine with a stack diagram that 
\					must be:
\					my-probe ( lo,hi -- probe? )
\					lo,hi and my-space,my-address that
\					you defined on the probe-table! 
\					line.
\					If this acf executes then the state
\					returned is cached to improve
\					performance.
\		intr, ino		a mapping for a device generated 
\					intr and an INO in the node pointed 
\					to by my-interrupt-parent.
\					0,0 means no interrupts and no 
\					entry will be created in 
\					interrupt-map.
\		locn,len		a string to use as the location
\					property if this node exists.
\					Null string (0,0) means there is no
\					location property for this node.
\

headerless
0 value num-addrcells
0 value builtin-phandle

: no-loc$ ( -- adr, len ) 0 0 ;		\ used in most nexuses

: builtin-drivers ( -- str$ ) " /packages/SUNW,builtin-drivers" ;

my-parent ihandle>phandle instance value my-interrupt-parent
			instance defer make-probe-device$
h# 20			instance buffer: probed-device$
h# 1000 alloc-mem dup	instance value device-probe-list
( table )		instance value device-probe-ptr

struct
   4 field >probe-acf
   4 field >probe-address
   4 field >probe-location
   2 field >probe-space
   1 field >probe-ino
   1 field >probe-intr
constant /probe-entry

: probe-table! ( my-space my-address acf intr ino location,len -- )
   device-probe-ptr >r
   ?dup if				( space addr acf intr ino loc,len)
      dup 2 + alloc-mem pack		( space addr acf intr ino va )
   else					( space addr acf intr ino loc )
      drop 0				( space addr acf intr ino 0 )
   then					( space addr acf intr ino va )
   r@ >probe-location l!		( space addr acf intr ino )
   r@ >probe-ino c!			( space addr acf intr )
   r@ >probe-intr c!			( space addr acf )
   r@ >probe-acf l!			( space addr )
   r@ >probe-address l!			( space )
   r@ >probe-space w!			( )
   r> /probe-entry + is device-probe-ptr
;

: asr-probe ( ptr acf -- ptr acf build-it? )	\ hook for asr
   true
;

: (parse-table) ( table acf -- )
   begin					( ptr acf )
      over device-probe-ptr < while		( ptr acf )
         asr-probe if
            2dup execute			( ptr acf )
         then
         swap /probe-entry + swap		( ptr' acf )
   repeat 2drop					( -- )
;

: build-probed-node ( ptr -- )
   builtin-phandle >r >r			( )
   r@ >probe-address l@ r@ >probe-space w@	( lo hi )
   r@ >probe-acf l@ dup case			( lo hi acf acf )
      -1 of  endof				( lo hi true )
      0  of  endof				( lo hi false )
      ( default )
      drop >r 2dup r>				( lo hi lo hi acf )
      catch if					( lo hi xx yy )
         2drop false				( lo hi false )
      then					( lo hi probe? )
      0						( lo hi probe? 0 )
   endcase					( lo hi probe? )
   dup r@ >probe-acf l!				( lo hi probe? )
   r> r>					( lo hi probe? ptr phandle )
   rot 0= if 					( lo hi ptr phandle )
      2drop 2drop exit 				( )
   then						( lo hi ptr phandle )
   2over  make-probe-device$			( lo hi ptr phandle probe$ )
   rot find-method if				( lo hi ptr acf )
      2swap num-addrcells 1 = if nip then	( ptr acf hi )
      " encode-unit" my-self $call-method	( ptr acf reg$ )
      0 0 2swap					( ptr acf 0 0 reg$ )
      new-device				( ptr acf 0 0 reg$ )
         set-args				( ptr acf )
         catch 0= if				( ptr )
            dup >probe-location l@ ?dup if	( ptr va )
               count encode-string		( ptr xdr,len )
               " sunw,location" property	( ptr )
            then				( ptr )
         then					( ptr )
         drop					( )
      finish-device				( )
   else						( lo hi ptr )
      3drop					( )
   then						( )
;

: en+ encode-int encode+ ;

: build-prober-intrmap ( xdr,len ptr acf ptr -- )
   >probe-intr c@ if				( xdr,len ptr acf )
      over >r 2swap				( ptr acf xdr,len )
      r@ >probe-space w@ en+			( ptr acf xdr,len )
      num-addrcells 2 = if			( ptr acf xdr,len )
        r@ >probe-address l@ en+		( ptr acf xdr,len )
      then					( ptr acf xdr,len )
      r@ >probe-intr c@ en+			( ptr acf xdr,len )
      my-interrupt-parent en+			( ptr acf xdr,len )
      r> >probe-ino c@ en+			( ptr acf xdr,len )
      2swap					( xdr,len ptr acf )
   then						( xdr,len ptr acf )
;

: locn-strings ( ptr -- )
   >probe-location l@ ?dup if			( va )
      dup c@ 2 + free-mem			( )
   then						( )
;

: build-probed-nodes ( -- )
   builtin-drivers find-package 0=  if
      exit
   then  is builtin-phandle
   " #address-cells" get-my-property 0=  if
      decode-int nip nip
   else
[ifndef] RELEASE
      cmn-error[ " Missing #address-cells property" ]cmn-end
[then]
      2
   then  is num-addrcells
   diagnostic-mode?  if  cmn-msg[   then
  
   0 0 encode-bytes
   device-probe-list  ['] build-prober-intrmap  (parse-table)
   ?dup if  " interrupt-map" property  else  drop  then
   device-probe-list  ['] build-probed-node  (parse-table)
   device-probe-list  ['] locn-strings (parse-table)
   device-probe-list h# 1000 free-mem
  
   diagnostic-mode?  if   " " ]cmn-end  then
;
