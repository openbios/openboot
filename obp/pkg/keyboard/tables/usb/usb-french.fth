\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-french.fth
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
\ id: @(#)usb-french.fth 1.2 99/07/23
\ purpose: 
\ copyright: Copyright 1999 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
8 keyboard: france

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   raised2      oops                    53      nsk		\ lft of 1
   ascii &      ascii 1                 30      nsk		\ 1
   acute-e      ascii 2      ascii ~    31      allk		\ 2
   ascii "      ascii 3      ascii #    32      allk		\ 3
   ascii '      ascii 4      ascii {    33      allk		\ 4
   ascii (      ascii 5      ascii [    34      allk		\ 5
   ascii -      ascii 6      ascii |    35      allk		\ 6
   grave-e      ascii 7      ascii `    36      allk		\ 7
   ascii _      ascii 8      ascii \    37      allk		\ 8
   dilla-c      ascii 9      ascii ^    38      allk		\ 9
   grave-a      ascii 0      ascii @    39      allk		\ 0
   ascii )      degrees      ascii ]    45      allk		\ rt of 0
   ascii =      ascii +      ascii }    46      allk		\ lft of bckspc
   ascii a      ascii A                 20      nsk		\ was q is a
   ascii z      ascii Z                 26      nsk		\ was w is z
   oops         oops                    47      nsk  		\ rt of p
   ascii $      p-strlg      currncy    48      allk  		\ lft of upRtn
   ascii q      ascii Q                 4       nsk		\ was a is q
   ascii m      ascii M                 51      nsk		\ rt of L
   grave-u      ascii %                 52      nsk  
   ascii *      mu                      50      nsk  		\ lft of lowRtn
   ascii <      ascii >                 100     nsk		\ left of w
   ascii w      ascii W                 29      nsk		\ was z is w
   ascii ,      ascii ?                 16      nsk		\ was m
   ascii ;      ascii .                 54      nsk 		\ rt of m
   ascii :      ascii /                 55      nsk 
   ascii !      section                 56      nsk		\ lft of rtshft
                                                        
kend

