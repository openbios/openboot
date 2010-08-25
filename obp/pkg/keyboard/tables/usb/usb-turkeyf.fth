\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: usb-turkeyf.fth
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
\ id: @(#)usb-turkeyf.fth 1.1 01/10/17
\ purpose: 
\ copyright: Copyright 2001 Sun Microsystems, Inc.  All Rights Reserved
\

decimal

\ Keyboard country code assigned by HID doc.
35 keyboard: turkeyf

\  normal  	shifted      altg      key#
\  -------      -------      -------   -----    ------------
   ascii +      ascii *      plusmin    53      allk		\ lft of 1
                             raised1    30      ak		\ 1
                ascii "      raised2    31      sak		\ 2
                ascii ^      ascii #    32      sak		\ 3
                             one4th     33      ak		\ 4
                             onehalf    34      ak		\ 5
                ascii &      thre4th    35      sak		\ 6
                ascii '      ascii {    36      sak		\ 7
                ascii (      ascii [    37      sak		\ 8
                ascii )      ascii ]    38      sak		\ 9
                ascii =      ascii }    39      sak		\ 0
   ascii /      ascii ?      ascii \    45      allk		\ rt of 0
   ascii -      ascii _      ascii |    46      allk		\ lft of bckspc
   ascii f      ascii F      ascii @    20      allk		\ q
   ascii g      ascii G                 26      nsk		\ w
   oops         oops         oops       8       allk		\ e
   oops         ascii I      paramrk    21      allk		\ r
   ascii o      ascii O                 23      nsk		\ t
   ascii d      ascii D      yen        28      allk		\ y
   ascii r      ascii R                 24      nsk		\ u
   ascii n      ascii N                 12      nsk		\ i
   ascii h      ascii H      degrees    18      allk		\ o
   ascii p      ascii P      p-strlg    19      allk		\ p
   ascii q      ascii Q      diaeres    47      allk  		\ rt of p
   ascii w      ascii W      ascii ~    48      allk  		\ lft of upRtn
   ascii x      ascii X      ascii `    49      allk		\ \
   ascii u      ascii U      dipth-a    4       allk		\ a
   ascii i      oops                    22      nsk		\ s
   ascii e      ascii E                 7       nsk		\ d
   ascii a      ascii A                 9       nsk		\ f
   diaer-u      u-diaer                 10      nsk		\ g
   ascii t      ascii T                 11      nsk		\ h
   ascii k      ascii K                 13      nsk		\ j
   ascii m      ascii M                 14      nsk		\ k
   ascii y      ascii Y      ascii '    51      allk		\ rt of L
   oops         oops         ascii #    52      allk		\ '
   ascii #      ascii '      ascii `    50      allk  		\ lft of lowRtn
   ascii j      ascii J      ascii <    29      allk		\ z
   diaer-o      o-diaer      ascii >    27      allk		\ x
   ascii v      ascii V      cents      6       allk		\ c
   ascii c      ascii C                 25      nsk		\ v
   dilla-c      c-dilla      dilla-c    5       allk		\ b
   ascii z      ascii Z                 17      nsk		\ n
   ascii s      ascii S      mu         16      allk		\ m
   ascii b      ascii B      multsym    54      allk 		\ rt of m
   ascii .      ascii :      divsym     55      allk		\ .
   ascii ,      ascii ;                 56      nsk		\ lft of rtshft
                                                        
kend

