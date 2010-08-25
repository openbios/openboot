\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: hyperconsole.fth
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
id: @(#)hyperconsole.fth 1.1 06/02/16
purpose: 
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
1 1 h# 61 0 hypercall: (hyperemit) ( char -- error? )
2 0 h# 60 0 hypercall: (hyperkey)  ( -- char error? )

headerless

: hyperemit ( char -- )
   begin dup (hyperemit) while 1 ms repeat drop
;

0 value hyperbreak?

: hyper-maygetchar ( -- char true | false )
   (hyperkey)  if		( ?? )
      drop false		( false )
   else				( char|break )
      dup -1 =  if		( break )
         \ BREAK
         to hyperbreak? false	( false )
      else			( char )
         true			( char true )
      then			( char true | false )
   then				( char true | false )
;
variable hyper-keybuf
: hyperkey? ( -- flag )
   hyper-keybuf @ -1 =  if	(  )
      hyper-maygetchar  if	( char )
         hyper-keybuf !  true   ( flag )
      else			(  )
         false			( flag )
      then			( flag )
   else				(  )
       true			( flag )
   then				( flag )
;

: hyperkey ( -- char )
  hyper-keybuf @ dup  -1 <>  if  -1 hyper-keybuf !  exit  then
  begin  hyper-maygetchar  until
;

headers

alias ukey  hyperkey
alias ukey? hyperkey?
alias uemit hyperemit

headerless
