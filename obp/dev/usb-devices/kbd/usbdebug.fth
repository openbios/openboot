\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usbdebug.fth
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
\ id: @(#)usbdebug.fth 1.9 03/05/08
\ purpose: 
\ copyright: Copyright 1997-2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
\ copyright: Use is subject to license terms.

[ifdef] debugging?
\ headers			\ XXX for debugging
external
hex

\ dump the info for the current input key buffer
: .dc
." curr modkeys " keybuff-curr^v >kbd-in-modkeys c@ . cr
." curr resrved " keybuff-curr^v >kbd-in-reserved c@ . cr
." curr byte1   " keybuff-curr^v >kbd-in-byte1 c@ . cr
." curr byte2   " keybuff-curr^v >kbd-in-byte2 c@ . cr
." curr byte3   " keybuff-curr^v >kbd-in-byte3 c@ . cr
." curr byte4   " keybuff-curr^v >kbd-in-byte4 c@ . cr
." curr byte5   " keybuff-curr^v >kbd-in-byte5 c@ . cr
." curr byte6   " keybuff-curr^v >kbd-in-byte6 c@ . cr
." curr #keysdn " keybuff-curr^v >#keys-down c@ . cr
." curr #rgkydn " keybuff-curr^v >#regl-keys-dn c@ . cr
." curr-repeat-key is " curr-repeat-key . cr
." putptr is " putptr .  ." getptr is " getptr . cr
;

: .dcx
." curr #keysdn " keybuff-curr^v >#keys-down c@ . cr
." curr #rgkydn " keybuff-curr^v >#regl-keys-dn c@ . cr
." curr-repeat-key is " curr-repeat-key . cr
;

\ dump the info for the previous input key buffer
: .dp
." prev modkeys " keybuff-prev >kbd-in-modkeys c@ . cr
." prev resrved " keybuff-prev >kbd-in-reserved c@ . cr
." prev byte1   " keybuff-prev >kbd-in-byte1 c@ . cr
." prev byte2   " keybuff-prev >kbd-in-byte2 c@ . cr
." prev byte3   " keybuff-prev >kbd-in-byte3 c@ . cr
." prev byte4   " keybuff-prev >kbd-in-byte4 c@ . cr
." prev byte5   " keybuff-prev >kbd-in-byte5 c@ . cr
." prev byte6   " keybuff-prev >kbd-in-byte6 c@ . cr
." prev #keysdn " keybuff-prev >#keys-down c@ . cr
." prev #rgkydn " keybuff-prev >#regl-keys-dn c@ . cr
;

: .dpx
." prev #keysdn " keybuff-prev >#keys-down c@ . cr
." prev #rgkydn " keybuff-prev >#regl-keys-dn c@ . cr
;

[then]
