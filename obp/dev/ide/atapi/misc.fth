\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: misc.fth
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
id: @(#)misc.fth 1.1 97/05/30
purpose: 
copyright: Copyright 1997 Sun Microsystems, Inc.  All Rights Reserved

headerless


/xfer-pkt	instance buffer: atapi-pkt
d# 16		instance buffer: atapi-cmd
/xfer-pkt	instance buffer: req-pkt
d# 16		instance buffer: req-cmd
d# 40		instance buffer: req-buf
: erase-cdb ( -- ) d#   12 h#  0 fill ;

: run-command ( pkt type -- error? )
   over >xfer-type l!			( pkt )
   " run-command" $call-parent 		( error? )
;
: (run-atapi)	( pkt -- error? ) 1 run-command ;
: run-ata	( pkt -- error? ) 0 run-command ;

: long>cdb ( long cdb -- )  >r lbsplit r> 4 bounds do i c! loop ;

: request-sense ( buffer -- false|status,true )
   req-cmd erase-cdb			( buffer )
   req-cmd				( buffer cdb )
   3 over c! d# 18 over 4 + c!		( buffer cdb )
   h# 400 req-pkt set-pkt-data		( pkt )
   (run-atapi)				( [fail?] )
;

\
\ We define a new run-atapi to harden the interface a little and do
\ some error recovery - the parameters also change a little, this is
\ just to make error recovery simpler for devices using the I/F.
\
: run-atapi ( pkt -- error? )
   #atapi-retries 0 			( pkt retries error? )
   begin drop >r			( pkt )
      dup (run-atapi) dup if		( pkt )
         drop dup >status l@		( pkt status )
         4 >> 6 = if			( pkt )
            req-buf request-sense drop	( pkt )
         then				( pkt )
         true				( pkt true )
      then				( pkt error? )
      r> 1- swap			( pkt retry? error? )
      2dup and				( pkt retry? error? ? )
   0= until				( pkt retry? error? )
   >r 2drop r>				( error? )
;

: device-present? ( -- flag )
   atapi-cmd erase-cdb			( -- )
   0 atapi-cmd c!			( -- )
   0 atapi-cmd h# 200			( buffer cdb timeout )
   atapi-pkt set-pkt-data		( pkt )
   run-atapi 0=				( present? )
;
