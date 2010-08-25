\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: instance.fth
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
id: @(#)instance.fth 1.2 03/12/08 13:22:42
purpose: 
copyright: Copyright 2002-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
code >instance-data ( pfa -- adr )
   'user my-self                sc2     nget
   sc2  %g0                     %g0     subcc
   0<> if					\ @
      64\ \dtc tos 0            scr     ld      \ (delay)
      64\ \itc tos 0            sc1     lduh    \ (delay)
      32\ \dtc tos 0            tos     ld      \ (delay)
      32\ \itc tos 2            scr     lduh    \ (delay)

      64\ \dtc scr h# 20        scr     slln
      64\ \dtc tos 4            tos     ld
      64\ \dtc tos scr          tos     or

      64\ \itc sc1 h# 10        scr     slln
      64\ \itc tos 2            sc1     lduh
      64\ \itc sc1 scr          scr     or
      64\ \itc scr h# 10        scr     slln
      64\ \itc tos 4            sc1     lduh
      64\ \itc sc1 scr          scr     or
      64\ \itc scr h# 10        scr     slln
      64\ \itc tos 6            sc1     lduh
      64\ \itc sc1 scr          tos     or
 
      32\ \itc tos 0            tos     lduh
      32\ \itc tos h# 10        tos     slln
      32\ \itc scr tos          tos     add
 
      tos sc2                   tos     add       \ +
      next
   then
   end-code
   colon-cf ]
   true  abort" Tried to access instance-specific data with no current instance"
;

