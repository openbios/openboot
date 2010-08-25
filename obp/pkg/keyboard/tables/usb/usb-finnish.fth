\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-finnish.fth
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
\ id: @(#)usb-finnish.fth 1.2 99/07/23
\ purpose: 
\ copyright: Copyright 1999 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
7 keyboard: finnish

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   section      onehalf                 53      nsk		\ lft of 1
                ascii "      ascii @    31      sak		\ 2
                ascii #      p-strlg    32      sak		\ 3
                currncy      ascii $    33      sak		\ 4
                ascii &                 35      sk		\ 6
                ascii /      ascii {    36      sak		\ 7
                ascii (      ascii [    37      sak		\ 8
                ascii )      ascii ]    38      sak		\ 9
                ascii =      ascii }    39      sak		\ 0
   ascii +      ascii ?      ascii \    45      allk		\ rt of 0
   oops         oops                    46      nsk		\ lft of bckspc
   angst-a      a-angst                 47      nsk  		\ rt of p
   oops         ascii ^      ascii ~    48      allk  		\ lft of upRtn
   diaer-o      o-diaer                 51      nsk		\ rt of L
   diaer-a      a-diaer                 52      nsk  
   ascii '      ascii *      ascii `    50      allk  		\ lft of lowRtn
   ascii <      ascii >      ascii |    100     allk		\ left of z
                ascii ;                 54      sk 		\ rt of m
                ascii :                 55      sk 
   ascii -      ascii _                 56      nsk		\ lft of rtshft
                                                        
kend

