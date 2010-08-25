\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-belgium.fth
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
\ id: @(#)usb-belgium.fth 1.1 01/10/12
\ purpose: 
\ copyright: Copyright 2001 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
02 keyboard: belgium

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   raised2      raised3                 53      nsk		\ lft of 1
   ascii &      ascii 1      ascii |    30      allk		\ 1
   acute-e      ascii 2      ascii @    31      allk		\ 2
   ascii "      ascii 3      ascii #    32      allk		\ 3
   ascii '      ascii 4                 33      nsk		\ 4
   ascii (      ascii 5                 34      nsk		\ 5
   section      ascii 6      ascii ^    35      allk		\ 6
   grave-e      ascii 7                 36      nsk		\ 7
   ascii !      ascii 8                 37      nsk		\ 8
   dilla-c      ascii 9      ascii {    38      allk		\ 9
   grave-a      ascii 0      ascii }    39      allk		\ 0
   ascii )      degrees                 45      nsk		\ rt of 0
   ascii -      ascii _                 46      nsk		\ lft of bckspc
   ascii a      ascii A                 20      nsk		\ q
   ascii z      ascii Z                 26      nsk		\ w
                             currncy    8       ak		\ e
   ascii ^      ascii "      ascii [    47      allk  		\ rt of p
   ascii $      ascii *      ascii ]    48      allk  		\ lft of upRtn
   hole         hole         hole       49      allk		\ \
   ascii q      ascii Q                 4       nsk		\ a
   ascii m      ascii M                 51      nsk		\ rt of L
   grave-u      ascii %      ascii '    52      allk		\ '
   mu           p-strlg      ascii `    50      allk  		\ lft of lowRtn
   ascii <      ascii >      ascii \    100     allk		\ left of z
   ascii w      ascii W                 29      nsk		\ z
   ascii ,      ascii ?                 16      nsk		\ m
   ascii ;      ascii .                 54      nsk 		\ rt of m
   ascii :      ascii /                 55      nsk		\ .
   ascii =      ascii +      ascii ~    56      allk		\ lft of rtshft
                                                        
kend
