\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: keycodes.fth
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
id: @(#)keycodes.fth 1.2 99/04/08
purpose: 
copyright: Copyright 1998 Sun Microsystems, Inc.  All Rights Reserved

headerless

  -1  constant nokey
    9 constant tab
h# 7f constant del
h# 1b constant esc

\  The "special" entries are defined below.  Their numerical values
\  are >= 0x80  <= 0x9f .  Entries < 0x80 and > 0x9f are ASCII characters.

h#    82  constant shift                \ Either shift key
h#    83  constant power                \ power key
h#    84  constant ctrl                 \ Control key
h#    85  constant altg                 \ Alt Graph key
h#    86  constant nop                  \ this key does nothing
h#    87  constant oops                 \ This key exists but is undefined
h#    88  constant hole                 \ This key does not exits on the
                                        \ keyboard.  Its position code should
                                        \ nver be generated.  This indicates
                                        \ a sw/hw mismatch, or bugs.
h#    89  constant resetk               \ Keyboard was just reset.
h#    90  constant error                \ Keybd just detected an internal err.
h#    91  constant idle                 \ Keybd is idle (no key downs)
h#    92  constant mon-off/on
     oops constant capslock             \ Caps Lock key


