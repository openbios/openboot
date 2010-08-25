\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: tte.fth
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
id: @(#)tte.fth 1.1 06/02/16
purpose:
copyright: Copyright 2006 Sun Microsystems, Inc. All Rights Reserved
copyright: Use is subject to license terms.

headerless
1 #pabits lshift 1-   constant pa-mask
h#  3                 constant tteshift
h#  8                 constant /tte

: >tte-writable ( tte -- tte' )  1 d#  6 lshift or  ;
: >tte-readonly ( tte -- tte' )  1 d#  6 lshift invert and  ;
: >tte-priv     ( tte -- tte' )  1 d#  8 lshift or  ;
: >tte-cv       ( tte -- tte' )  1 d#  9 lshift or  ;
: >tte-cp       ( tte -- tte' )  1 d# 10 lshift or  ;
: >tte-effect   ( tte -- tte' )  1 d# 11 lshift or  ;
: >tte-invert   ( tte -- tte' )  1 d# 12 lshift or   ;
: >tte-locked   ( tte -- tte' )  1 d# 61 lshift or  ;
: >tte-valid    ( tte -- tte' )  1 d# 63 lshift or  ;
: >tte-global   ( tte -- tte' )  0 or ;
: >tte-8k       ( tte -- tte' )  7 invert and  0 or  ;
: >tte-64k      ( tte -- tte' )  7 invert and  1 or  ;
: >tte-4m       ( tte -- tte' )  7 invert and  3 or  ;
: >tte-256m     ( tte -- tte' )  7 invert and  5 or  ;

: >tte-soft     ( tte -- tte' )  h# 30 invert and  h# 10 or  ;
0
>tte-writable
>tte-cv
>tte-effect
>tte-global
>tte-invert
constant tte-mode-mask

: mode>tte  ( mode tte  -- tte' )

   \ MODE == -1 is the default
   over true  =  if  nip exit  then          ( mode tte )

   tte-mode-mask invert and                  ( mode tte" )
   over h# 001 and  if  >tte-writable  then  ( mode tte" )
   over h# 020 and  if  >tte-cv        then  ( mode tte" )
   over h# 040 and  if  >tte-effect    then  ( mode tte" )
   over h# 080 and  if  >tte-global    then  ( mode tte" )
   over h# 100 and  if  >tte-invert    then  ( mode tte" )
   nip
;
: tte>mode  ( tte -- mode )
   0                                              ( tte mode" )
   over 0 >tte-writable and  if  h# 001 or  then  ( tte mode' )
   2 or \ Always readable                         ( tte mode' )
   4 or \ Always executable                       ( tte mode' )
   over 0 >tte-cv       and  if  h# 020 or  then  ( tte mode' )
   over 0 >tte-effect   and  if  h# 040 or  then  ( tte mode' )
   over 0 >tte-global   and  if  h# 080 or  then  ( tte mode' )
   over 0 >tte-invert   and  if  h# 100 or  then  ( tte mode )
   nip
;

: valid-tte? ( tte -- flag )  0<  ;

: tte>size ( tte -- size )  1 swap 7 and 3 * d# 13 + lshift  ;

\ Set this as the memory high water mark.
variable physmax physmax off

headers
: memory? ( pa.lo pa.hi -- flag ) drop physmax @ < ;

: tte> ( tte -- pa.lo pa.hi )
   pa-mask and page#mask and  0 ( pa.lo pa.hi )
;
: >tte ( pa.lo pa.hi -- tte )
   2dup memory?  if                    ( pa.lo pa.hi )
      drop 0 >tte-cp >tte-cv           ( pa tte )
   else                                ( pa.lo pa.hi )
      drop 0 >tte-effect               ( pa tte )
   then                                ( pa tte )
   swap  pa-mask and page#mask and or  ( tte )
   >tte-valid >tte-writable >tte-priv  ( tte )
;
headerless
