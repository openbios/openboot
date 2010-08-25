\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-swiss-german.fth
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
\ id: @(#)usb-swiss-german.fth 1.2 99/07/23
\ purpose: 
\ copyright: Copyright 1999 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
28 keyboard: swiss-german

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   section      degrees                 53      nsk		\ lft of 1
                ascii +      ascii |    30      sak		\ 1
                ascii "      ascii @    31      sak		\ 2
                ascii *      ascii #    32      sak		\ 3
                dilla-c      ascii ^    33      sak		\ 4
                             ascii ~    34      ak		\ 5
                ascii &                 35      sk		\ 6
                ascii /                 36      sk		\ 7
                ascii (                 37      sk		\ 8
                ascii )                 38      sk		\ 9
                ascii =      ascii `    39      sak		\ 0
   ascii '      ascii ?      oops       45      allk		\ rt of 0
   oops         oops                    46      nsk		\ lft of bckspc
   ascii z      ascii Z                 28      nsk		\ was y is z
   diaer-u      grave-e      ascii [    47      allk  		\ rt of p
   oops         ascii !      ascii ]    48      allk  		\ lft of upRtn
   diaer-o      acute-e                 51      nsk		\ rt of L
   diaer-a      acute-a      ascii {    52      allk
   ascii $      p-strlg      ascii }    50      allk  		\ lft of lowRtn
   ascii <      ascii >      ascii \    100     allk		\ left of y
   ascii y      ascii Y                 29      nsk		\ was z is y
                ascii ;                 54      sk 		\ rt of m
                ascii :                 55      sk 
   ascii -      ascii _                 56      nsk		\ lft of rtshft
                                                        
kend
