\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: svc.fth
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
id: @(#)svc.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ 
\ This is a simple wrapper to the htraps that run the svc buffers.
\ 
\ Call init-svc before you use the interfaces.
\

headerless

0 value my-svc
0 value my-mtu
0 value inbuf
0 value outbuf
0 value pibuf
0 value pobuf

: init-svc ( svc mtu -- )
   dup alloc-mem is inbuf
   dup alloc-mem is outbuf
   is my-mtu
   is my-svc
   inbuf >physical drop is pibuf
   outbuf >physical drop is pobuf
;

: finish-svc ( -- )
   inbuf my-mtu free-mem
   outbuf my-mtu free-mem
;

: getstatus ( -- reg )	begin my-svc 1 2 h# 82 h# 80 htrap 0= until ;
: setstatus ( reg -- )	begin my-svc swap 2 1 h# 83 h# 80 htrap 0= until  ;
: clrstatus ( reg -- )	begin my-svc swap 2 1 h# 84 h# 80 htrap 0= until ;

: send? ( -- flag )	     getstatus h# 10 and 0= ;
: recv? ( -- key )	     getstatus h# 01 and 0<> ;

\ these two are raw.. they assume you have check status before calling them
: recv ( -- len )
   my-svc pibuf my-mtu 3 2 h# 81 h# 80 htrap if
     drop 0
   else
      1 clrstatus
   then
;

: send ( len -- )
   h# 4 clrstatus >r my-svc pobuf r> 3 1 h# 80 h# 80 htrap drop
;
