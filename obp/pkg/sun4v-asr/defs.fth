\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: defs.fth
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
id: @(#)defs.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

0 constant diag-src
1 constant user-src

1 constant flag-user-disabled	\ user, with reason$
2 constant flag-diag-disabled	\ diag, with reason$
4 constant flag-override	\ disabled, but overridden (no brick)

d#  0 constant asr-cmd-ok
d#  1 constant asr-cmd-failed
d#  2 constant asr-unknown-cmd
d#  3 constant asr-unknown-key
d#  4 constant asr-no-match
d#  5 constant asr-db-ovrflow
d# 10 constant asr-unknown-error
d# 11 constant asr-reason-too-big
d# 12 constant asr-rx-error
d# 13 constant asr-tx-error

\      2   There is an asr entry matching the key and the value of
\          asr-policy is "service" .
\      1   There is an ASR entry matching the key, but it has been
\ 	 ignored because the machine needs the corresponding device in
\ 	 order to run OBP, (see exceptions, section 5), and the value
\ 	 of asr-policy is "standard".
\      0   The device corresponding to the key is OK.
\ 	 (There is no asr-entry in the asr-db for the device.)
\ 	 The value of asr-policy is either "standard" or "service".
\     -1   The device corresponding to the key is disabled by USER and
\ 	 the value of asr-policy is "standard".
\     -2   The device corresponding to the key is disabled by FWDIAGS and
\ 	 the value of asr-policy is "standard".
\     -3   The device corresponding to the key is disabled by both
\ 	 USER and FWDIAGS and the value of asr-policy is "standard".

 2 constant query-service
 1 constant query-ovr
 0 constant query-ok
-1 constant query-u-dis
-2 constant query-d-dis
-3 constant query-ud-dis

d# 9 constant asr-sid

d# 0 constant disable-cmd
d# 1 constant enable-cmd
d# 2 constant keylist-cmd
d# 3 constant keylistlen-cmd
d# 4 constant state-cmd
d# 5 constant statelen-cmd
d# 6 constant reason-cmd
d# 7 constant reasonlen-cmd
d# 8 constant clear-cmd
d# 9 constant query-cmd
