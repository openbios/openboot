\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fb-fcodes.fth
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
id: @(#)fb-fcodes.fth 1.1 00/04/20
purpose: 
copyright: Copyright 1999-2000 Sun Microsystems, Inc.  All Rights Reserved

hex
\ Define the various FB support FCODEs.
\ TERMINAL/FRAMEBUFFER Installation
v1 v2  01c 1 byte-code: is-install            ( acf -- )
v1 v2  01d 1 byte-code: is-remove             ( acf -- )
v1 v2  01e 1 byte-code: is-selftest           ( acf -- )

\ TERMINAL/FRAMEBUFFER OPERATIONS (DISPLAY DEVICE FCODES)
\ --- Terminal emulator values -------------------------------------------
v1 v2  050 1 byte-code: #lines                ( -- n )
v1 v2  051 1 byte-code: #columns              ( -- n )
v1 v2  052 1 byte-code: line#                 ( -- n )
v1 v2  053 1 byte-code: column#               ( -- n )
v1 v2  054 1 byte-code: inverse?              ( -- flag )
v1 v2  055 1 byte-code: inverse-screen?       ( -- flag )
\ v1     056 1 byte-code: frame-buffer-busy?    ( -- flag ) \ Obsolete

\ --- Terminal emulation low-level operations ----------------------------
v1 v2  057 1 byte-code: draw-character        ( char -- )
v1 v2  058 1 byte-code: reset-screen          ( -- )
v1 v2  059 1 byte-code: toggle-cursor         ( -- )
v1 v2  05a 1 byte-code: erase-screen          ( -- )
v1 v2  05b 1 byte-code: blink-screen          ( -- )
v1 v2  05c 1 byte-code: invert-screen         ( -- )
v1 v2  05d 1 byte-code: insert-characters     ( n -- )
v1 v2  05e 1 byte-code: delete-characters     ( n -- )
v1 v2  05f 1 byte-code: insert-lines          ( n -- )
v1 v2  060 1 byte-code: delete-lines          ( n -- )
v1 v2  061 1 byte-code: draw-logo             ( line# laddr lwidth lheight -- )

\ --- Frame Buffer Text routines -----------------------------------------
v1 v2  062 1 byte-code: frame-buffer-adr      ( -- addr )
v1 v2  063 1 byte-code: screen-height         ( -- n )
v1 v2  064 1 byte-code: screen-width          ( -- n )
v1 v2  065 1 byte-code: window-top            ( -- n )
v1 v2  066 1 byte-code: window-left           ( -- n )

\ --- Font ---------------------------------------------------------------
v1 v2  06a 1 byte-code: default-font          ( -- fntbase chrwidth chrheight fntbytes #1stchr #chrs    )
v1 v2  06b 1 byte-code: set-font              ( fntbase chrwidth chrheight fntbytes #1stchr #chrs -- )
v1 v2  06c 1 byte-code: char-height           ( -- n )
v1 v2  06d 1 byte-code: char-width            ( -- n )
v1 v2  06e 1 byte-code: >font                 ( char -- adr )
v1 v2  06f 1 byte-code: fontbytes             ( -- n )  \ Bytes/scan line, usu. 2

\ --- 8-bit frame buffer routines ----------------------------------------
v1 v2  080 1 byte-code: fb8-draw-character    ( char -- )
v1 v2  081 1 byte-code: fb8-reset-screen      ( -- )
v1 v2  082 1 byte-code: fb8-toggle-cursor     ( -- )
v1 v2  083 1 byte-code: fb8-erase-screen      ( -- )
v1 v2  084 1 byte-code: fb8-blink-screen      ( -- )
v1 v2  085 1 byte-code: fb8-invert-screen     ( -- )
v1 v2  086 1 byte-code: fb8-insert-characters ( #chars -- )
v1 v2  087 1 byte-code: fb8-delete-characters ( #chars -- )
v1 v2  088 1 byte-code: fb8-insert-lines      ( #lines -- )
v1 v2  089 1 byte-code: fb8-delete-lines      ( #lines -- )
v1 v2  08a 1 byte-code: fb8-draw-logo         ( line# ladr lwidth lheight -- )
v1 v2  08b 1 byte-code: fb8-install           ( width height #cols #lines -- )
