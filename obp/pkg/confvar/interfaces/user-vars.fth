\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: user-vars.fth
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
id: @(#)user-vars.fth 1.1 00/04/20
purpose: 
copyright: Copyright 1990-2000 Sun Microsystems, Inc.  All Rights Reserved

\ Interfaces to the mechanism (if any) for user-created environment variables
\ Some of these interfaces are used in clientif.fth

headers

defer next-env-var  ( adr len -- adr' len' )
: no-next-env-var  ( adr len -- null$ )  2drop null$  ;
' no-next-env-var to next-env-var

defer put-env-var  ( value$ name$ -- len )
: no-put-env-var  ( value$ name$ -- len )  2drop 2drop -1  ;
' no-put-env-var to put-env-var

\ show-extra-env displays the values of environment variables
\ other than the ones explicitly known by Open Firmware.
defer show-extra-env-vars
' noop is show-extra-env-vars

defer show-extra-env-var  ( name$ -- )
: no-show-extra  ( name$ -- )  ." Unknown option: " type cr  ;
' no-show-extra to show-extra-env-var

defer put-extra-env-var  ( value$ name$ -- )
: no-put-extra  ( value$ name$ -- )  no-show-extra 2drop  ;
' no-put-extra to put-extra-env-var

defer get-env-var  ( name$ -- true | value$ false )
: no-get-env-var  ( name$ -- true )  2drop  true  ;
' no-get-env-var to get-env-var

headerless

