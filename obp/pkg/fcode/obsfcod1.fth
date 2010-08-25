\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: obsfcod1.fth
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
id: @(#)obsfcod1.fth 1.5 02/10/03
purpose: Installs handlers for obsolete (not in IEEE 1275) FCode functions
copyright: Copyright 1994-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\  This is common code (Aaaa-a-a-aaahhHHH-CHOOOOOoooo!)
\      between the FCode interpreter and the Tokenizer.

\  \  Except for this:
\  v1 v2  h# 001 1 byte-code: .fcode-dma-alloc ( #bytes -- virtual )
\  v1 v2  h# 001 1 byte-code:        dma-alloc ( #bytes -- virtual )
\  \  The first belongs in the FCode interpreter; the second should
\  \      be changed altogether... 


v1 v2  h# 004 1 byte-code: memmap           ( physical space size -- virtual )
v1 v2  h# 006 1 byte-code: >physical        ( virtual -- physical space )
v1 v2  h# 00f 1 byte-code: my-params        ( -- addr len )
v1 v2  h# 017 1 byte-code: intr             ( int-level vector -- )
v1     h# 018 1 byte-code: driver           ( adr len -- )
v1 v2  h# 021 1 byte-code: display-status   ( n -- )
v1 v2  h# 023 1 byte-code: group-code       ( -- adr )
