\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: gmii-h.fth
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
id: @(#) gmii-h.fth 1.2 03/08/23
purpose: Ethernet PHY GMII register access routines and bit-fields.
copyright: Copyright 1999-2003 Sun Microsystems, Inc. All Rights Reserved.
copyright: Use is subject to license terms.

headerless

\ GMII 1000Base-T Control Register definitions
h#  100  constant  gcr.1000bt-hdx    \ Advertise 1000Base-T HDX
h#  200  constant  gcr.1000bt-fdx    \ Advertise 1000Base-T FDX
h#  800  constant  gcr.ms-cfg-value  \ Master/Salve 1000Base-T link clock value
h# 1000  constant  gcr.ms-cfg-enable \ Master/Slave 1000Base-T link clock enable

\ GMII 1000Base-T Status Register definitions
h#  400  constant  gsr.lp-1000hdx        \ Link Partner 1000Base-T HDX capable
h#  800  constant  gsr.lp-1000fdx        \ Link Partner 1000Base-T FDX capable
h# 1000  constant  gsr.remote-rx-status  \ Remote receiver status
h# 2000  constant  gsr.local-rx-status   \ Local Receiver status
h# 4000  constant  gsr.ms-cfg-resolution \ Master/Slave link-clk cfg resolution
h# 8000  constant  gsr.ms-cfg-fault      \ Master/Salve link-clk cfg fault

\ GMII Extended Status Register definitions
h# 2000  constant  esr.1000bt-fdx     \ 1000Base-T FDX capable
h# 1000  constant  esr.1000bt-hdx     \ 1000Base-T HDX capable

headers

\ 1000 Base-T Control Register
: phy-1000-cr@  ( -- data )   9 phy@  ;
: phy-1000-cr!  ( data -- )   9 phy!  ;

\ 1000 Base-T Status Register
: phy-1000-sr@  ( -- data )   h# a phy@ ; 

\ Extended Status register
: phy-esr@  ( -- data )   h# f phy@ ;

: gmii-phy? ( -- flag )
   phy-sr@ physr.ext-status and  0<>
; 

headers
