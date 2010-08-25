\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sysconfig.fth
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
id: @(#)sysconfig.fth 1.13 06/02/16
purpose: system configuration information
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

\ Make sure to update Copyrights to match up with the year in which
\ OpenBoot PROM is released.
: .copyrights ( -- )
   ." Copyright 2006 Sun Microsystems, Inc.  All rights reserved." cr
;

: .rom  ( -- )
   ." OpenBoot " obp-release ". 
;

defer .memory-speed  ' noop  is .memory-speed

: (memory-installed ( -- ) ."  memory installed" ;

defer .memory-install-msg ' (memory-installed is .memory-install-msg

: memory-size ( -- #megs )
   " size" memory-node @ $call-method lxjoin 1meg /
;

: .memory ( -- )
   memory-size .d ." MB"  .memory-speed .memory-install-msg
;

: .serial  ( -- )
   ." Serial #"  serial# (.d) type  ." ."
;

: .ether  ( -- )  ." Ethernet address " .enet-addr  ;

: .hostid  ( -- )
   push-hex
   ." Host ID: "  hostid  <# u# u# u# u# u# u# u# u# u#> type
   pop-base
;

: cpu-model  ( -- adr len )
   current-device >r
   root-device
      " banner-name" get-property
   r> push-device  if
      " "
   else
      get-encoded-string
   then
;
