\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: mii-h.fth
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
id: @(#) mii-h.fth 1.2 03/08/23
purpose: Ethernet PHY MII register access routines and bit-fields.
copyright: Copyright 1999-2003 Sun Microsystems, Inc. All Rights Reserved.
copyright: Use is subject to license terms.

headers

\ PHY Control register
: phy-cr@  ( -- data )   0 phy@ ;
: phy-cr!  ( data -- )   0 phy! ; 

\ PHY Status register
: phy-sr@  ( -- data )  1 phy@  drop  1 phy@ ;

\ PHY Identifier registers
: phy-id1@  ( -- data )  2 phy@ ;
: phy-id2@  ( -- data )  3 phy@ ;

: phy-id@  ( -- phy-id )  phy-id1@ d# 16 lshift  phy-id2@ or ;

\ Auto-negotiation Advertisement register
: phy-anar@ ( -- data )  4 phy@  ;
: phy-anar! ( data -- )  4 phy!  ;

\ Auto-Negotiation Link Partner Ability Register
: phy-anlpar@  ( -- data )  5 phy@ ;

\ Auto-Negotiation Expansion Register
: phy-aner@ ( -- data )   h# 6 phy@ ;

headerless

\ Basic Control register definitions
h# 8000  constant  phycr.reset
h# 4000  constant  phycr.loopback
h# 2040  constant  phycr.speed-mask
h# 1000  constant  phycr.an-enable
h#  200  constant  phycr.an-restart
h#  100  constant  phycr.duplex

h#    0  constant  phycr.speed-10
h# 2000  constant  phycr.speed-100
h#   40  constant  phycr.speed-1000

\ Basic Status register definitions
h#  20   constant  physr.an-complete
h#   4   constant  physr.link-up
h# 100   constant  physr.ext-status

\ PHY Identifier values
h#  206050  constant  broadcom-605x
h# 1410c52  constant  marvell-88e1000
h#  437411  constant  lucent-3X31T

\ Autonegotiation Advertisement Register definitions
h#    1  constant  anar.selector-field  \ IEEE 802.3 protocol selector field.

\ Autonegotiation Link Partner Ability register definitions
h#   20  constant  anlpar.10hdx
h#   40  constant  anlpar.10fdx
h#   80  constant  anlpar.100hdx
h#  100  constant  anlpar.100fdx

\ Autonegotiation Expansion register definitions
h#    1  constant  aner.lp-an-able
h#   10  constant  aner.mlf         \ Multiple link fault

headers
