\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: config-access.fth
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
id: @(#)config-access.fth 1.2 05/10/12
purpose: 
copyright: Copyright 2005 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

\ Configuration space access routines executed from a child instance

headerless

\ pci express extended config space uses bits 28-31 as cfg offset bits 8-11

: >pcie  ( offset -- offset' )
   dup h# f00 and d# 20 << swap h# ff and or
;

: my-b@ ( offset -- b )  >pcie my-space or " config-b@" $call-parent ;
: my-w@ ( offset -- w )  >pcie my-space or " config-w@" $call-parent ;
: my-l@ ( offset -- l )  >pcie my-space or " config-l@" $call-parent ;

: my-b! ( b offset -- )  >pcie my-space or " config-b!" $call-parent ;
: my-w! ( w offset -- )  >pcie my-space or " config-w!" $call-parent ;
: my-l! ( l offset -- )  >pcie my-space or " config-l!" $call-parent ;
