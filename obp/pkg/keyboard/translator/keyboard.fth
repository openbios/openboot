\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: keyboard.fth
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
id: @(#)keyboard.fth 2.52 02/08/22
purpose: Package methods for keyboard translator
copyright: Copyright 1990-1994,2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless

instance variable kbd-dropin&id-acf

: set-acf ( var str,len -- ok? )
  my-parent ihandle>phandle find-method if
    swap ! true
  else
    drop false
  then
;

: call-my-parent ( xxx? routine -- xxx? ) @ my-parent call-package ;

: kbd-dropin&id ( -- magic$ dropin$ layoutid )
   kbd-dropin&id-acf call-my-parent
;

: install-indirect ( -- ok? )
   kbd-dropin&id-acf   " kbd-dropin&id" set-acf        ( flag' )
;

external

: open ( -- okay? )
   install-dropin-support 0=	( ok? )
   install-indirect 0= or if  false exit  then

   kbd-dropin&id install-kbd  if  
      cr type cr drop false
   else  true  then
;

: convert ( key# altg? shift? -- entry )
    key-table                            ( key# altg? shift? addr )
    swap                                 ( key# altg? addr shift? )
    if                                   ( key# altg? addr )
       >k-shiftmap nip                   ( key# map )
    else                                 ( key# altg? addr )
       swap if  >k-altgmap else  >k-normalmap then  ( key# map )
    then                                 ( key# map )
    + c@                                 ( entry )
;

: close ( -- )
   uninstall-dropin-support
;

headerless
