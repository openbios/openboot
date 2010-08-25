\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tftp-h.fth
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
id: @(#)tftp-h.fth 1.1 04/09/07
purpose:
copyright: Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

1     constant  TFTP_RRQ        \ Read request
2     constant  TFTP_WRQ        \ Write request
3     constant  TFTP_DATA       \ Data packet
d# 4  constant  TFTP_ACK        \ Acknowledgement
d# 5  constant  TFTP_ERROR      \ Error packet

struct
   /w  field  >tftp-opcode	\ Packet type
   0   field  >tftp-file	\ Filename and mode (RRQ/WRQ)
   0   field  >tftp-errcode	\ Error code (ERROR)
   /w  field  >tftp-block#	\ Block number (DATA/ACK)
   0   field  >tftp-data	\ Segment data or error message
   0   field  >tftp-errmsg	\ Error message
constant /tftp-header

d# 512 constant TFTP_SEGSIZE	\ Default data segment size

: /tftp-packet ( -- n )  TFTP_SEGSIZE /tftp-header + ;

headers
