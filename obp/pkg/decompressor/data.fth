\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: data.fth
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
id: @(#)data.fth 1.2 01/04/06
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

headers
transient

inline-struct? on

\
\ Watch out space saving trickery here..
\ constants use a lot of space; if they are only used once or twice
\ it is more efficient to use literals, however that obfuscates code
\ so instead I pull an immediate+literal trick
\
d#    14 dup constant dc-#bits
1 swap <<    constant maxmaxbits		\ should NEVER generate this
d#     9     constant #init-bits		\ initial number of bits/code
d# 18013     constant hsize			\ 91% occupancy
d#  8000     constant /destack

struct
    /l field >getcode-offset
    /l field >getcode-oldcode
    /l field >n-bits		\ current #bits we are compressing with
    /l field >maxcode		\ current maximum code value
    /l field >fin-char
    /l field >incode
    /l field >free-ent		\ current free code value
    /l field >tab-suffix	\ ptr to a buffer.
    /l field >tab-prefix	\ ptr to another buffer
    /l field >de-stack		\ and yet another buffer
    /l field >source-size	\ source buffer size
    /l field >source-addr	\ source address ptr
    /l field >dest-addr		\ destination address ptr
constant /decomp-control

struct
   /decomp-control h# 80 round-up	field >decomp-control
   hsize    h# 100 round-up		field >tab-suffix-offset
   hsize 2* h# 400 round-up		field >tab-prefix-offset
   /destack h# 400 round-up		field >destack-offset
constant /decomp-data

inline-struct? off

resident
