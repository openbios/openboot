\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mif.fth
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
id: @(#)mif.fth 1.1 06/02/16
purpose: Intel Ophir/82571 PHY access routines
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headers

\ Routines to access the phy using the MDIO Auto-access method

1 value phy-adr				\ Internal phy address

1 d# 28 << constant phy-ready-bit
1 d# 30 << constant phy-error-bit

: mdi@		( -- value ) h# 20 reg@ ;
: mdi!		( value -- ) h# 20 reg! ;

\
\ Loop (for an arbitrarily chosen number of times)
\ until the ready-bit goes clear or we run out of loops.
\ At the end, return 0 if the ready bit is set and the error bit is
\ clear, else return non-zero.
\ Also, clear the error bit for the next access.
\
: phy-cmd-timeout?	( -- error? )
   d# 5000				\ ... whatever ... 
   begin				( loops )
      1- dup 0<				( loops timeout? )
      mdi@ phy-ready-bit and		( loops timeout? complete? )
      or				( loops done? )
   until				( loops )
   drop mdi@				( reg-val )
   dup phy-error-bit and 0<>		( reg-val error? )
   swap phy-ready-bit and 0= or		( error? )
;

: phy-val ( data reg-addr read? -- val )
   if  2 else 1 then			( data reg-addr  )
   d# 26 << 				( data reg-addr val0 )
   phy-adr h# 1f and d# 21 << or	( data reg-adr val1 )	\ shift in phy adr
   swap h# 1f and d# 16 << or		( data )	\ shift in reg adr
   swap h# ffff and or			(  )
;
   
: phy@		( reg-adr -- data )
   0 swap true phy-val mdi!			( )
   phy-cmd-timeout?			( timeout? )
   mdi@ h# ffff and			( timeout? data )
   nip					( data )	\ Throw away error!
;

: phy!		( data reg-adr -- )
   false phy-val mdi!			( )
   phy-cmd-timeout?			( error? )
   drop					( )	\ Throw away error!
;
