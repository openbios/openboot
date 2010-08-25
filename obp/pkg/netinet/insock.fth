\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: insock.fth
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
id: @(#)insock.fth 1.1 04/09/07
purpose: IPV4 socket address representation
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

2  constant  AF_INET			\ IPV4 address family

\ IPV4 socket address structure
struct
   /c        field  >sin-len		\ Length of structure
   /c        field  >sin-family		\ AF_INET 
   /w        field  >sin-port		\ 16-bit port, network byte ordered
   /ip-addr  field  >sin-addr		\ IP address, network byte ordered
   8         field  >sin-zero		\ Unused
constant /insock

\ Initialize fields in a socket address structure. 
: insock-init ( insock ipaddr port -- )
   rot  dup /insock erase			( ipaddr port insock )
   AF_INET  over  >sin-family  c!		( ipaddr port insock )
   /insock  over  >sin-len     c!		( ipaddr port insock )
   tuck           >sin-port    htonw!		( ipaddr insock )
                  >sin-addr    copy-ip-addr	( )
;

: insock>addr,port ( insock -- ipaddr port )
   dup >sin-addr  swap  >sin-port ntohw@
;

: insock= ( insock1 insock2 -- flag )  /insock comp 0= ;

: .insock ( insock -- )
   insock>addr,port  swap .ipaddr  ." :"  .d
;

headers
