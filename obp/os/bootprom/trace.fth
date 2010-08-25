\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: trace.fth
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
id: @(#)trace.fth 1.3 94/09/06
purpose: Debugging tool - traces package calls
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ Debugging tool for packages.
\   trace-on   ( -- )	Turns on package call tracing
\   trace-off  ( -- )	Turns off package call tracing
\
\ Tracing displays the stack contents, the name of the called package,
\ and the name of the called method each time that a package method is
\ invoked.  Calls to the stdin and stdout packages are not traced, as
\ doing so results in a screenful of hard-to-decipher messages.
headerless
: (trace)  ( adr len phandle -- adr len phandle )
   >r  >r >r  .s  r> r>           ( adr len )  ( r: phandle )
   also  r@ execute               ( adr len )  ( r: phandle )
   " name" get-property           ( adr len value-str false )  ( r: phandle )
   previous                       ( adr len value-str false )  ( r: phandle )
   drop get-encoded-string  type  ( adr len )  ( r: phandle )
   ." : "  2dup type space  cr    ( adr len )  ( r: phandle )
   r>                             ( adr len phandle )
;
: (safe-trace)  ( adr len phandle -- adr len phandle )
   dup   stdout @ pihandle=              ( adr len phandle flag )
   over  stdin  @ pihandle=  or  0=  if  ( adr len phandle )
      (trace)
   then
;
headers
: trace-on  ( -- )  ['] (safe-trace) is fm-hook  ;
: trace-off ( -- )  ['] noop is fm-hook  ;
