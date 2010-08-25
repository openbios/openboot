\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: support.fth
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
id: @(#)support.fth 1.12 01/05/29
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

\ This is the additional code required to permit atapi packets to
\ be run from downstream devices.

headers

0 value atapi-debug?
5 value #atapi-retries

headerless

: atapi-features! ( data -- )	cmd-regs 1 + c! ;
: atapi-reason@ ( -- data )	cmd-regs 2 + c@ ;

: pkt-size@ ( -- len ) 4 ata@ 5 ata@ bwjoin ;
: pkt-size! ( len -- )  wbsplit 5 ata! 4 ata! ;

: .dev-ready? ( status -- set? ) h# 88 and h# 8 = ;
: dev-ready? ( t -- ok? ) ['] .dev-ready? alt-wait-status ;

: .wait-irq? ( status -- set? ) drop ide-irq? ;
: wait-irq ( t -- ok? ) ['] .wait-irq? alt-wait-status ;

: .atapi-err ( pkt code -- )
   atapi-debug? if
      ." CMD Failed: " dup .x space ." = "
      ." SenseKey: "
      dup d# 4 >> case
         h# 0 of ." No Sense" endof
         h# 1 of ." Recovered Error" endof
         h# 2 of ." Not Ready" endof
         h# 3 of ." M Error" endof
         h# 4 of ." H/W Error" endof
         h# 5 of ." Illegal REQ" endof
         h# 6 of ." ATTENTION" endof
         h# 7 of ." PROTECT" endof
         h# b of ." ABRT" endof
         h# e of ." MISCOMPARE" endof
         ( ) ." RSVD"
      endcase space ." ErrBits: "
      dup h# f and
      dup h# 8 and if ." MCR " then
      dup h# 4 and if ." ABRT " then
      dup h# 2 and if ." EOM " then
      dup h# 1 and if ." ILI" then
      0= if ." None" then
      cr
   then
   swap >status l!
;

: run-atapi ( pkt -- error? )
   dup >timeout l@ is timeout			( pkt )
   d# 2000 alt-wait-!busy? 0= if drop true exit then
   disk-id >disk h# e0 or lun or head!		( pkt )
   0 atapi-features!				( pkt )
   blocksize pkt-size!				( pkt )
   h# a0 cmd!					( pkt )
   d# 10 alt-wait-data? 0= if			( pkt )
     drop true exit				( true )
   then						( pkt )
   dup >cdb-ptr l@				( pkt cdb )
   d# 12 bounds do				( pkt )
      i w@ data!				( pkt )
      astat@ .check-data 0= ?leave		( pkt )
   2 +loop					( pkt )
   stat@ h# 1 and if				( pkt )
      err@ .atapi-err true exit			( true )
   then						( pkt )
   begin					( pkt more? )
      timeout alt-wait-!busy? if
         astat@ .check-data
      else false then				( pkt more? )
      while					( pkt )
         atapi-reason@ 2 and			( pkt? io )
         if (read) else (write) then		( pkt? )
         dup >transfer-bytes			( pkt lenptr )
         dup >r l@				( pkt len )
         over >data-ptr l@			( pkt len buffer )
         over >r +				( pkt buffer' )
         pkt-size@				( pkt buffer' size )
         tuck cmd-regs -rot			( pkt size regs buffer size )
         ?dup if xfer-fn else 3drop then	( pkt size )
         r> + r> l!				( pkt )
   repeat					( pkt )
   stat@ h# 1 and if				( pkt )
      err@ .atapi-err true exit			( flag )
   then						(  )
   drop false					( flag )
;
