\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: pktdata.fth
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
id: @(#)pktdata.fth 1.2 01/05/29
purpose: 
copyright: Copyright 1997-2001 Sun Microsystems, Inc.  All Rights Reserved

\ This defines the format of a packet for the ata/atapi interface

struct \ xfer-pkt
  4 field >xfer-type		\ Transfer type 0 = ATA, 1 = ATAPI
  4 field >cdb-ptr		\ pointer to cdb/reg struct
  4 field >transfer-bytes	\ number of bytes transferred
  4 field >data-ptr		\ address of data buffer.
  4 field >timeout		\ Timeout for xfer
  4 field >status		\ Status, set on errors
constant /xfer-pkt

: get-pkt-data ( pkt -- buffer cdb pkt )
   >r					( -- )
   0 r@ >transfer-bytes l!		( -- )
   0 r@ >status l!			( -- )
   r@ >data-ptr l@			( buffer )
   r@ >cdb-ptr l@			( buffer cdb )
   r>					( buffer cdb pkt )
;

: set-pkt-data ( buffer cdb timeout pkt -- pkt )
   >r					( buffer cdb timeout )
   r@ /xfer-pkt erase			( buffer cdb timeout )
   r@ >timeout l!			( buffer cdb )
   r@ >cdb-ptr l!			( buffer )
   r@ >data-ptr l!			( )
   r>					( pkt )
;
