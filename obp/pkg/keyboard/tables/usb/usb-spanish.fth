\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-spanish.fth
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
\ id: @(#)usb-spanish.fth 1.5 99/07/23
\ purpose: 
\ copyright: Copyright 1997-1999 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
25 keyboard: spain

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   mascsup      femsup       ascii \    53      allk		\ lft of 1
                             ascii |    30      ak		\ 1
                ascii "      ascii @    31      sak		\ 2
                cen-dot      ascii #    32      sak		\ 3
                             ascii ^    33      ak		\ 4
                             ascii ~    34      ak		\ 5
                ascii &      notsign    35      sak		\ 6
                ascii /                 36      sk		\ 7
                ascii (                 37      sk		\ 8
                ascii )                 38      sk		\ 9
                ascii =                 39      sk		\ 0
   ascii '      ascii ?      ascii `    45      allk		\ rt of 0
   invert!      invert?                 46      nsk		\ lft of bckspc
   oops         oops         ascii [    47      allk  		\ rt of p
   ascii +      ascii *      ascii ]    48      allk  		\ lft of upRtn
   tilde-n      n-tilde                 51      nsk		\ rt of L
   oops         oops         ascii {    52      allk  
   dilla-c      c-dilla      ascii }    50      allk  		\ lft of lowRtn
   ascii <      ascii >                 100     nsk		\ left of z
                ascii ;                 54      sk 		\ rt of m
                ascii :                 55      sk		 
   ascii -      ascii _                 56      nsk		\ lft of rtshft
                                                        
kend

