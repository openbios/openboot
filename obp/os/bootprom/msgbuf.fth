\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: msgbuf.fth
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
id: @(#)msgbuf.fth 1.6 01/04/06
purpose: 
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless
h# 1800 constant  msg-buf-size
msg-buf-size 	buffer: msg-buf

variable msg-buf-ptr  msg-buf-ptr off
variable msg-buf-end  msg-buf-end off

headers
: show-tty-msgs ( -- )  msg-buf-ptr @  msg-buf tuck - type cr  ;

\   begin				( adr len )
\      dup exit? 0= and 			( adr len flag )
\   while				( adr len )
\      control M left-parse-string 	( adr len' adr2 len2 )
\      ?dup if				( adr len' adr2 len2 )
\          type (cr 1 #line +!		( adr len' )
\      else				( adr len' adr )
\          drop				( adr len' )
\      then				( adr len' )
\   repeat			
\   2drop
headerless

\ NOTE: msg-buf-ptr and msg-buf-end must be initialized after msg-buffer
\       is accessed.  Since msg-buffer is defined as buffer:, its
\       space is only being allocated after the first access.
stand-init: Alloc msg buf
   msg-buf msg-buf-size 0 fill 
   msg-buf msg-buf-ptr !
   msg-buf msg-buf-size + msg-buf-end !
;

headers
